# islami — Architecture

The app is organized using **Clean Architecture** with **BLoC/Cubit** for state
management and **GetIt** for dependency injection.

## Layers

Each feature under `lib/features/<feature>/` is split into three layers:

```
features/<feature>/
├── data/                 # implementation details
│   ├── datasources/      # local/remote sources (assets, files, APIs)
│   ├── models/           # DTOs extending domain entities
│   ├── repositories/     # repository implementations (map exceptions → failures)
│   └── services/         # platform implementations of domain service contracts
├── domain/               # pure business logic, no Flutter imports
│   ├── entities/         # core objects (Equatable)
│   ├── repositories/     # abstract repository contracts
│   ├── services/         # abstract policies/strategies (e.g. AdhanScheduler)
│   └── usecases/         # single-responsibility actions (UseCase<Type, Params>)
└── presentation/         # UI
    ├── bloc/ | cubit/    # state management
    ├── pages/            # screens
    └── widgets/          # reusable widgets
```

Dependency rule: `presentation → domain ← data`. The domain layer depends on
nothing; data and presentation depend on domain. No presentation file imports a
data source or a model, and plugin types (`Position`, `PlayerState`, …) never
leave the service that wraps them.

## Core (`lib/core/`)

- `cache/` — `CacheManager` (namespaced, timestamped entries with an optional
  TTL, plus `readList`/`writeList`), `JsonStore` (plain JSON under the key it
  is given, for state the app owns) and `CacheResult` (data + where it came
  from).
- `data/guard.dart` — `guardLocalData`, the try/catch that turns a
  `LocalDataException` into a `LocalDataFailure`.
- `di/service_locator.dart` — GetIt registrations (`sl`) and `init()`.
- `error/` — `Failure` types (returned in `Either`) and `Exception` types
  (thrown by data sources).
- `gen/` — generated asset and font references (flutter_gen).
- `network/api_client.dart` — the one JSON GET client (`ApiClient`, backed by
  dio): status check, decode, `ServerException`, timeout.
- `presentation/` — shared presentation pieces: `ViewStatus` (the load status
  every screen uses), `PlaybackController` + `PlaybackStatus`, `UiNotice`
  (one-shot messages) and `ConnectivityCubit`.
- `routes/`, `theme/` — routing and the single dark theme (`AppColors`,
  `ThemeManager`).
- `services/` — platform wrappers behind abstractions: audio player, compass,
  connectivity, magnetic declination, downloads, location, notifications.
- `usecase/` — base `UseCase` contract, `NoParams`, `RefreshParams`.
- `utils/` — `ArabicSearch` (diacritic/hamza-insensitive matching), display
  `formatters`, `QiblaCalculator`.
- `widgets/` — `AppBackground`, `HeaderLogo`, `LoadingView`, `ErrorView`,
  `EmptyMessage`, `NoticeListener`, `OfflineBanner`/`OfflineBannerFor`,
  `PlayPauseButton`, `SuraAudioTile`, `SearchField`.

## Error handling

Data sources throw `*Exception`; repositories catch them and return
`Either<Failure, T>` (dartz). Use cases and BLoCs `fold` the result into
success/failure states, which the screens render with `LoadingView`,
`ErrorView` or the data itself.

## Dependency injection

`main()` calls `await di.init()` before `runApp`. BLoCs are registered as
**factories** (new instance per screen via `sl<XBloc>()`), while use cases,
repositories, data sources and services are **lazy singletons**.

Feature BLoCs are provided at the page level with `BlocProvider(create: (_) => sl<XBloc>())`.
Two are provided above the `MaterialApp` because the whole app shares them:
`DownloadsBloc` (one queue, one index) and `ConnectivityCubit` (one answer to
"are we online?"). Lightweight UI-only state (Home tab index, Tasbeh counter)
uses `Cubit`s instantiated directly.

## Offline behaviour

Azkar, hadith, the Quran text and the prayer guide ship as assets, so they need
no network at all. Radio lists are cached for 7 days and prayer times a month
at a time, both through `CacheManager`; downloaded suras play from disk. A
screen showing saved data while offline says so with `OfflineBannerFor`.

## Adhan

Which adhans sound is a persisted setting (`AdhanSettings`: a master switch and
the prayers that are on). Everything follows from saving it: `TimeBloc` watches
the settings and is the only place alarms are armed, so the settings screen and
the prayer card's volume icon simply save. The policy hands the native
scheduler exactly the prayers that are switched on, and it re-arms only what it
was last given — after a reboot, a clock change, or nothing at all when the
master switch is off.

The notification permission is asked for when the adhan is switched on, not at
launch; refusing it switches the adhan off rather than leaving a promise the
device will not keep.

## Audio

There is one player (`AudioPlayerService`), so there is one owner: every play
call carries a tag, and `PlaybackController` gives a screen its own view of it —
which of *its* items is loaded, whether it is playing, and whether closing
should stop anything. Radio, the reciter sura list and Downloads all share that
one rule.

## Features

| Feature | State | Data |
|---------|-------|------|
| splash  | `SplashCubit` (delay → first screen) | `OnboardingRepository` |
| intro   | `IntroCubit` (page, finish) | `OnboardingRepository` |
| onboarding | — (domain + data only) | "seen the intro" flag in SharedPreferences |
| home    | `HomeCubit` (tab index, IndexedStack) | — |
| quran   | `QuranBloc` (list + search), `QuranDetailsBloc` (verses) | 114 suras from `SuraNames` + ayah `.txt` assets; recents in SharedPreferences |
| hadith  | `HadithBloc` | 50 hadiths in `assets/files/hadeeth` |
| azkar   | `AzkarBloc` | morning/evening JSON assets |
| tasbeh  | `TasbehCubit` (counter + dhikr) | — |
| radio   | `RadioBloc` (stations, reciters, search, playback), `SuraPlaybackCubit` | mp3quran.net API, cached |
| downloads | `DownloadsBloc` (queue + index), `DownloadsPlaybackCubit` | files on disk (`DownloadService`) + an index in SharedPreferences |
| time    | `TimeBloc` (schedule, countdown, adhan alarms), `AdhanSettingsCubit` (which adhans) | Aladhan API, a month cached; alarms armed natively; adhan settings in SharedPreferences |
| qibla   | `QiblaCubit` (location + compass) | last location cached for offline use |
| prayer_guide | `PrayerGuideCubit` | `assets/files/prayer_guide/prayer_guide.json` — present but not yet wired into the app |

## Setup

```bash
flutter pub get
dart run build_runner build --delete-conflicting-outputs   # regenerates core/gen
```

## Release

The application id is `com.thecofounderstudio.islami` (the Kotlin package
matches; the MethodChannel names, `islami/adhan` and `islami/geomagnetic`, are
internal and unchanged).

A release build needs `android/key.properties` and fails without it rather
than falling back to the debug key. `docs/release/` holds the signing
instructions, the permission list with reasons, and the Play paperwork drafts
(privacy policy, data safety, foreground service, exact alarms, store
listing).
