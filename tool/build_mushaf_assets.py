"""Builds the Mushaf runtime assets from the untouched sources.

    python tool/build_mushaf_assets.py [out_dir]

Reads tool/quran_source/ (see SOURCE.md) and writes, under out_dir
(default: the project root):

  assets/quran/meta.json         suras, ayat, juz and quarter starts, basmala
  assets/quran/pages/NNN.json    page -> lines -> segments of tokens
  assets/fonts/uthmanic_hafs_v20.ttf, assets/fonts/surah-name-v4.ttf
                                 copied byte for byte

This script only reshapes the source; it never changes a character.

- Each ayah's text (KFGQPC hafsData aya_text) is cut at its own separators,
  U+0020 and U+00A0, and every separator is kept. So concatenating an ayah's
  tokens with their separators gives back aya_text exactly.
  tool/verify_mushaf_assets.py checks this for all 6236 ayat.
- Tokens are placed on the 15 lines using the QUL V2 layout, which gives each
  line as a range of QUL word ids.

Output is deterministic: the same sources always give the same bytes.
"""
import json
import os
import shutil
import sqlite3
import sys
import xml.etree.ElementTree as ET

SRC = 'tool/quran_source'
PAGES = 604

AYAH_MARK = range(0xFC00, 0xFD1E)  # one codepoint per ayah number in this text
RUB = '\u06de'  # ۞
SAJDAH = '\u06e9'  # ۩
SEPARATORS = ' \u00a0'

# Where the KFGQPC text and QUL's word list cut words differently. Each entry
# maps the ayah to (KFGQPC word indexes, QUL word indexes) that cover the same
# letters, 1-based and counting words only, not the ayah mark. These were
# checked by eye against both sources. The build stops if the set of
# mismatching ayat ever differs from this table, or if a group straddles a
# line break.
WORD_GROUPS = {
    (15, 7): ([1], [1, 2]),      # لَّوۡمَا   | لَّوْ مَا
    (27, 20): ([4], [4, 5]),     # مَالِيَ    | مَا لِىَ
    (36, 22): ([1], [1, 2]),     # وَمَالِيَ  | وَمَا لِىَ
    (37, 130): ([3, 4], [3]),    # إِلۡ يَاسِينَ | إِلْ يَاسِينَ (one word in QUL)
}

# Sajdah types, as Tanzil's quran-data.xml gives them.
SAJDAH_TYPE = {'recommended': 1, 'obligatory': 2}


def fail(msg):
    sys.exit(f'build_mushaf_assets: {msg}')


def tokens(text):
    """Cuts [text] at U+0020 / U+00A0 into (token, separator-after) pairs."""
    out, cur = [], ''
    for ch in text:
        if ch in SEPARATORS:
            out.append((cur, ch))
            cur = ''
        else:
            cur += ch
    out.append((cur, ''))
    return out


def kind(tok):
    if len(tok) == 1 and ord(tok) in AYAH_MARK:
        return 'end'
    if tok == RUB:
        return 'rub'
    if tok == '':
        return 'empty'
    return 'word'


