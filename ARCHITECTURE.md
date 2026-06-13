# islami — Architecture

The app is organized using **Clean Architecture** with **BLoC/Cubit** for state
management and **GetIt** for dependency injection.

## Layers

Each feature under `lib/features/<feature>/` is split into three layers:

```
features/<feature>/
├── data/                 # implementation details
│   ├── datasources/      # local/remote sources (assets, files, APIs)
│   ├── models/           # DTOs extending domain entities (fromJson/toJson)
│   └── repositories/     # repository implementations (map exceptions → failures)
├── domain/               # pure business logic, no Flutter imports
│   ├── entities/         # core objects (Equatable)
│   ├── repositories/     # abstract repository contracts
│   └── usecases/         # single-responsibility actions (UseCase<Type, Params>)
└── presentation/         # UI
    ├── bloc/ | cubit/    # state management
    ├── pages/            # screens
    └── widgets/          # reusable widgets
```

Dependency rule: `presentation → domain ← data`. The domain layer depends on
nothing; data and presentation depend on domain.

## Core (`lib/core/`)

- `di/service_locator.dart` — GetIt registrations (`sl`) and `init()`.
- `error/` — `Failure` types (returned in `Either`) and `Exception` types
  (thrown by data sources).
- `usecase/usecase.dart` — base `UseCase` contract and `NoParams`.
- `routes/`, `theme/`, `gen/` — routing, theming, generated assets.

## Error handling

Data sources throw `*Exception`; repositories catch them and return
`Either<Failure, T>` (dartz). Use cases and BLoCs `fold` the result into
success/failure states.

## Dependency injection

`main()` calls `await di.init()` before `runApp`. BLoCs are registered as
**factories** (new instance per screen via `sl<XBloc>()`), while use cases,
repositories, and data sources are **lazy singletons**.

Feature BLoCs are provided at the page level with `BlocProvider(create: (_) => sl<XBloc>())`.
Lightweight UI-only state (Home tab index, Tasbeh counter, Splash timer) uses
`Cubit`s instantiated directly (no dependencies, so not in GetIt).

## Features

| Feature | State | Data |
|---------|-------|------|
| splash  | `SplashCubit` (timer → navigate) | — |
| home    | `HomeCubit` (tab index, IndexedStack) | — |
| quran   | `QuranBloc` (list + search), `QuranDetailsBloc` (verses) | 114 suras (static) + ayah `.txt` assets |
| hadith  | `HadithBloc` | static hadith list |
| tasbeh  | `TasbehCubit` (counter + dhikr) | — |
| radio   | UI only (placeholder) | — |
| time    | UI only (placeholder) | — |

## Setup

After pulling these changes, fetch the new packages:

```bash
flutter pub get
```

New dependencies: `flutter_bloc`, `bloc`, `get_it`, `equatable`, `dartz`.
