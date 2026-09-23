# Islami — Claude Code task list

Work through this file **one phase per session**. Start each session with:

> Read `docs/claude-code-tasks.md`. Do **Phase N** only. Follow the ground rules.

When a phase is done, paste the "Report back" block from the end of this file
(filled in) into the planning chat.

---

## Ground rules (apply to every phase)

- The project follows Clean Architecture (`data → domain ← presentation`),
  SOLID, BLoC/Cubit and GetIt — see `ARCHITECTURE.md`. Keep to it:
  - `domain/` imports no Flutter, no plugins, no `data/`, and no other
    feature's `data/`.
  - Presentation talks to use cases or domain-level abstractions, never to a
    data source or a model.
  - Plugin types (`Position`, `PlayerState`, …) never leave the service that
    wraps them.
- Behaviour must not change unless the phase says so. This is a refactor
  first; the UI must look identical.
- Do not modify `lib/features/prayer_guide/` before Phase 7 (it was built
  separately and is integrated in Phase 7).
- After each logical step: `flutter analyze` must report **no issues** and
  `flutter test` must pass. Add or update tests for anything you move or add.
- One commit per numbered item (or per small group of related items), with a
  clear message. Never commit `build/`, `.dart_tool/` or local IDE files.
- Before the first commit, check `git status`: about 200 files outside `lib/`
  (assets, android) show as modified, probably from line endings. Find out
  why (e.g. `git diff --ignore-all-space --stat`, `core.autocrlf`). Fix it
  with a `.gitattributes` if it is only line endings. Stop and report if the
  contents really changed. A stale empty file
  `.git/index.lock.stale-from-claude` can be deleted.

---

## Phase 1 — Shared building blocks in `core/`

1. **One view status.** Add `core/presentation/view_status.dart` with
   `enum ViewStatus { initial, loading, success, failure }` (plus
   `isLoading` helpers if useful). Replace `AzkarStatus`, `HadithStatus`,
   `DetailsStatus`, `QuranStatus`, `RadioStatus`, `TimeStatus`.
2. **Shared state widgets.** Add `core/widgets/loading_view.dart`,
   `error_view.dart` (message + optional retry), `empty_message.dart`. Replace
   the 7 copies of the gold `CircularProgressIndicator`, the centred error
   texts, `RadioEmptyHint`, `RadioNoResults` and `_NoResults`. Qibla's
   `_MessageState` becomes `ErrorView` with an icon + retry.
3. **Local data guard.** Add a helper (e.g. `core/data/guard.dart`) so
   repositories stop repeating
   `try { … } on LocalDataException catch (e) { return Left(LocalDataFailure(e.message)); }`
   (6 copies in azkar, hadith, quran).
4. **One HTTP client.** Add `core/network/api_client.dart` (abstract +
   impl) that does GET → status check → JSON decode → `ServerException`,
   with a timeout. Use it in `RadioRemoteDataSourceImpl` and
   `PrayerRemoteDataSourceImpl`. The app currently depends on both `http`
   and `dio`. Keep only `dio` (the downloads already use it), so remove
   `http` from `pubspec.yaml` and DI.
5. **Cache list helper.** Add `CacheManager.readList<T>(key, fromJson, {Duration? ttl})`
   and `writeList`. Use them in `RadioLocalDataSourceImpl` and
   `PrayerLocalDataSourceImpl`. `DownloadsLocalDataSourceImpl` hand-rolls
   JSON in SharedPreferences, so move it onto a `CacheManager`-style
   helper too (keep its existing storage key so users don't lose their
   download index).
6. **Formatters.** Move `formatBytes` (downloads_view), `_thousands`
   (qibla_view), `_toArabicNumber` (quran_details_view) and
   `_formatCountdown` (prayer_times_card) into `core/utils/formatters.dart`
   with unit tests.
7. **Screen chrome.** Add `core/widgets/app_background.dart` (background
   image + optional transparent AppBar with the gold title) and
   `core/widgets/header_logo.dart` (the `imgHeader` logo with a width
   factor). Use them on the 6 screens that repeat the background +
   AppBar pattern (Azkar, Downloads, Qibla, ReciterSuras, Radio, Time) and
   the 5 that repeat the header logo.
