"""Builds assets/files/suras/<n>.txt from the Tanzil Quran text.

Source: tool/quran_source/quran-simple.txt, downloaded from
https://tanzil.net/download/ as: Simple, "Text (with aya numbers)",
pause marks / sajdah / rub-el-hizb signs OFF (the Janna font has no
glyphs for them), tatweel below superscript alefs ON.

The only thing done to the text is dropping the basmala that Tanzil
prefixes to the first aya of every sura except Al-Fatiha and At-Tawba
(in 95 and 97 its ba carries a shadda),
because the app lists ayat, and the basmala is aya 1 only in Al-Fatiha.
Each aya is written verbatim on its own line.

Run from the project root:  python3 tool/build_quran_assets.py
"""
import os, sys

SRC = 'tool/quran_source/quran-simple.txt'
OUT = 'assets/files/suras'
COUNTS = [7,286,200,176,120,165,206,75,129,109,123,111,43,52,99,128,111,110,98,135,112,78,118,64,77,227,93,88,69,60,34,30,73,54,45,83,182,88,75,85,54,53,89,59,37,35,38,29,18,45,60,49,62,55,78,96,29,22,24,13,14,11,11,18,12,12,30,52,52,44,28,28,20,56,40,31,50,40,46,42,29,19,36,25,22,17,19,26,30,20,15,21,11,8,8,19,5,8,8,11,11,8,3,9,5,4,7,3,6,3,5,4,5,6]

suras = {}
BASMALA = None  # taken from Al-Fatiha 1:1, plus the space that follows it
for line in open(SRC, encoding='utf-8'):
    line = line.rstrip('\r\n')
    if not line or line.startswith('#'):
        continue
    s, a, text = line.split('|', 2)
    s, a = int(s), int(a)
    if (s, a) == (1, 1):
        BASMALA = text + ' '
    if a == 1 and s not in (1, 9):
        # 95 and 97 carry a shadda on the ba (idgham from the sura before).
        for prefix in (BASMALA, BASMALA.replace('\u0628\u0650', '\u0628\u0651\u0650', 1)):
            if text.startswith(prefix):
                text = text[len(prefix):]
                break
        else:
            sys.exit(f'sura {s}: expected the basmala prefix')
    suras.setdefault(s, []).append((a, text))

assert sorted(suras) == list(range(1, 115))
for s, ayat in suras.items():
    assert [a for a, _ in ayat] == list(range(1, COUNTS[s - 1] + 1)), s
    with open(f'{OUT}/{s}.txt', 'w', encoding='utf-8-sig', newline='') as f:
        f.write('\r\n'.join(t for _, t in ayat) + '\r\n')
print('wrote', len(suras), 'suras,', sum(len(v) for v in suras.values()), 'ayat')
