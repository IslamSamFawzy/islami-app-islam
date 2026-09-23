# Islami — Design Spec (Figma → Flutter)

Source of truth: https://www.figma.com/design/rYIdiZRmbIhvvoGbLPQ9Al/Islami?node-id=9-19
Page: **UI** · Frame size: **430 × 932** · Single theme: **Dark**

> This document was written by reading every frame in the Figma file. Use it together with the
> Figma link. If you have Editor access on the file, prefer `get_design_context` (Figma MCP) for
> exact values; this spec is the fallback and the summary of intent.

---

## 1. Design tokens

| Token | Value | Where |
|---|---|---|
| `backgroundColor` | `#202020` | Scaffold, screen backgrounds, text on gold, active nav pill |
| `primaryColor` (gold) | `#E2BE7F` | Cards, tiles, bottom nav bar, borders, headings on dark |
| `textColor` (cream) | `#FEFFE8` | Section titles / body text on dark |
| `titleTextColor` | `#202020` | Text drawn on gold surfaces |
| White | `#FFFFFF` | Sura list text, sura number, counter |

These already exist in `lib/core/theme/app_colors.dart` — **do not introduce new hex values**; add to
`AppColors` if a new shade is genuinely needed.

### Typography
- **Janna LT Bold** (`assets/fonts/janna-lt-Bold.ttf`, family `Janna`) for **everything** — Arabic and English.
- **No Arial / no default system font anywhere** (Figma review comment #6: Arial leaked into the
  unselected Radio tab state — that is a bug, not a design decision).
- Scale in use: 24 (headline), 20 (title), 16 (body large), 14 (body medium). All `FontWeight.w700`.

### Shape & spacing
- Screen horizontal padding: **20**
- Card radius: **20** (most-recent cards), **18** (radio tiles), **16** (azkar cards), **12** (search field)
- Bottom nav: gold bar, selected item = dark rounded pill (`radius ~40`) around a white icon, label under it.
- Every main tab screen shows: dimmed mosque background photo + centered **"Islami"** wordmark
  (`assets/images/img_header.png`) at the top.

---

## 2. Screens

### 2.1 Splash Screen
Two frames exist:
- **Art variant** — full-bleed dark photo, glow, lantern, corner ornaments, centered `islami_logo`.
- **Plain variant** — flat `#202020`, centered gold mosque logo only.

Both end with, at the bottom, the **Route** logo + `Supervised by Mohamed Nabil` (cream, 14).
Current code implements the art variant. Keep it, but **add the Route + supervisor footer**.

Navigation: after ~3s → **Intro** on first launch, otherwise → **HomeLayout**.

---

### 2.2 Intro / Onboarding — 5 pages (NOT implemented yet)
A `PageView` of 5 pages. Background `#202020`, no photo. Each page:

1. **Header** — small "Islami" wordmark with faint mosque line-art (`img_header`), centered, top.
2. **Illustration** — large gold line-art, centered, ~55% of the screen height.
3. **Title** — gold `#E2BE7F`, 24, bold, centered.
4. **Body** — gold/cream, 16, bold, centered, up to 2 lines, horizontal padding 24.
5. **Bottom bar** — `Back` (left, hidden on page 1) · dots indicator (center) · `Next` (right, `Finish` on page 5).
   Active dot = elongated gold pill; inactive dots = small muted dots.

| # | Title | Body | Illustration |
|---|---|---|---|
| 1 | `Welcome To Islami App` | — | Arabic calligraphy (تبارك) |
| 2 | `Welcome To Islami` | `We Are Very Excited To Have You In Our Community` | mosque line-art |
| 3 | `Reading the Quran` | `Read, and your Lord is the Most Generous` | open Quran + mosque |
| 4 | `Azkar` | `Praise the name of your Lord, the Most High` | hands holding a tasbeh |
| 5 | `Holy Quran Radio` | `You can listen to the Holy Quran Radio through the application for free and easily` | vintage microphone |

