# Quran sources

Every file here is exactly as downloaded (`.gitattributes` stops Git from
touching line endings). Nothing in this folder is edited, by hand or by script.
`tool/build_mushaf_assets.py` reads these files and
`tool/verify_mushaf_assets.py` checks the result against them. See
`docs/quran/SOURCE_DECISION.md` for why these sources were chosen.

Downloaded 2026-09-30.

## kfgqpc/: the text and the font (King Fahd Glorious Quran Printing Complex)

"Unicode Uthmanic Font (Hafs Narration)", package `UthmanicHafs_v2-0.zip`.

- Official URL: https://download.qurancomplex.gov.sa/resources_dev/UthmanicHafs_v2-0.zip,
  listed on https://qurancomplex.gov.sa/en/techquran/dev/ with "Update 13.0",
  created 16-9-2020, last modified 19-09-2023, MD5 `CF6841AEA5B1D1FD70D032B43FF08278`.
- The KFGQPC site does not answer from here, so the zip came from the Wayback
  Machine copy:
  https://web.archive.org/web/20250417225336id_/https://download.qurancomplex.gov.sa/resources_dev/UthmanicHafs_v2-0.zip
  Its MD5 equals the official one above. The zip: 10,729,285 bytes, sha256
  `a7b0e5591945712ec5e4d6142938ae4d1e9b49bdc89dff06222789bfebdfd72c`.
- `read.me` says: Version 2.0, Date 2022-09-07, Update 13.0.

| File (unchanged from the zip) | Bytes | sha256 |
|---|---|---|
| `hafsData_v2-0.json` (from `UthmanicHafs_v2-0 data/`) | 3,594,552 | `d2960b3217962e7e4252abdcece67bea3d6b48271e4cd3af45bbbb2dd5c872ca` |
| `read.me` (from `UthmanicHafs_v2-0 data/`) | 2,302 | `d334f9ad7c70c3a95778509ba7b705b25bcc7a76fea51af135559b93ee60cdb8` |
| `uthmanic_hafs_v20.ttf` (from `UthmanicHafs_v2-0 font/`) | 795,444 | `d560bbbc7a90a4f4d416d206a5ac48bd8a1ad00273d64d232f16ca54941bd041` |

Licence: `LICENSE.txt`, extracted verbatim from the font's name table. The
font may be used, copied and distributed free of cost. It may not be sold,
modified or altered, so it ships byte for byte, not subset. Its name table
ID 0 says it "may not be reproduced, modified without the express written
approval" of KFGQPC. The KFGQPC font page (Wayback copy of
https://fonts.qurancomplex.gov.sa/wp02/حفص/) allows copying, distribution and
use, personal and commercial, provided the font is not attributed to anyone but
KFGQPC.

## qul/: the 15-line layout and the sura names (Quranic Universal Library, Tarteel)