8. **Colours.** Move the hard-coded card gradient
   (`0xff262019 → 0xff0A0806`, used by the Azkar and Qibla cards) and the
   prayer-pill gradient colours into `AppColors`. In `ThemeManager`, drop the
   `fontFamily: "Janna"` repeated on every `TextStyle` (it is already set on
   the theme). The Azkar card images use string paths. Switch them to
   `Assets.images.azkarEvening` / `azkarMorning`.

## Phase 2 — Downloads domain + one playback model

1. **Downloads gets a domain layer.** Add `DownloadEntry` (exists),
   `DownloadsRepository` (domain) + `DownloadsRepositoryImpl` (data, wraps
   `DownloadsLocalDataSource` + `DownloadService`) and use cases
   (`GetDownloads`, `ReconcileDownloads`, `SaveDownload`, `DeleteDownload`,
   `DeleteReciterDownloads`, `FindDownloadedFile`). `DownloadsBloc` and
   `SuraPlaybackCubit` use those. No presentation file imports a data
   source or a model. In particular, `SuraPlaybackCubit` (radio) must stop
   importing `downloads/data/…`.
2. **One download key.** Add a small value object (e.g. `DownloadKey`
   with `reciterId`, `suraId`, `toString() => '$reciterId/$suraId'`, `parse`)
   and use it everywhere the key is built or split today:
   `DownloadEntry.key`, `DownloadsState.keyOf`, the data source,
   `DownloadsBloc._beginDownload` (which splits the string), and
   `DownloadsPlaybackCubit.stopIfReciter`.
3. **Audio abstraction without plugin types.** `AudioPlayerService` exposes
   `Stream<bool> isPlayingStream` / `bool isPlaying` instead of
   audioplayers' `PlayerState`, plus `togglePause()`. The
   `"same item → pause/resume"` logic and the player subscription are
   repeated in `RadioBloc`, `SuraPlaybackCubit` and
   `DownloadsPlaybackCubit`. Extract them into one reusable piece, e.g. a
   `PlaybackController` in `core/` or a mixin that owns `currentId`,
   `isPlaying` and `toggle(id, start)`. `RadioBloc.close()` currently stops
   audio unconditionally, while the downloads cubit only stops audio it owns.
   Make all three consistent (stop only what you own).
4. **One-shot notices.** `notice` + `noticeSeq` + the SnackBar
   `BlocListener` are repeated in 3 states and 3 screens. Add a small
   `UiNotice` value (message + id) and a `NoticeListener<B, S>` widget in
   `core/widgets`.
5. **Sura audio row.** `_SuraTile` (downloads_view) and `_SuraRow`
   (reciter_suras_view) are the same row. Extract a shared `SuraAudioTile`
   (play/pause, number + English name, Arabic name, trailing slot) and a
   `PlayPauseButton`, also used by `StationTile`.
6. **LocationService without geolocator types.** Return a domain
   `GeoPoint {latitude, longitude, altitude}` instead of `Position`. Throw
   typed exceptions (`LocationServiceDisabledException`,
   `LocationPermissionDeniedException`) so `QiblaCubit` stops matching
   `'disabled'` inside the message text.

## Phase 3 — Feature-by-feature cleanup

1. **Quran search.** Delete `DefaultSuraSearchFilter`'s own matching. It
   must use `ArabicSearch.suraMatches` (number, English, Arabic;
   hamza/diacritic-insensitive), the same as the reciter screen. Keep the
   `SuraSearchFilter` abstraction; only the implementation changes.
2. **Quran sura entity.** `Sura.id` / `ayaCount` are `String` while
   `SuraNames` uses `int`. Make them `int` in the domain (asset file
   names still use the number).
3. **Open sura.** `SuraItem` and `MostRecentlyWidget` both do
   "mark as recent + push details". Extract one helper/callback.