def main(out_root):
    # --- sources -----------------------------------------------------------
    hafs = json.load(open(f'{SRC}/kfgqpc/hafsData_v2-0.json', encoding='utf-8-sig'))
    ayat = [(r['sura_no'], r['aya_no']) for r in hafs]
    text = {(r['sura_no'], r['aya_no']): r['aya_text'] for r in hafs}
    if len(ayat) != 6236 or len(set(ayat)) != 6236:
        fail('expected 6236 distinct ayat in hafsData')

    words = sqlite3.connect(f'{SRC}/qul/qpc-quran-script.db')
    qul = {}  # (sura, ayah) -> [word ids in order]; the last is the ayah mark
    for wid, s, a, w in words.execute(
            'select id, surah, ayah, word from words order by id'):
        qul.setdefault((s, a), []).append(wid)

    layout = sqlite3.connect(f'{SRC}/qul/qpc-v2-15-lines.db')
    rows = list(layout.execute(
        'select page_number, line_number, line_type, is_centered, '
        'first_word_id, last_word_id, surah_number '
        'from pages order by page_number, line_number'))

    tanzil = ET.parse(f'{SRC}/tanzil/quran-data.xml').getroot()
    t_suras = tanzil.find('suras')
    t_juz = [(int(e.get('sura')), int(e.get('aya'))) for e in tanzil.find('juzs')]
    t_quarters = [(int(e.get('sura')), int(e.get('aya'))) for e in tanzil.find('hizbs')]
    t_sajdas = {(int(e.get('sura')), int(e.get('aya'))): e.get('type')
                for e in tanzil.find('sajdas')}

    # --- tokens -> QUL word ids --------------------------------------------
    word_of_token = {}  # (sura, ayah, token index) -> QUL word id
    mismatched = set()
    for key in ayat:
        toks = tokens(text[key])
        ids = qul[key]
        q_words, q_end = ids[:-1], ids[-1]
        k_words = [i for i, (t, _) in enumerate(toks) if kind(t) == 'word']
        ends = [i for i, (t, _) in enumerate(toks) if kind(t) == 'end']
        if ends != [len(toks) - 1]:
            fail(f'{key}: the ayah mark is not the last token')

        # Word index (1-based, words only) -> QUL word id.
        if len(k_words) == len(q_words):
            k_to_q = {n: q_words[n - 1] for n in range(1, len(k_words) + 1)}
        else:
            mismatched.add(key)
            if key not in WORD_GROUPS:
                fail(f'{key}: {len(k_words)} KFGQPC words vs {len(q_words)} QUL words, '
                     'and no entry in WORD_GROUPS')
            k_group, q_group = WORD_GROUPS[key]
            k_to_q, k, q = {}, 1, 1
            while k <= len(k_words):
                if k == k_group[0]:
                    for kk in k_group:
                        k_to_q[kk] = q_words[q_group[0] - 1]
                    k += len(k_group)
                    q += len(q_group)
                else:
                    k_to_q[k] = q_words[q - 1]
                    k += 1
                    q += 1
            if q - 1 != len(q_words):
                fail(f'{key}: WORD_GROUPS does not account for every QUL word')

        # Every token takes a QUL id: words their own, the ayah mark the
        # mark's, and a rub sign or empty token the id of the word after it.
        n = 0
        pending = []
        for i, (t, _) in enumerate(toks):
            k = kind(t)
            if k == 'word':
                n += 1
                wid = k_to_q[n]
                for p in pending:
                    word_of_token[key + (p,)] = wid
                pending = []
                word_of_token[key + (i,)] = wid
            elif k == 'end':
                word_of_token[key + (i,)] = q_end
            else:
                pending.append(i)
        if pending:
            fail(f'{key}: rub sign or empty token with no word after it')

    if mismatched != set(WORD_GROUPS):
        fail(f'WORD_GROUPS is stale: mismatching ayat are {sorted(mismatched)}')

    # Groups must not straddle a line break.
    line_of_word = {}
    for p, ln, typ, cen, fw, lw, sura in rows:
        if typ == 'ayah':
            for wid in range(fw, lw + 1):
                line_of_word[wid] = (p, ln)
    for key, (_, q_group) in WORD_GROUPS.items():
        ids = [qul[key][i - 1] for i in q_group]
        if len({line_of_word[i] for i in ids}) != 1:
            fail(f'{key}: a word group straddles a line break')

    # --- pages -------------------------------------------------------------
    tokens_by_word = {}
    for (s, a, i), wid in word_of_token.items():
        tokens_by_word.setdefault(wid, []).append((s, a, i))

    page_lines = {}
    first_page = {}
    for p, ln, typ, cen, fw, lw, sura in rows:
        if typ == 'surah_name':
            line = {'t': 's', 'sura': sura}
        elif typ == 'basmallah':
            line = {'t': 'b'}
        elif typ == 'ayah':
            segs = []
            for wid in range(fw, lw + 1):
                for s, a, i in sorted(tokens_by_word.get(wid, [])):
                    first_page.setdefault((s, a), p)
                    tok, sep = tokens(text[(s, a)])[i]
                    if segs and segs[-1][0] == s and segs[-1][1] == a:
                        segs[-1][3].append(tok)
                        segs[-1][4] += sep
                    else:
                        segs.append([s, a, i, [tok], sep])
            line = {'t': 'a', 'segs': segs}
            if cen:
                line['c'] = 1
        else:
            fail(f'page {p} line {ln}: unknown line type {typ!r}')
        page_lines.setdefault(p, []).append(line)

    if sorted(page_lines) != list(range(1, PAGES + 1)):
        fail('layout does not cover pages 1..604')
    if len(first_page) != 6236:
        fail(f'{6236 - len(first_page)} ayat were not placed on any line')

    # --- metadata ----------------------------------------------------------
    # Quarter starts: the ۞ the text itself prints, plus the quarters that
    # begin a sura, where the Mushaf prints the sura header instead of ۞.
    rub_marked = {k for k in ayat if RUB in text[k]}
    quarters = sorted(rub_marked | {q for q in t_quarters if q[1] == 1}
                      | set(t_juz))
    if len(quarters) != 240:
        fail(f'{len(quarters)} quarter starts, expected 240')
    juz_starts = sorted(t_juz)
    if len(juz_starts) != 30 or not set(juz_starts) <= set(quarters):
        fail('juz starts must be 30 quarter starts')

    sajdah = {k for k in ayat if SAJDAH in text[k]}
    if sajdah != set(t_sajdas):
        fail(f'sajdah signs in the text {sorted(sajdah)} differ from Tanzil {sorted(t_sajdas)}')

    order = {k: i for i, k in enumerate(ayat)}
    q_index = [order[q] for q in quarters]
    j_index = [order[j] for j in juz_starts]
    ayah_rows = {}
    qi = ji = 0
    for idx, key in enumerate(ayat):
        while qi + 1 < len(q_index) and q_index[qi + 1] <= idx:
            qi += 1
        while ji + 1 < len(j_index) and j_index[ji + 1] <= idx:
            ji += 1
        # [page, juz, quarter 1..240, sajdah 0 none / 1 recommended / 2 obligatory]
        ayah_rows.setdefault(key[0], []).append([
            first_page[key], ji + 1, qi + 1,
            SAJDAH_TYPE[t_sajdas[key]] if key in t_sajdas else 0])

    suras = []
    for e in t_suras:
        n = int(e.get('index'))
        count = int(e.get('ayas'))
        if len(ayah_rows[n]) != count:
            fail(f'sura {n}: Tanzil says {count} ayat, KFGQPC has {len(ayah_rows[n])}')
        suras.append({
            'n': n,
            'ayahs': count,
            'type': 'makki' if e.get('type') == 'Meccan' else 'madani',
            'page': first_page[(n, 1)],
        })

    basmala = tokens(text[(1, 1)])[:-1]  # 1:1 without its ayah mark
    basmala[-1] = (basmala[-1][0], '')    # nor the NBSP before the mark

    meta = {
        'source': 'KFGQPC Uthmanic Hafs v2.0 (Update 13.0); layout: QUL KFGQPC V2 (1421H) 15 lines',
        'pages': PAGES,
        'basmala': [t for t, _ in basmala],
        'basmala_seps': ''.join(s for _, s in basmala),
        'suras': suras,
        'ayahs': [ayah_rows[n] for n in range(1, 115)],
        'juz': [[s, a] for s, a in juz_starts],
        'quarters': [[s, a] for s, a in quarters],
    }

    # --- write -------------------------------------------------------------
    def dump(path, obj):
        path = os.path.join(out_root, path)
        os.makedirs(os.path.dirname(path), exist_ok=True)
        with open(path, 'w', encoding='utf-8', newline='\n') as f:
            json.dump(obj, f, ensure_ascii=False, separators=(',', ':'))
            f.write('\n')

    dump('assets/quran/meta.json', meta)
    for p in range(1, PAGES + 1):
        dump(f'assets/quran/pages/{p:03d}.json', {'p': p, 'lines': page_lines[p]})

    fonts = os.path.join(out_root, 'assets/fonts')
    os.makedirs(fonts, exist_ok=True)
    shutil.copyfile(f'{SRC}/kfgqpc/uthmanic_hafs_v20.ttf', f'{fonts}/uthmanic_hafs_v20.ttf')
    shutil.copyfile(f'{SRC}/qul/surah-name-v4.ttf', f'{fonts}/surah-name-v4.ttf')

    print(f'wrote {PAGES} pages, {len(ayat)} ayat, {len(suras)} suras')


if __name__ == '__main__':
    main(sys.argv[1] if len(sys.argv) > 1 else '.')