QUL (https://qul.tarteel.ai) publishes no licence text for these. The owner
decided on 2026-09-30 to use them and credit QUL, and has asked QUL for
permission; production release waits for the answer.

The owner downloaded the two databases from QUL itself with his account on
2026-09-30. The pages show no version number. The zips are kept as downloaded
in `qul-official/`; the `.db` files in `qul/` are their contents, unchanged.

| File in `qul/` | Official source (owner's QUL account, 2026-09-30) | Bytes | sha256 |
|---|---|---|---|
| `qpc-v2-15-lines.db`: "KFGQPC V2 (1421H print)" layout | https://qul.tarteel.ai/resources/mushaf-layout/10, "Download sqlite": `qul-official/qpc-v2-15-lines.db.zip` (99,483 B, sha256 `697cbc7f16db1f56b6d95c4d11a9eea074ad4759babd2d75abcad5738e2fdf96`), inner `qpc-v2-15-lines.db` dated 2025-11-18 | 241,664 | `e4df98f35dd3b8927ff096337c8739e0f0b12c8ba622834c345eaa4c3e28dd8c` |
| `qpc-quran-script.db`: "QPC V2 Glyph word-by-word"; only word id and location are used | https://qul.tarteel.ai/resources/quran-script/61, "Download sqlite": `qul-official/qpc-v2.db.zip` (1,197,952 B, sha256 `a766a033cad47b36f00f493f5f0541d5f07e1336857eaa6feba92465af3f68bb`), inner `qpc-v2.db` dated 2025-05-28 | 2,437,120 | `4bf9549dfcfd367d4d4b151bd58b51af63b677d1c980cf5e52541c2f981d7e6d` |
| `surah-name-v4.ttf`: "Surah name v4" | https://qul.tarteel.ai/resources/font/457, via https://static-cdn.tarteel.ai/qul/fonts/surah-names/v4/surah-name-v4.ttf. **The owner's own download is not in `qul-official/` yet**, so this one is not yet compared. | 215,592 | `026cfe8ac461531a7b1c8e4edd05ce3343f09e9c73447ff14c6bc93f3193d661` |

Compared with the public mirrors used until 2026-09-30:
- `qpc-quran-script.db`: byte-identical to the Bayaan mirror
  (https://raw.githubusercontent.com/thebayaan/Bayaan/cf1b710f37c0e4734a4a40aebfc208576b42293b/data/mushaf/qcf/qpc-quran-script.db).
- `qpc-v2-15-lines.db`: differs from the blueheron786 mirror (sha256
  `26f1afbe…d6cf`, zip entry dated 2025-05-26). Same schema, same `info`, and
  9,044 of 9,046 `pages` rows are equal; page 27 lines 14–15 differ by one
  word: word 3479 (2:181 word 6, «فَإِنَّمَآ», the word after «سَمِعَهُۥ»)
  opens line 15 in QUL's file and ended line 14 in the mirror. QUL's file is byte-identical to the
  Bayaan mirror's `qpc-mushaf-layout.db`. The assets were rebuilt from QUL's
  file; only `assets/quran/pages/027.json` changed.

Notes:
- `qpc-v2-15-lines.db`'s `info` table reads "QCF V2 ( 1421H print )", with 604
  pages and 15 lines.
- `surah-name-v4.ttf` carries no copyright or licence text in its name table.

QUL FAQ (https://qul.tarteel.ai/faq), verbatim: "The resources available on
QUL vary in their copyright status. Some are in the public domain, while others
may be subject to specific licenses." and "Yes, you can use QUL data in
commercial projects. However, please review the licensing terms for each
resource. Some data may have restrictions or require attribution, while others
are freely available for commercial use."

## tanzil/: independent data for verification, and the metadata

| File | URL | Bytes | sha256 |
|---|---|---|---|
| `quran-uthmani.txt`: Tanzil Uthmani 1.1 (Feb 2021), `sura\|aya\|text`, marks, sajdah signs, alef and tatweel on (the download page's defaults) | https://tanzil.net/pub/download/index.php?marks=true&sajdah=true&alef=true&tatweel=true&quranType=uthmani&outType=txt-2&agree=true | 1,396,087 | `6933e133dd56db778c801bf738848454e43648105a151e8d84d86a7cae39ec5f` |
| `quran-data.xml`: Tanzil metadata 1.0 (suras, juz, quarters, sajdas) | https://tanzil.net/res/text/metadata/quran-data.xml | 77,234 | `8867c1d88191472adec9db694b3cd9f135b1a2ef580574d32cf888dcb22c5c7a` |

- `quran-uthmani.txt` is used only to verify, never shipped. Its licence is in its
  own header: Creative Commons Attribution 3.0, verbatim copies only, "provided
  that its source (Tanzil Project) is clearly indicated, and a link is made to
  tanzil.net".
- `quran-data.xml` carries `license="cc-by"`,
  `copyright="(C) 2008-2009 Tanzil.info"`. Its `pages` follow the 1405H print, so
  they are not used.