4. **Time.**
   - The list `['Fajr','Dhuhr','Asr','Maghrib','Isha']` is duplicated in
     `DefaultAdhanPrayerPolicy` and `AdhanNextPrayerCalculator`, and `'Fajr'`
     is a string literal. Add a `PrayerName` enum / constants in the Time
     domain and use it in both.
   - `TimeBloc` computes "next prayer + countdown" in both `_onLoad` and
     `_onTick`, and schedules adhans in both `_syncAdhans` and
     `_onToggleMute`. Deduplicate.
   - `AdhanScheduler` and `NotificationService` are concrete classes. Give
     them abstract interfaces like the other services. Move `AdhanTime` so the
     Time **domain** no longer imports `core/services/adhan_scheduler.dart`
     (e.g. `AdhanTime` becomes a domain value, and the scheduler interface
     lives in the Time domain with the MethodChannel impl in data/core).
   - `NotificationService.init()` sets up `timezone` / `flutter_timezone`,
     but nothing schedules through the plugin (the adhan is native).
     Remove that setup and those two dependencies if they are unused.
5. **Connectivity.** `RadioBloc` and `TimeBloc` both subscribe to
   connectivity, seed `isOffline` and drive `OfflineBanner`. Add one
   app-level `ConnectivityCubit` (provided above `MaterialApp`) and an
   `OfflineBannerFor` widget. The blocs keep only their "retry on reconnect"
   reaction.
6. **Qibla.** `QiblaCubit` uses `CacheManager` directly. Move the
   last-location cache behind a small repository.
7. **Intro / Splash.** Both cubits use `SharedPreferences` directly and
   share `onboardingSeenKey` across features. Add an `OnboardingRepository`
   (domain + impl) with `hasSeenOnboarding()` / `markOnboardingSeen()`.
8. **Dead code & deps.** Remove the unused `fromJson`/`toJson` on
   `HadithModel` and `SuraModel`. Move `flutter_native_splash` to
   `dev_dependencies`. Remove `bloc` if only `flutter_bloc` APIs are used.
   Set a real `description` in `pubspec.yaml`.
9. Update `ARCHITECTURE.md` (it still says Radio/Time are placeholders)
   to describe the current features and the new `core/` pieces.

---

## Phase 4 — New: notification settings

Users can choose which adhans they get.

- **Domain** (new feature `settings/` or inside `time/`, your call, but keep
  it clean): `AdhanSettings { bool enabled; Set<PrayerName> prayers; }`
  (default: enabled, all five), `SettingsRepository` with
  `getAdhanSettings()`, `saveAdhanSettings()`, and a
  `Stream<AdhanSettings> watch()`. Use cases to match.
- **Data:** persisted in SharedPreferences (through the Phase 1 helper).
- **Scheduling:** the adhan policy only returns prayers that are enabled.
  The master switch off cancels every alarm and stops a playing adhan. Any
  change reschedules immediately. The current in-memory `muted` flag in
  `TimeState` (it resets on app restart) is replaced by this persisted
  setting. The volume icon on the prayer card toggles the master switch.
- **Native:** check the Android side (`AdhanScheduler.kt`, the service and any
  boot receiver). After a reboot or time change it must re-arm only the
  prayers that are still enabled, and it must not re-arm anything when the
  master switch is off. Adjust the channel payload if needed.
- **Permission:** stop requesting the notification permission at app start
  (`service_locator.init`). Request it when the user turns adhan on (and
  on first launch of the Time tab if enabled). If the permission is denied,
  show the switch off with a short explanation.
- **UI:** a Settings screen (`/settings`), styled like the rest of the app
  (dark background, gold). Open it from a gear icon on the Time tab header.
  Content: master "Adhan notifications" switch, then one switch per prayer
  (disabled while the master is off).
- **Tests:** repository round-trip, policy filtering, bloc reacts to setting
  changes (fake scheduler asserts schedule/cancel calls).

## Phase 5 — New: looping hadith carousel

- `HadithView`'s `CarouselSlider` gets `enableInfiniteScroll: true`, so after
  the last hadith comes the first (and swiping back from the first shows
  the last).
