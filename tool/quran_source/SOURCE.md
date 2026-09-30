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
decided on 2026-09-30 to use them and credit QUL. QUL's own download buttons
need a login, so the two databases come from public mirrors, pinned to a commit.

| File | From | Bytes | sha256 |
|---|---|---|---|
| `qpc-v2-15-lines.db`: "KFGQPC V2 (1421H print)" layout, QUL resource https://qul.tarteel.ai/resources/mushaf-layout/10 | extracted unchanged from `qpc-v2-15-lines.db.zip` (99,450 B, sha256 `29941fa5e8504bc50a3007e2d1ef2f65280c483ea8b465662141f2ce7cdaed3d`) at https://raw.githubusercontent.com/blueheron786/quranic-universal-library-mushaf-layouts/5fe1704df9630ec9ed523c34a289ad920a99989e/qpc-v2-15-lines.db.zip (repo has no licence file; zip entry dated 2025-05-26) | 241,664 | `26f1afbe0417bb9a724780a5f6ffb2a19d58a442836fc74b29f88c364667d6cf` |
| `qpc-quran-script.db`: QUL "QPC V2 Glyph word-by-word" (https://qul.tarteel.ai/resources/quran-script/61). Only its word id and location are used. | https://raw.githubusercontent.com/thebayaan/Bayaan/cf1b710f37c0e4734a4a40aebfc208576b42293b/data/mushaf/qcf/qpc-quran-script.db (repo licence AGPL-3.0) | 2,437,120 | `4bf9549dfcfd367d4d4b151bd58b51af63b677d1c980cf5e52541c2f981d7e6d` |
| `surah-name-v4.ttf`: QUL "Surah name v4" (https://qul.tarteel.ai/resources/font/457) | https://static-cdn.tarteel.ai/qul/fonts/surah-names/v4/surah-name-v4.ttf | 215,592 | `026cfe8ac461531a7b1c8e4edd05ce3343f09e9c73447ff14c6bc93f3193d661` |

Notes:
- `qpc-v2-15-lines.db`'s `info` table reads "QCF V2 ( 1421H print )", with 604
  pages and 15 lines.
- A second mirror of the V2 layout (Bayaan, `data/mushaf/qcf/qpc-mushaf-layout.db`)
  differs only on page 27, lines 14–15 (one word, id 3478 vs 3479). Page 27 is
  on the owner's visual check list.
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

## quran-simple.txt

Tanzil Simple, the text of the old ayah-card list. It goes in Phase 3, since
the owner removed list mode.
