# Mushaf visual check

A script cannot prove typography. These are release-build screenshots from the
`Pixel_9_Pro_XL` emulator (1344×2992, dark theme), taken 2026-09-30 at version
1.1.0. Compare each with the same page of a printed **King Fahd Complex
Madinah Mushaf, Hafs, 1421H print or later** (the 604-page, 15-line edition):
the lines should break at the same words, and every letter and mark should
match.

**Before the production release, someone who knows the Mushaf well should
review these pages, and the app itself on a real phone.**

| Page | File | What to look at |
|---|---|---|
| 1 | `p001.png` | Al-Fatiha: 8 lines, centred, the basmala as ayah 1. |
| 2 | `p002.png` | Al-Baqarah header, basmala, 2:1–5 centred. |
| 3 | `p003.png` | First full page: 15 justified lines, 2:6–16. |
| 10 | `p010.png` | 2:72 «فَٱدَّٰرَٰءۡتُمۡ»: the one word whose hamza is encoded differently from Tanzil's text. It should look as printed. |
| 27 | `p027.png` | Lines 14–15: two copies of the layout data differ here by one word. |
| 50 | `p050.png` | Aal-E-Imran header and basmala at the top of a full page. |
| 106 | `p106.png` | End of An-Nisa, Al-Ma'idah header mid-page. |
| 187 | `p187.png` | At-Tawba: header, and no basmala. |
| 282 | `p282.png` | Al-Isra header mid-page. |
| 293 | `p293.png` | 17:107–109 sajdah: the line over «يَخِرُّونَ لِلۡأَذۡقَانِ سُجَّدٗا» and ۩; then Al-Kahf 18:1. |
| 377 | `p377.png` | An-Naml's header. |
| 400 | `p400.png` | A line where quran.com's data disagrees with the layout by one word. |
| 442 | `p442.png` | Ya-Sin. |
| 443 | `p443.png` | Another line where quran.com disagrees by one word. |
| 500 | `p500.png` | Al-Jathiya. |
| 552 | `p552.png` | Line 10 is the widest line in the Mushaf. It should fill the width without being squeezed smaller than its neighbours. |
| 582 | `p582.png` | Juz 30 opens: An-Naba. |
| 589 | `p589.png` | Another line where quran.com disagrees by one word. |
| 600 | `p600.png` | Several short suras, centred last lines. |
| 604 | `p604.png` | Al-Ikhlas, Al-Falaq, An-Nas. |

Known differences from print (by design of the chosen source, see
`docs/quran/SOURCE_DECISION.md`):

* The letters are the KFGQPC's Unicode Uthmanic Hafs font, not the printed
  calligraphy, so words are shaped a little differently and stack less.
* Lines are justified by the spaces between words, not by stretching letters,
  so gaps are wider than in print.
* The rubʿ sign ۞ is drawn as the font draws it (a small star).
* Sura headers are the name in a gold frame, not the printed ornament.