- Make sure the number passed to `HadithDetailsView` is the hadith's real
  index (`index`, not `realIndex`), so "Hadith 50" is still 50 after wrapping.
- Widget test: swiping past the last card shows the first card's title.

## Phase 6 — New: resume reading where you stopped

Tapping a sura in **Most Recently** opens it at the ayah where the user left
off. Opening from the main **Suras List** still starts at the top.

- **Domain:** `ReadingProgress { int suraId; int ayahIndex; DateTime updatedAt; }`,
  repository methods `getProgress(suraId)` and `saveProgress(progress)`, and
  use cases to match. Recents keep their current order.
- **Data:** SharedPreferences map `suraId → {ayahIndex, updatedAt}` (new
  key; keep `recent_sura_ids` as is).
- **Details screen:** ayah cards have different heights, so jumping by
  pixel offset is unreliable. Use `scrollable_positioned_list` (or an
  equivalent) to `jumpTo(index)` and to listen to visible items. Save the
  **first fully visible ayah**, debounced (~500 ms) while scrolling, and
  again on dispose / app pause.
- **Navigation:** pass a route argument such as
  `QuranDetailsArgs(sura, resume: true)` from Most Recently. With `resume`,
  jump to the saved ayah and briefly highlight it (reuse the existing
  selected-ayah styling).
- **Most Recently card:** show "Ayah N" under the verse count when progress
  exists.
- **Tests:** progress round-trip, bloc emits the initial index when
  resuming, saving is debounced.

## Phase 7 — Integrate the Prayer Guide ("طريقة الصلاة")

The feature is already in the repo; it was built separately:
`lib/features/prayer_guide/**`, `assets/files/prayer_guide/prayer_guide.json`,
`assets/icons/ic_prayer.svg`, `test/features/prayer_guide/**`.

1. `pubspec.yaml`: add `- assets/files/prayer_guide/` under `assets`. Run
   `dart run build_runner build --delete-conflicting-outputs` so
   `Assets.icons.icPrayer` is generated.
2. DI (`service_locator.dart`):
   ```dart
   sl.registerFactory(() => PrayerGuideCubit(getPrayerGuide: sl()));
   sl.registerLazySingleton(() => GetPrayerGuide(sl()));
   sl.registerLazySingleton<PrayerGuideRepository>(
     () => PrayerGuideRepositoryImpl(localDataSource: sl()),
   );
   sl.registerLazySingleton<PrayerGuideLocalDataSource>(
     () => PrayerGuideLocalDataSourceImpl(),
   );
   ```
3. Bottom navigation: add a 6th tab `PrayerGuideView()` with
   `Assets.icons.icPrayer` and the label `'Salah'`, placed after `Time`.
   The screens live in an `IndexedStack`, so wrap each child in
   `TickerMode(enabled: index == selectedIndex, child: …)`. Otherwise the
   prayer animation (and the radio waveform) keep ticking in hidden tabs.
   Check that 6 items fit on a 360 dp wide screen.
4. Switch the feature to the Phase 1 building blocks:
   `PrayerGuideStatus` → `ViewStatus`, the loading/error UI →
   `LoadingView`/`ErrorView`, background/header → `AppBackground`/`HeaderLogo`.
   Don't change the figure/animation code or the JSON content.
5. `flutter analyze` + `flutter test` (the feature ships with model,
   skeleton, cubit and widget tests). Run it on a device. The overview page
   loops a full rak'ah, and each step page loops its own postures.

## Final check before release prep

- `flutter analyze`: no issues. `flutter test`: all green.
- `flutter build apk --release` builds.
- Update `ARCHITECTURE.md` (features table, core pieces, settings).

---

## Report back (paste this into the planning chat after each phase)

```
Phase: N
Commits: <hash – message> (one per line)
What changed: <short list>
Deviations from the plan and why: <…>
Open questions / anything that needs a decision: <…>
flutter analyze: <result>   flutter test: <passed/failed counts>
```