**Figma review fixes to apply while building:**
- Page 1 in Figma says *"Welcome To Islmi App"* → typo, must be **Islami** (comment #5).
- Page 4 in Figma is labelled *"Bearish"* → wrong word, must be **Azkar** (comment #7).

`Finish` persists `onboarding_seen = true` in `SharedPreferences` and navigates to `HomeLayout`
(replacing the stack). Splash reads that flag.

---

### 2.3 Quran tab (Home Screen)
Top → bottom:
1. Header wordmark.
2. **Search field** — fill `#202020` @ 70% opacity, 1px gold border, radius 12, gold Quran SVG as
   prefix icon, hint `Sura Name` (cream). Typing filters the list **and hides the "Most Recently" section**
   (see the "الفاتحة" search frame: only the header, the field and the matching sura remain).
3. **`Most Recently`** — cream, 20 bold, left aligned. Horizontal `ListView` of gold cards:
   radius 20, width ~70% of screen, height ~145, padding 12. Inside: EN name (24, dark), AR name (24, dark),
   `112 Verses` (14, dark) on the left; illustration (`img_most_recent`) on the right.
   Empty state: a short cream line ("No recently read suras yet").
4. **`Suras List`** — cream, 20 bold. Each row: star badge (`img_sura_number_theme`, 50×50) with the
   sura number in white, 24 gap, then EN name (20, white) + `7 Verses` (14, white) stacked, and the AR
   name (20, white) pinned to the right. A thin gold divider sits under the text column.

Tapping a row records it as recent and pushes **Sura Details**.

---

### 2.4 Sura Details
- Transparent `AppBar`, gold back arrow, centered EN sura name (gold, 20 bold).
- Under it: gold AR sura name (24) centered between `img_left_corner` / `img_right_corner` ornaments.
- **Verses.** The Figma shows two treatments — implement the **card list** one:
  - Each ayah is its own box: 1px gold border, radius ~8, transparent fill, gold RTL text centered,
    and the **verse number rendered AFTER the ayah text**, not before
    (Figma review comment #9 — this matches the standard Mushaf reading pattern; the current code
    already does this, keep it).
  - The ayah currently being read/played is **filled solid gold with dark text**.
- Bottom: `img_bottom_decoration` mosque silhouette pinned to the bottom of the screen.

---

### 2.5 Hadith tab
- Header wordmark, then a **carousel** (`carousel_slider`, viewportFraction ≈ 0.8, enlarge center page)
  of parchment cards. The neighbouring cards **peek** at both edges — that peek is part of the design.
- Card: gold parchment background, radius ~20, corner ornaments top-left/top-right, centered dark title
  (`الحديث الأول`, 20 bold), then the hadith body — dark, RTL, **scrollable inside the card**.
- Tapping a card opens **Hadith Details**: dark screen, `AppBar` (back + `Hadith 1`), AR title, full text.

---

### 2.6 Sebha (Tasbeh)
- Header wordmark, then the underlined gold title `سَبِّحِ اسْمَ رَبِّكَ الأَعْلَى` (24).
- A **ring of ~33 gold beads** with a small handle/pointer at the top of the ring.
- Ring centre: the current zekr (`سبحان الله`, white/gold, 20) and the counter (`30`, 24) below it.
- **Behaviour (Figma review comment #8 — it was ambiguous in the design, so define it explicitly):**
  tap anywhere → the ring rotates one bead step + counter increments. At **33** the counter resets and
  the zekr advances: `سبحان الله` → `الحمد لله` → `لا إله إلا الله` → `الله أكبر` → repeat.

---

### 2.7 Radio tab
- Header wordmark.
- **Segmented tabs** `Radio` | `Reciters`: pill shape; active = gold fill + dark text; inactive =
  transparent + cream text. **Both states use Janna**, same size — only colour changes (comment #6).
- List of gold tiles (radius 18, padding 16/14):
  - centered station/reciter name (dark, 16 bold)
  - row: play/pause circular icon (dark) · animated waveform (dark bars, only animating while playing) · volume icon.
- The playing tile shows the pause icon; the waveform of the playing tile is animated.

---

### 2.8 Time tab
- Header wordmark.
- **Prayer card** — gold, with a scalloped/wavy top edge (already implemented via `_ScallopClipper`):
  - left: gregorian date (`16 Jul, 2024`), centre: `Pray Time` + weekday (`Tuesday`), right: hijri date (`09 Muh, 1446`).
  - horizontal carousel of prayer chips (dark, rounded): prayer name + time; the **next prayer chip is
    enlarged and popped out** of the row.
  - bottom row: `Next Pray - 02:32` (dark) + mute/speaker icon on the right.
- **`Azkar`** section title (cream, 20 bold), then two cards side by side, radius ~16, 1px gold border:
  `azkar_evening.png` + label `Evening Azkar`, `azkar_morning.png` + label `Morning Azkar` → push the Azkar screen.

---

### 2.9 Bottom navigation (shared)
- Bar: gold `#E2BE7F`, 5 items, fixed type, no shadow.
- Unselected: dark SVG icon only (no label).
- Selected: dark pill (`#202020`, radius ~40, horizontal padding ~20, vertical ~6) with the icon tinted
  white inside, and the label under it (dark, 14 bold).
- Order: Quran · Hadith · Sebha · Radio · Time.

---

## 3. Figma reviewer comments — all of them
| # | Comment | Action |
|---|---|---|
| 9 | "verse numbers should appear **after the ayah**, not before. This matches the standard Quran reading pattern" | Keep number after the ayah text |
| 8 | "The design looks good, but the counter behavior is not clear (is it limited or unlimited?)" | Define it: 33 per zekr, then advance zekr (see 2.6) |
| 7 | "it's should to be **Azkar**" | Intro page 4 title = `Azkar`, not `Bearish` |
| 6 | "Arial appears to be used only for the unselected Radio Tab state, I think it's wrong" | Janna everywhere, incl. unselected radio tab |
| 5 | "*Islami" | Intro page 1: `Welcome To Islami App` (not `Islmi`) |

## 4. Assets
Everything needed already exists under `assets/` except the **5 intro illustrations**, which must be
exported from Figma (Select frame → Export → PNG 2x/4x) into `assets/images/` as:
`intro_1_calligraphy.png`, `intro_2_mosque.png`, `intro_3_quran.png`, `intro_4_tasbeh.png`,
`intro_5_radio.png` — then run `dart run build_runner build` to regenerate `assets.gen.dart`.
