"""Verifies the Mushaf assets against their sources.

    python tool/verify_mushaf_assets.py

Exits non-zero if any check fails. Prints every mismatch; never fixes one.

What it proves:
  - the sources are the files SOURCE.md records (sha256);
  - the fonts are shipped byte for byte;
  - counts: 114 suras, 6236 ayat, 604 pages, 15 lines a page (8 on pages
    1-2), 114 sura headers, 112 basmala lines, 30 juz, 240 quarters;
  - round trip: every ayah rebuilt from the page assets equals the KFGQPC
    source text exactly;
  - independent cross-check: every ayah's letter skeleton equals Tanzil's
    Uthmani text; every ayah's page equals the KFGQPC page field (so the page
    of each sura's first ayah too);
  - anchors: Al-Baqarah on page 2, 18:1 on page 293, An-Nas on page 604, and
    the 15 sajdah ayat flagged;
  - the build is deterministic: rebuilding gives identical bytes.
"""
import filecmp
import hashlib
import json
import os
import subprocess
import sys
import tempfile
import unicodedata
import xml.etree.ElementTree as ET

SRC = 'tool/quran_source'
ASSETS = 'assets/quran'

SOURCE_SHA256 = {
    'kfgqpc/hafsData_v2-0.json': 'd2960b3217962e7e4252abdcece67bea3d6b48271e4cd3af45bbbb2dd5c872ca',
    'kfgqpc/uthmanic_hafs_v20.ttf': 'd560bbbc7a90a4f4d416d206a5ac48bd8a1ad00273d64d232f16ca54941bd041',
    'qul/qpc-v2-15-lines.db': '26f1afbe0417bb9a724780a5f6ffb2a19d58a442836fc74b29f88c364667d6cf',
    'qul/qpc-quran-script.db': '4bf9549dfcfd367d4d4b151bd58b51af63b677d1c980cf5e52541c2f981d7e6d',
    'qul/surah-name-v4.ttf': '026cfe8ac461531a7b1c8e4edd05ce3343f09e9c73447ff14c6bc93f3193d661',
    'tanzil/quran-uthmani.txt': '6933e133dd56db778c801bf738848454e43648105a151e8d84d86a7cae39ec5f',
    'tanzil/quran-data.xml': '8867c1d88191472adec9db694b3cd9f135b1a2ef580574d32cf888dcb22c5c7a',
}

SAJDAH_AYAT = {(7, 206), (13, 15), (16, 50), (17, 109), (19, 58), (22, 18),
               (22, 77), (25, 60), (27, 26), (32, 15), (38, 24), (41, 38),
               (53, 62), (84, 21), (96, 19)}

# Skeleton mismatches with Tanzil that a person has looked at. Each is printed
# on every run; any other mismatch fails.
REVIEWED_SKELETON = {
    (2, 72): 'فَٱدَّٰرَٰءۡتُمۡ: KFGQPC writes the hamza as the letter U+0621 with '
             'U+06E1; Tanzil as the combining hamza above U+0654 with U+0652. '
             'KFGQPC read.me: "Modifying Word (فادارأتم) sura Al-Baqarah(2) '
             'aya(72) to display properly on different platforms".',
}

failures = []


def check(ok, msg):
    if not ok:
        failures.append(msg)
        print('FAIL', msg)
    return ok


def sha256(path):
    return hashlib.sha256(open(path, 'rb').read()).hexdigest()


# Tanzil and KFGQPC encode some letters differently, not differently spelt:
# hamza on a seat as one codepoint or as letter + combining hamza (Unicode
# canonical decomposition covers that), alef wasla / alef forms, and final ya
# with or without dots. The skeleton keeps the base letters only.
FOLD = {'\u0671': '\u0627', '\u0672': '\u0627', '\u0673': '\u0627',
        '\u0649': '\u064a', '\u06cc': '\u064a'}


def skeleton(text):
    out = []
    for ch in unicodedata.normalize('NFD', text):
        o = ord(ch)
        if unicodedata.category(ch) in ('Mn', 'Me', 'Lm', 'Zs', 'Cf'):
            continue  # marks, small letters, spaces
        if ch in '\u0640\u06de\u06e9\u00a0':
            continue  # tatweel, rub, sajdah, NBSP
        if 0xFC00 <= o <= 0xFD1D or 0x06D6 <= o <= 0x06ED:
            continue  # ayah numbers, Quranic annotation signs
        out.append(FOLD.get(ch, ch))
    return ''.join(out)


