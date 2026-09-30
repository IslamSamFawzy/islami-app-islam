# Mushaf source decision (Phase 1)

Goal: show the Quran as the King Fahd Complex (KFGQPC) Madinah Mushaf prints it
(Hafs ʿan ʿĀṣim): the same Uthmani rasm and marks, the same 604 pages of 15
lines, breaking at the same words, fully offline.

Researched 2026-09-30. Every URL below was opened. Where a site could not be
reached from here, that is said, and the Wayback Machine copy is quoted instead.

## TL;DR

| | A-V2: QPC glyph fonts, 1421H | A-V1: QPC glyph fonts, 1405H | **B: KFGQPC Uthmanic Hafs text + font** | C: page images |
|---|---|---|---|---|
| Looks like the print | pixel-level | pixel-level, older print | same text, marks and line breaks; the calligraphy is simpler (fewer stacked ligatures) | pixel-level |
| Text searchable/selectable | no (glyph codes) | no | **yes** | no |
| Added to the AAB (compressed) | **≈ 118 MB** | ≈ 50 MB | **≈ 2–3 MB** | 48–125 MB |
| Font licence | no written licence; the fonts call themselves "Test Font, KFGQPC" | no written licence | **written EULA in the font: use, copy, distribute** | no clear grant (typically CC BY-NC-ND) |
| Line-break (layout) data | QUL V2 layout (no licence text) | QUL V1 layout (no licence text) | QUL V2 layout (no licence text) | baked into the images |

**Recommendation: option B**, with the QUL V2 (1421H) 15-line layout. It meets
every bullet of the goal: letter-for-letter rasm and marks, sajdah and pause
marks, ayah-end markers, 604 pages, 15 lines, the same word at every line break.
It does this with the KFGQPC's own text and font under a written licence, for
about 2–3 MB. The one thing it does not match is the printed calligraphy glyph
for glyph. Only A-V2 does that, and it costs about 118 MB and rests on fonts with no
written licence. Screenshots of all three: `docs/quran/spike/`.

## Option A: KFGQPC per-page glyph fonts (QPC V1 / V2)

### Where it comes from
- QUL resource pages (no version or date shown):
  - V1 fonts (1405H print): https://qul.tarteel.ai/resources/font/238
  - V2 fonts (1421H print): https://qul.tarteel.ai/resources/font/249
  - V1 15-line layout: https://qul.tarteel.ai/resources/mushaf-layout/15
  - V2 15-line layout: https://qul.tarteel.ai/resources/mushaf-layout/10
  - Word glyph codes: V1 https://qul.tarteel.ai/resources/quran-script/57, V2 https://qul.tarteel.ai/resources/quran-script/61
- QUL's download buttons need a (free) login. For the spike I used:
  - Fonts from the public CDN `https://static-cdn.tarteel.ai/qul/fonts/quran_fonts/{v1|v2}/{ttf|woff|woff2}/p{N}.{ext}`. This pattern was found by probing, not published on a page. All 3,624 files returned 200.
  - quran.com serves the same bytes (`quran/quran.com-frontend-next`, `src/utils/fontFaceHelper.ts`).
  - Layout DBs from a public mirror of QUL with no licence file: https://github.com/blueheron786/quranic-universal-library-mushaf-layouts (files dated 2025-05-26).
- What the font files say about themselves:
  - V1: `QCF_P001…604`, "version 5.10", "King Fahad Complex, All rights reserved.", created 2005-05-15.
  - V2: `QCF2001…2604`, version "KFGQPC TEST", copyright "Test Font, KFGQPC", created 2013-10-08.

### Licence
There is no licence inside the V1/V2 fonts. The closest official text is the KFGQPC
digital-Mushaf page, which covers "True Type Font" among other formats. The live site
refused the connection, so this is quoted from the Wayback copy of
http://dm.qurancomplex.gov.sa/copyright-2/ (snapshot 2019-08-19):

> "The Qur'an Printing Complex is honored to present to the Muslim public a
> complete free digital copy of Mus'haf al-Madinah published by the Complex, in
> the following formats: • Adobe Illustrator files • PDF files • High quality
> images • True Type Font Mus'haf al-Madinah in these previous formats can be
> used for free in all personal, individual businesses, in works of governmental
> departments & agencies, in the publications of both private and national
> institutions, also allows Qur'an printing *, digital publishing, & for media
> use, can be used also in websites, software, and other similar intermediates."

