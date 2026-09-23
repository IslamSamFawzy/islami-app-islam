# Prompt for Claude Code — Radio search · sura names · play from Downloads

> Paste everything below the line into Claude Code. Four phases, in order.
> `flutter analyze` clean + one commit per phase.

---

## Context

**Islami** — Flutter, `flutter_bloc` + `get_it`, clean architecture
(`lib/features/<feature>/{data,domain,presentation}`, shared code in `lib/core`).

Three related changes:
1. **Search** in the Radio tab (both tabs) and in a reciter's sura list.
2. **Real sura names** (Arabic + English) instead of `Sura N`, resolved from the sura number.
3. **Play a downloaded sura directly from the Downloads screen.**

Do phases in order — Phase 1 unblocks 2 and 3.

## Ground rules

- No hardcoded colours/fonts — `AppColors` + `Theme.of(context).textTheme`, Janna everywhere.
- Don't touch the Time tab, the prayer card, the Qibla feature, or the caching layer.
- `flutter analyze` clean; the existing 47 tests must still pass.
- One commit per phase.
- If anything below contradicts what you find in the code, **say so and stop** — don't silently
  improvise a different design.

---

## Phase 1 — Promote the sura name list to `core`

**The problem.** The canonical list of 114 suras (`id` / `nameEn` / `nameAr` / `ayaCount`) is currently
a **private** `static const List<SuraModel> _suras` inside
`lib/features/quran/data/datasources/quran_local_data_source.dart`. Downloads and Radio need it too,
which is exactly why you previously rendered `Sura N` instead of a name.

**The fix.** Move the data to a shared, feature-agnostic home — do **not** make Downloads or Radio
depend on the Quran feature.

- New `lib/core/constants/sura_names.dart` — a plain Dart constant list of records/simple objects
  (`number`, `nameEn`, `nameAr`, `ayaCount`), plus a lookup helper:
  - `SuraNames.byNumber(int n)` → the entry, or `null` for out-of-range (guard `n < 1 || n > 114`).
  - Keep it a `const` list + a lazily-built `Map<int, …>` index so lookups are O(1), not a linear scan
    on every list row (the reciter screen renders 114 rows).
  - **No Flutter imports** — pure Dart, so it stays testable and usable anywhere.
- `QuranLocalDataSourceImpl` now builds its `SuraModel`s from `SuraNames` instead of holding its own
  copy. **The Quran tab must behave exactly as before** — same names, same order, same `ayaCount`.
  Its `Sura` entity keeps `id` as a `String`; convert at the boundary, don't churn the Quran feature.
- **Copy the data verbatim.** Do not retype or "fix" any Arabic name. After the move, assert the list
  is exactly 114 entries and diff the old vs new values so nothing silently changed.

**Tests:** `SuraNames.byNumber(1)` → Al-Fatiha / الفاتحه; `(2)` → Al-Baqarah / البقرة; `(114)` → An-Nas;
`(0)`, `(115)`, `(-1)` → null. Plus a test asserting `length == 114`.

## Phase 2 — Show real sura names

Replace every `Sura N` label with the real name, in the Quran tab's style (English name + Arabic name):

- `lib/features/radio/presentation/pages/reciter_suras_view.dart` — each row shows the number, the
  English name, and the Arabic name (RTL, on the right, like the Quran tab's sura rows).
- `lib/features/downloads/presentation/pages/downloads_view.dart` — same treatment for each entry.
- If a number somehow has no match, fall back to `Sura N` rather than crashing or showing blank.
- Keep the existing row controls (download button / progress / delete) exactly as they are.

## Phase 3 — Search

Reuse the **existing** search field styling — `lib/features/quran/presentation/widgets/sura_search_field.dart`
(dark fill @70%, 1px gold border, radius 12, gold prefix icon, cream hint). If it's cleanly reusable,
**extract it to a shared widget** rather than copy-pasting it three times; if extracting would drag
`QuranBloc` along with it, generalise it to take an `onChanged` + `hintText` instead.

**3a — Radio tab** (`radio_view.dart`), search field under the header, above the segmented tabs:
- Filters the **currently active tab's** list: stations when on `Radio`, reciters when on `Reciters`.
- Hint text reflects the active tab (`Search stations` / `Search reciters`).
- Filtering lives in `RadioBloc` (a `query` in state, like `QuranBloc` does) — not in the widget.
- Switching tabs **clears the query** so the user isn't confused by a stale filter.

**3b — Reciter sura list** (`reciter_suras_view.dart`), search field under the AppBar:
- Matches on **sura number, English name, or Arabic name** — typing `2`, `baqara`, or `بقرة` all find
  Al-Baqarah.

**Matching rules — apply to both:**
- Case-insensitive, and **diacritic/hamza-insensitive for Arabic**. Typing `بقره` must match `البقرة`,
  and `الاعراف` must match `الأعراف`. Normalise both sides before comparing: strip tashkeel, unify
  `أ إ آ` → `ا`, `ة` → `ه`, `ى` → `ي`, and strip the leading `ال`.
  Put this normaliser in `lib/core/utils/` as a **pure function with its own tests** — this is the part
  most likely to be quietly wrong.
- Substring match is fine; no fuzzy matching needed.
- **Empty results** → a short cream "No results" line, not a blank screen.

## Phase 4 — Play from the Downloads screen

**The constraint.** `SuraPlaybackCubit` is scoped to a **single reciter** (it takes `reciter` in its
constructor and builds stream URLs from it), and its `close()` calls `audioPlayerService.stop()`.
The Downloads screen lists suras from **multiple** reciters, and every entry is already a local file —
no streaming, no reciter needed.

So **do not** try to bend `SuraPlaybackCubit` to fit. Add a separate, simpler
`DownloadsPlaybackCubit` that plays a `DownloadEntry` by its `path`:
- `toggle(DownloadEntry)` — tapping the playing entry pauses/resumes; tapping another switches to it.
- Before playing, confirm the file still exists (`File(entry.path).exists()`); if it's gone, show a
  notice and tell `DownloadsBloc` to drop the stale index entry (it already reconciles on startup —
  reuse that path, don't duplicate the logic).
- Subscribe to `audioPlayerService.onStateChanged` for the playing flag, same pattern as
  `SuraPlaybackCubit`.
- Since `AudioPlayerService` is an app-wide singleton, playback from Downloads and from the reciter
  screen must not fight each other — starting one stops the other (that's already how `playFile`/
  `playUrl` behave; just don't break it).

**UI:** each downloads row gets a gold play/pause circular icon on the left, matching `StationTile`'s
control. The currently playing row is visually distinct (as the reciter screen already does it).

**Deleting the entry that's currently playing must stop playback first** — don't leave the player
holding a deleted file.

---

## Verify & report

1. `flutter analyze` clean; `flutter test` green (existing 47 + new tests for `SuraNames`, the Arabic
   normaliser, and the downloads playback cubit).
2. On the device:
   - Radio tab → search filters stations; switch to Reciters → query clears, search filters reciters.
   - Open a reciter → search `2`, `baqara`, `بقرة`, `بقره` → all find Al-Baqarah.
   - Sura rows show real Arabic + English names, RTL rendering correct, no clipping.
   - Downloads → play a sura directly; pause/resume; play a different one; delete the playing one.
   - **Airplane mode:** downloads still play (they're local files).
3. Report: what you changed per phase, anything you had to guess, and any Arabic name that differs
   between the old list and the new one (there should be none).
