# Prompt for Claude Code — Islami app: match the Figma design, screen by screen

> Paste everything below the line into Claude Code, from the project root (`~/StudioProjects/islami`).
> Work through it **one phase at a time** — don't paste all phases at once if you want tight control;
> Phase 0 → Phase 6 in order works best.

---

## Context

You are working on **Islami**, a Flutter app (Dart 3.10, `flutter_bloc` + `get_it` + clean architecture:
`lib/features/<feature>/{data,domain,presentation}`, shared code in `lib/core`).

The design is here: **https://www.figma.com/design/rYIdiZRmbIhvvoGbLPQ9Al/Islami?node-id=9-19**
(page **UI**, frames are 430×932, single **dark** theme).

The full written spec — tokens, per-screen layout, states, and the reviewer comments from the Figma
file — is in **`design/DESIGN_SPEC.md`**. Read it first, in full, before touching any code.

If you have the Figma MCP available and the file opens with `get_design_context` / `get_metadata`, use
it to pull exact values per frame. If it returns "you don't have edit access", fall back to
`design/DESIGN_SPEC.md` — the spec is complete enough to build from.

Goal: **every screen in the app should look like its Figma frame.** Not "inspired by" — the same
layout, the same spacing, the same states.

## Ground rules

1. **Do not rewrite the architecture.** Keep the existing bloc/cubit, use cases, repositories and DI.
   This is a UI/design pass; only touch `presentation/` (+ `core/theme`, `core/routes`, `pubspec.yaml`,
   `assets/`) unless a screen genuinely needs new state.
2. **No hardcoded colours or font families in widgets.** Use `AppColors` and `Theme.of(context).textTheme`.
   If a shade is missing, add it to `AppColors` — don't inline a hex.
3. **Janna everywhere** — Arabic and English, all weights. No Arial, no default system font. If any widget
   is falling back to the system font, fix it at the theme level (`ThemeData.fontFamily = 'Janna'`).
4. `ThemeManager.lightTheme()` is misnamed — it *is* the dark theme. Rename it to `darkTheme()` (or
   `appTheme()`), keep `MaterialApp` on that single theme, and make sure every text style in the
   `TextTheme` is actually used by the screens instead of ad-hoc `TextStyle`s.
5. After each phase: run `flutter analyze` and fix everything it reports. Zero warnings when you're done.
6. Small, reviewable commits — one per phase, message like `feat(intro): add 5-page onboarding`.
7. If the design and the existing code disagree, **the design wins** — except where `DESIGN_SPEC.md`
   §3 says the design itself is wrong (the reviewer comments); there, follow the spec.

---

## Phase 0 — Foundation

- Read `design/DESIGN_SPEC.md`, then `lib/core/theme/`, `lib/core/routes/app_routes.dart`,
  `lib/features/home/presentation/pages/home_layout.dart`, and every `presentation/pages/*.dart`.
- Report back a short gap list: for each screen, what differs from the spec. Then start fixing.
- Set `fontFamily: 'Janna'` on `ThemeData` so nothing can fall back to Arial (spec §3, comment #6).
- Make sure the whole `TextTheme` matches the type scale in the spec (24 / 20 / 16 / 14, all w700).

## Phase 1 — Bottom navigation (shared, affects 5 screens)

Match spec §2.9 exactly: gold bar, dark icons when unselected (no label), and for the selected item a
dark `#202020` pill (radius ~40, padding 20×6) with the icon tinted white and the label underneath in
dark 14 bold. The current `Colors.black45` pill is wrong — it must be the real background colour.

## Phase 2 — Intro / Onboarding (new feature — the biggest gap)

Nothing in the codebase implements this; the design has 5 pages.

- Export the 5 illustrations from Figma (Export → PNG 2x) into `assets/images/` as
  `intro_1_calligraphy.png`, `intro_2_mosque.png`, `intro_3_quran.png`, `intro_4_tasbeh.png`,
  `intro_5_radio.png`, then `dart run build_runner build --delete-conflicting-outputs`.
  If the files aren't there yet, build the screens against `Assets.images.*` names anyway and tell me
  which assets are missing.
- New feature folder `lib/features/intro/presentation/` with an `IntroView` + a small `IntroCubit`
  (current page index) — follow the same style as `SplashCubit`.
- Layout, copy and dot indicator: spec §2.2. `Back` hidden on page 1, `Finish` on page 5.
- Apply the two copy fixes from the Figma review: **"Welcome To Islami App"** (not "Islmi") and
  page 4 titled **"Azkar"** (not "Bearish").
- `Finish` → persist `onboarding_seen = true` via `SharedPreferences` (there's already a
  `shared_preferences` dependency and a DI setup — reuse them) → `pushNamedAndRemoveUntil(HomeLayout)`.
- `SplashView` reads the flag: first launch → `IntroView`, otherwise → `HomeLayout`.
- Register `IntroView.routeName` in `AppRoutes`.

## Phase 3 — Quran tab + Sura Details

- Quran tab (spec §2.3): search field, `Most Recently` cards, `Suras List` rows with the star badge,
  EN name + verses count, AR name on the right, gold divider. Searching hides `Most Recently`.
- Sura Details (spec §2.4): rebuild the verse list as **bordered ayah cards** (1px gold border, radius 8,
  transparent fill, RTL centered gold text) with the **verse number after the ayah text**, and the
  currently selected/playing ayah **filled solid gold with dark text**. Keep the corner ornaments and the
  bottom mosque silhouette.

## Phase 4 — Hadith + Sebha

- Hadith (spec §2.5): carousel with visible peeking side cards (`viewportFraction ≈ 0.8`,
  `enlargeCenterPage: true`), parchment card with ornaments, title, and a body that scrolls **inside** the
  card. Tapping a card opens a Hadith Details page (dark, AppBar back + `Hadith N`).
- Sebha (spec §2.6): bead ring + centre counter. Implement the counter behaviour explicitly:
  tap → rotate one bead + increment; at 33 → reset and advance the zekr
  (`سبحان الله` → `الحمد لله` → `لا إله إلا الله` → `الله أكبر` → repeat). This resolves Figma comment #8.

## Phase 5 — Radio + Time

- Radio (spec §2.7): segmented `Radio` / `Reciters` pill tabs — **both states in Janna**, only the colour
  changes. Gold tiles with centered title, play/pause, animated waveform (animating only while playing),
  volume icon.
- Time (spec §2.8): the scalloped prayer card with gregorian date / `Pray Time` + weekday / hijri date,
  the prayer chip carousel with the next prayer popped out, the `Next Pray - HH:MM` row with the mute
  icon, then the two `Evening Azkar` / `Morning Azkar` cards.

## Phase 6 — Verify

- `flutter analyze` → clean.
- Run the app (or `flutter run -d <device>`), open **every** screen, screenshot each one, and put the
  screenshots side by side with the Figma frames. For each screen give me a short verdict:
  matches / differs (and how). Fix anything that differs.
- Check RTL Arabic rendering everywhere (verses, hadith, azkar, sebha) — no clipped or reversed text.
- Confirm no `TextStyle` in the app is missing `fontFamily: 'Janna'`.

---

## What to give me at the end

1. The gap list from Phase 0 vs. what you actually changed.
2. Any place where you had to guess because the spec was ambiguous — list it, don't silently invent.
3. The list of assets you still need exported from Figma.