QUL FAQ (https://qul.tarteel.ai/faq):

> "The resources available on QUL vary in their copyright status. Some are in
> the public domain, while others may be subject to specific licenses."
>
> "Yes, you can use QUL data in commercial projects. However, please review the
> licensing terms for each resource. Some data may have restrictions or require
> attribution, while others are freely available for commercial use."

The QUL font, layout and script pages carry no licence text. GitHub issue
TarteelAI/quranic-universal-library#768 (2026-09-24) asked QUL for this
permission. Nobody from QUL answered, and the author closed it.

What this means for each question:
- **Modify:** not granted. So no subsetting and no format conversion.
- **Attribution:** not specified. Crediting KFGQPC and QUL is the safe course.
- **Redistribution in an app:** implied ("can be used also in websites, software") but not stated explicitly.

### Size (HEAD requests on all 604 files)
| | ttf | woff2 |
|---|---|---|
| V1 | 95.0 MB | 48.0 MB |
| V2 | 208.1 MB | 97.7 MB |

- Flutter's `FontLoader` needs TTF/OTF, not WOFF2.
- Measured deflate ratio on the sample pages: V1 0.53, V2 0.57. So in the AAB, V1 adds about **50 MB** and V2 about **118 MB**.
- Plus the layout DB (0.24 MB) and word glyph codes (about 2.4 MB).

### Layout mapping
- `pages(page_number, line_number, line_type, is_centered, first_word_id, last_word_id, surah_number)`.
- Line types: `ayah` (8,820), `surah_name` (114; no words), `basmallah` (112; no words).
- Pages 1 and 2 have 8 lines.
- `first_word_id..last_word_id` indexes QUL's word table (83,668 words). Each word's glyph code is one or more codepoints in that page's font.
- **Ayah-end markers are words of their own** (6,236), drawn by the page font.
- The app draws the sura headers itself (e.g. with QUL's sura-name font) and the basmala line (for example with the page-1 glyphs).
- The V1 and V2 line breaks differ (4,661 of 9,046 line rows), so each font version needs its own layout.

### Shipping
About 118 MB for V2 is too much for the base module. It would need a Play Asset Delivery
install-time pack, and Flutter has no official support for that:
- flutter/flutter#100855 is still open.
- The Android docs (https://developer.android.com/guide/playcore/asset-delivery/integrate-java) say install-time packs are "immediately available at app launch. Use the Java AssetManager API". That means a small Kotlin MethodChannel, because `rootBundle` cannot read them.
- It would still install with the app and work offline.

### Rendering (spike)
Near-perfect. A-V2 matches the modern print closely, including the sajdah overline on
17:107–109 and the ۩ mark (page 293). The fonts are plain TrueType, with no colour tables
and no GSUB. Lines are justified in code.

Risk: when a page font fails to load, Flutter silently falls back to a system font and
draws wrong but plausible letters, so the app needs a load guard.

### Verification
- Word glyph codes can't be compared to text directly.
- Verify through the QUL word table's Uthmani text, which is a different source from the glyphs.
- Compare the page numbers against a second dataset.

### Other needs
- Juz/hizb/rubʿ/sajdah metadata: QUL metadata (login, no licence) or Tanzil.
- The sura-name font from QUL.
- Three verses (2:181, 8:6, 13:37) split words differently between QUL and quran.com, and need the official QUL word table.

## Option B: KFGQPC Uthmanic Hafs text + font (recommended)

### Where it comes from
- The KFGQPC developer page is https://qurancomplex.gov.sa/en/techquran/dev/. It is unreachable from here, so I used the Wayback copy: https://web.archive.org/web/20250219215515id_/https://qurancomplex.gov.sa/en/techquran/dev/.
- The package is "Unicode Uthmanic Font (Hafs Narration)", at https://download.qurancomplex.gov.sa/resources_dev/UthmanicHafs_v2-0.zip.
  - The page says "Update 13.0". The file was created 16-9-2020 and last modified 19-09-2023.
  - MD5 on the page: CF6841AEA5B1D1FD70D032B43FF08278.
  - The copy I downloaded from the Wayback Machine has that same MD5.
- The zip's `read.me`: "Version: 2.0 / Date: 2022-09-07 / Update: 13.0".
- Contents:
  - `hafsData_v2-0` (JSON/CSV/SQL/XML/XLSX): 6,236 ayat, with the fields id, jozz, page, sura_no, sura_name_en/ar, line_start, line_end, aya_no, aya_text, aya_text_emlaey.
  - The font `uthmanic_hafs_v20.ttf` (795,444 B).
- The package's page numbers are the 1421H print: they match the V2 layout for all 6,236 ayat.
- Layout: the QUL V2 15-line layout (same as A-V2). The KFGQPC data only gives each ayah's page and its first and last line, not where each line breaks within the ayah.

### Licence (font name table ID 13, verbatim, identical in v2.0 and v2.2)

> ELECTRONIC END-USER LICENSE AGREEMENT
>
> By installing this Font You accept all the terms and conditions of this Agreement.
>
> Copyright (c) 2010 by King Fahd Glorious Quran Printing Complex (KFGQPC),
> AlMadinah AlMunawarrah, Kingdom of Saudi Arabia. All Rights Reserved. KFGQPC
> retains full title and ownership of this Typeface both as artwork and font
> software. This Agreement does not grant you any intellectual property rights
> in the Font.
>
> Permission is hereby granted, Free of Cost, to any person obtaining a copy of
> this Font accompanying this license, the rights to Use, Copy, Distribute,
> subject to the following conditions:
>
> 1. The Font Software cannot be Sold, Modified, Altered, Translated, Reverse
> Engineered, Decompiled, Disassembled, Reproduced or Attempted to discover the
> Source Code of this Font in no means.
>
> 2. The Font Software is provided "AS IS", […]

The KFGQPC font page (Wayback copy of https://fonts.qurancomplex.gov.sa/wp02/حفص/,
section «حقوق الاستخدام»):

> «…وهو متاح للنسخ والتوزيع والاستعمال مجاناً في المجالات الشخصية والتجارية
> والأعمال الفردية كافة… شريطة ألا ينسب الخط المذكور إلى جهة أخرى غير الجهة
> المالكة لحقوقه… ولا يحق لأي فرد أو أي جهة أخرى إعادة برمجته أو التعديل على
> تراكيبه أو أي جزء من مكوناته بأي شكل ولأي غرض، أو بيعه بمقابل ماديّ مهما كان
> السبب.»

What this means for each question:
- **Copy, distribute and use (commercially too) in an app:** allowed.
- **Modify:** not allowed, so ship the TTF unchanged, with no subsetting.
- **Attribution:** it must not be attributed to anyone but KFGQPC. Credit KFGQPC.

The text package has no separate licence file. The KFGQPC copyright page
(dm.qurancomplex.gov.sa/copyright-2/, quoted under A) is the closest.

### Size
- Font 0.80 MB, which compresses to 0.19 MB.
- The text as compact per-page assets is about 1.5–2 MB raw, and less compressed.
- Layout 0.24 MB.
- **About 2–3 MB added to the AAB.** No asset pack is needed.

### Rendering (spike)
Good. The spike checked every mark on the 8 pages, and:
- Uthmani letters, small high letters and pause marks render correctly.
- The ayah-end markers render with their numbers: the text encodes each ayah number as one codepoint, U+FC00+(n−1), which the font draws as the ornamented marker.
- Lines break at the same words as A-V2.
- Each line is justified by spreading the word gaps. Flutter's `TextAlign.justify` isn't used; each line is laid out on its own.

Differences from print, visible in `b-*.png` next to `a_v2-*.png`:
- Letter shapes are the KFGQPC Unicode design rather than the print's calligraphy, with fewer vertical ligature stacks.
- Word gaps are wider because the glyphs are narrower.
- Letter stretching (kashida) is not used, because the v2 font does not stretch tatweel evenly.

Known risk: flutter/flutter#192891 (open) reports lam-alef not ligating on some Android
devices with an older version of this font (Ver09). **The owner should check on the real
phone.**

### Verification
- **Text:** the KFGQPC text is a second source independent of Tanzil. Strip marks, normalise alef/hamza forms, and compare each ayah's letter skeleton with Tanzil Uthmani 1.1.
- **Pages:** the KFGQPC `page` field is independent of QUL's layout. It already matches V2 for all 6,236 ayat, and the page of every sura's first ayah can be checked against it.

### Other needs
- **Juz:** the KFGQPC text's `jozz` field.
- **Rubʿ starts:** marked by ۞ in the text (199 marks, plus the juz starts).
- **Sajdah:** ۩ in the text, 15 marks including 22:77.
- **Hizb:** derived from the rubʿ marks.
- **Cross-check:** Tanzil `quran-data.xml` (CC BY). Note that its `pages` section follows the 1405H print, so use its juz, rubʿ and sajdah data only, not its pages.
- **Sura headers:** either QUL's sura-name font (no licence text; its embedded copyright is "King Fahad Complex") or the KFGQPC font's own text inside a drawn frame (clean licence).

### Found in the source (reported, not patched)
- **2:286** has an ordinary space (U+0020) before its ayah-number codepoint; every other ayah has NBSP (U+00A0).
- **Word counts:** five ayat split into a different number of words in the KFGQPC text than in QUL's word list: 2:6 (QUL 11 / KFGQPC 12), 15:7 (8/7), 27:20 (12/11), 36:22 (8/7) and 37:130 (3/4). The layout gives line breaks as QUL word ids, so these five need a word alignment that is checked, not guessed. None is on a line break unless the verification script says so.

## Option C: page images (rejected; fallback only)
- quran_android's image sets: https://files.quran.app/hafs/madani/zips/images_{W}.zip
  (via android.quran.com): 800 px 48.2 MB, 1024 px 63.4 MB, 1260 px 81.1 MB, 1920 px 124.9 MB.
- Licence: the quran_android README says "Please keep use of this code for non-profit
  purposes only … the data is licensed under the various licenses of the data's authors
  (typically, this is CC BY-NC-ND […])". That is no clear redistribution grant.
- Drawbacks:
  - No text to search, copy or read aloud.
  - Blurry beyond its native width.
  - Dark mode means inverting colours, which distorts the frames and coloured marks.
  - 48–125 MB.

## Independent verification data (for Phase 2)
- **Tanzil Uthmani text 1.1** (Feb 2021): https://tanzil.net/pub/download/index.php?marks=true&sajdah=true&alef=true&tatweel=true&quranType=uthmani&outType=txt-2&agree=true
  - `quran-uthmani.txt`, 1,396,087 B, sha256 `6933e133…39ec5f`.
  - Licence (file header): "License: Creative Commons Attribution 3.0 … Permission is granted to copy and distribute verbatim copies of this text, but CHANGING IT IS NOT ALLOWED. This Quran text can be used in any website or application, provided that its source (Tanzil Project) is clearly indicated, and a link is made to tanzil.net to enable users to keep track of changes."
  - Aya 1 of every sura except 1 and 9 carries the basmala prefix, which must be stripped before comparing.
- **Tanzil metadata 1.0:** http://tanzil.net/res/text/metadata/quran-data.xml (license="cc-by").
  - It has 30 juz, 240 rubʿ and 15 sajdas. The 4 obligatory ones are 32:15, 41:38, 53:62 and 96:19; the other 11 are recommended.
  - Its 604 pages match quran_android's `MadaniDataSource.kt` exactly. Both are the 1405H print, not 1421H.
- **Page cross-check for the 1421H layout:** the KFGQPC `page` field, compared with the QUL V2 layout.

## Spike
- Branch `spike/mushaf-render` (not merged).
- The spike renders pages 1, 2, 50, 187, 293, 377, 600 and 604 for A-V1, A-V2 and B, in the app's dark/gold theme, plus pages 2 and 293 on a paper background.
- Screenshots are in `docs/quran/spike/`, named `<option>-p<page>[-paper].png`.
- All options read well on the dark/gold theme, so a paper theme is optional rather than required.

## Questions for the owner
1. **Option:** B (recommended, +≈2–3 MB) or A-V2 (print-identical calligraphy, +≈118 MB, needs an install-time asset pack and fonts without a written licence)?
2. **Layout licence:** all 15-line word-level layouts trace to QUL, whose pages carry no licence. Proceed with QUL's V2 layout and credit it, or first ask QUL/Tarteel for written permission? QUL downloads also need a free account. Can you create one so the source files come from QUL itself rather than a mirror?
3. **List mode:** does the ayah-card list stay as a second reading mode (then it would use the same KFGQPC text and font), or go?
4. **Size:** is +3 MB (B) acceptable? If A-V2: is +118 MB acceptable?
5. **Sura headers:** QUL's sura-name font (looks like print, no licence text) or the name in the KFGQPC font inside a drawn frame (clean licence)?

## Owner's decisions (2026-09-30)
1. **Option B**: the KFGQPC Uthmanic Hafs text and font (+≈3 MB accepted).
2. **Layout**: use the QUL V2 15-line layout and credit QUL.
3. **List mode**: removed. The Tanzil Simple text and its script go.
4. **Sura headers**: QUL's sura-name font (`surah-name-v4.ttf`). Correction to
   the question as asked: this font carries no copyright or licence text at
   all; it was QUL's other header font (`QCF_SurahHeader_COLOR`) that names
   "King Fahad Complex".