def main():
    # --- sources and fonts -------------------------------------------------
    for rel, want in SOURCE_SHA256.items():
        check(sha256(f'{SRC}/{rel}') == want, f'source {rel} is not the recorded file')
    check(filecmp.cmp(f'{SRC}/kfgqpc/uthmanic_hafs_v20.ttf',
                      'assets/fonts/uthmanic_hafs_v20.ttf', shallow=False),
          'the shipped Hafs font differs from the source')
    check(filecmp.cmp(f'{SRC}/qul/surah-name-v4.ttf',
                      'assets/fonts/surah-name-v4.ttf', shallow=False),
          'the shipped sura-name font differs from the source')

    hafs = json.load(open(f'{SRC}/kfgqpc/hafsData_v2-0.json', encoding='utf-8-sig'))
    source = {(r['sura_no'], r['aya_no']): r['aya_text'] for r in hafs}
    kfgqpc_page = {(r['sura_no'], r['aya_no']): r['page'] for r in hafs}
    kfgqpc_juz = {(r['sura_no'], r['aya_no']): r['jozz'] for r in hafs}

    meta = json.load(open(f'{ASSETS}/meta.json', encoding='utf-8'))

    # --- counts ------------------------------------------------------------
    check(len(meta['suras']) == 114, f"{len(meta['suras'])} suras")
    n_ayat = sum(len(a) for a in meta['ayahs'])
    check(n_ayat == 6236, f'{n_ayat} ayat')
    check([s['ayahs'] for s in meta['suras']] == [len(a) for a in meta['ayahs']],
          'sura ayah counts disagree with the ayah table')
    check(meta['pages'] == 604, f"meta says {meta['pages']} pages")
    page_files = sorted(os.listdir(f'{ASSETS}/pages'))
    check(page_files == [f'{p:03d}.json' for p in range(1, 605)],
          f'{len(page_files)} page files')
    check(len(meta['juz']) == 30, f"{len(meta['juz'])} juz")
    check(len(meta['quarters']) == 240, f"{len(meta['quarters'])} quarters")

    # --- pages: lines, and the round trip -----------------------------------
    rebuilt = {}       # (sura, ayah) -> text
    next_token = {}    # (sura, ayah) -> next expected token index
    order = []         # ayat in reading order
    first_page = {}
    headers = basmalas = 0
    all_lines = []  # (page, line) in reading order, across page breaks
    for p in range(1, 605):
        page = json.load(open(f'{ASSETS}/pages/{p:03d}.json', encoding='utf-8'))
        check(page['p'] == p, f'page file {p} says it is page {page["p"]}')
        lines = page['lines']
        want = 8 if p <= 2 else 15
        check(len(lines) == want, f'page {p} has {len(lines)} lines, expected {want}')
        all_lines += [(p, line) for line in lines]
    for i, (p, line) in enumerate(all_lines):
        if line['t'] == 's':
            headers += 1
            # A header can end a page; its basmala then opens the next.
            nxt = all_lines[i + 1][1]['t'] if i + 1 < len(all_lines) else None
            if line['sura'] in (1, 9):
                check(nxt == 'a', f"sura {line['sura']} header on page {p} is not followed by an ayah line")
            else:
                check(nxt == 'b', f"sura {line['sura']} header on page {p} is not followed by the basmala")
        elif line['t'] == 'b':
            basmalas += 1
        else:
            check(line['segs'], f'page {p} has an ayah line with no words')
            for s, a, start, toks, seps in line['segs']:
                key = (s, a)
                # One separator per token, except after an ayah's last
                # token (its mark), which has none.
                n_tokens = sum(ch in ' \u00a0' for ch in source[key]) + 1
                ends = start + len(toks) == n_tokens
                check(len(seps) == len(toks) - (1 if ends else 0),
                      f'{key}: {len(toks)} tokens but {len(seps)} separators on page {p}')
                if key not in rebuilt:
                    check(not order or order[-1] < key, f'{key} is out of reading order')
                    order.append(key)
                    rebuilt[key] = ''
                    next_token[key] = 0
                    first_page[key] = p
                check(start == next_token[key], f'{key}: token {start} on page {p}, expected {next_token[key]}')
                for n, t in enumerate(toks):
                    rebuilt[key] += t + (seps[n] if n < len(seps) else '')
                next_token[key] = start + len(toks)
    check(headers == 114, f'{headers} sura headers')
    check(basmalas == 112, f'{basmalas} basmala lines')
    check(len(rebuilt) == 6236, f'{len(rebuilt)} ayat on the pages')

    round_trip = [k for k in source if rebuilt.get(k) != source[k]]
    for k in round_trip:
        print('  round trip differs:', k)
    check(not round_trip, f'round trip: {len(round_trip)} ayat differ from the source')

    seps = meta['basmala_seps']
    basmala = ''.join(t + (seps[n] if n < len(seps) else '')
                      for n, t in enumerate(meta['basmala']))
    check(source[(1, 1)].startswith(basmala) and
          source[(1, 1)][len(basmala):len(basmala) + 1] == '\u00a0' and
          len(source[(1, 1)]) == len(basmala) + 2,
          'the basmala is not 1:1 without its ayah mark')

    # --- ayah table ----------------------------------------------------------
    for si, rows in enumerate(meta['ayahs'], start=1):
        for ai, (page, juz, quarter, sajdah) in enumerate(rows, start=1):
            check(page == first_page.get((si, ai)), f'{si}:{ai}: meta page {page} vs pages {first_page.get((si, ai))}')

    # --- cross-check: skeleton vs Tanzil ------------------------------------
    tanzil = {}
    for line in open(f'{SRC}/tanzil/quran-uthmani.txt', encoding='utf-8'):
        line = line.rstrip('\n')
        if line and not line.startswith('#'):
            s, a, t = line.split('|', 2)
            tanzil[(int(s), int(a))] = t
    check(len(tanzil) == 6236, f'{len(tanzil)} ayat in Tanzil')
    t_basmala = skeleton(tanzil[(1, 1)])
    skel_bad = []
    for k in source:
        want = skeleton(tanzil[k])
        if k[1] == 1 and k[0] not in (1, 9):
            # Tanzil prefixes the basmala to aya 1 of every sura but 1 and 9.
            check(want.startswith(t_basmala), f'{k}: Tanzil has no basmala prefix')
            want = want[len(t_basmala):]
        if skeleton(rebuilt.get(k, '')) != want:
            skel_bad.append(k)
    print(f'skeleton vs Tanzil Uthmani: {len(skel_bad)} mismatches')
    for k in skel_bad:
        note = REVIEWED_SKELETON.get(k)
        print(f"  {k[0]}:{k[1]} {'(reviewed) ' + note if note else 'NOT REVIEWED'}")
    check(set(skel_bad) == set(REVIEWED_SKELETON),
          f'skeleton mismatches {sorted(skel_bad)} differ from the reviewed list')

    # --- cross-check: pages vs the KFGQPC page field ----------------------
    page_bad = [k for k in source if first_page.get(k) != kfgqpc_page[k]]
    print(f'ayah pages vs KFGQPC page field: {len(page_bad)} mismatches')
    for k in page_bad:
        print(f'  {k}: layout {first_page.get(k)}, KFGQPC {kfgqpc_page[k]}')
    check(not page_bad, 'ayah pages differ from the KFGQPC page field')
    for s in meta['suras']:
        check(s['page'] == kfgqpc_page[(s['n'], 1)], f"sura {s['n']} starts on {s['page']}, KFGQPC says {kfgqpc_page[(s['n'], 1)]}")

    # --- metadata, reported ------------------------------------------------
    x = ET.parse(f'{SRC}/tanzil/quran-data.xml').getroot()
    t_quarters = [(int(e.get('sura')), int(e.get('aya'))) for e in x.find('hizbs')]
    ours = [tuple(q) for q in meta['quarters']]
    q_diff = sorted(set(ours) ^ set(t_quarters))
    print(f'quarter starts vs Tanzil: differ at {q_diff} '
          '(ours follow the ۞ printed in the KFGQPC text)')
    check(q_diff == [(15, 49), (15, 50)], f'unexpected quarter differences {q_diff}')

    juz_of = {}
    for si, rows in enumerate(meta['ayahs'], start=1):
        for ai, row in enumerate(rows, start=1):
            juz_of[(si, ai)] = row[1]
    j_diff = sorted(k for k in source if juz_of[k] != kfgqpc_juz[k])
    print(f"juz vs KFGQPC 'jozz' field: {len(j_diff)} ayat differ: {j_diff} "
          "(ours follow Tanzil's juz starts, which match the ۞ in the text)")

    # --- anchors ----------------------------------------------------------------
    check(meta['suras'][1]['page'] == 2, 'Al-Baqarah does not start on page 2')
    check(first_page[(18, 1)] == 293, f'18:1 is on page {first_page[(18, 1)]}, not 293')
    check(first_page[(114, 1)] == 604, f'An-Nas starts on page {first_page[(114, 1)]}, not 604')
    # From the printed Madinah Mushaf (the owner's copy, 2026-09-30).
    juz_starts = [tuple(j) for j in meta['juz']]
    check(juz_starts[10] == (9, 93) and first_page[(9, 93)] == 201,
          f'juz 11 starts at {juz_starts[10]}, not 9:93 on page 201')
    check((15, 49) in [tuple(q) for q in meta['quarters']],
          'no rub starts at 15:49')
    flagged = {(si, ai) for si, rows in enumerate(meta['ayahs'], start=1)
               for ai, row in enumerate(rows, start=1) if row[3]}
    check(flagged == SAJDAH_AYAT, f'sajdah ayat flagged: {sorted(flagged)}')

    # --- determinism --------------------------------------------------------
    with tempfile.TemporaryDirectory() as tmp:
        subprocess.run([sys.executable, 'tool/build_mushaf_assets.py', tmp],
                       check=True, stdout=subprocess.DEVNULL)
        for rel in ['assets/quran/meta.json', 'assets/fonts/uthmanic_hafs_v20.ttf',
                    'assets/fonts/surah-name-v4.ttf'] + \
                   [f'assets/quran/pages/{p:03d}.json' for p in range(1, 605)]:
            if not filecmp.cmp(rel, os.path.join(tmp, rel), shallow=False):
                check(False, f'{rel} differs from a fresh build')
                break

    print()
    print('counts: 114 suras, 6236 ayat, 604 pages, 30 juz, 240 quarters, 15 sajdah')
    print(f'round trip: {6236 - len(round_trip)}/6236 ayat identical to the source')
    if failures:
        print(f'{len(failures)} check(s) FAILED')
        sys.exit(1)
    print('all checks passed')


if __name__ == '__main__':
    main()
