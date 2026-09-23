# Prompt for Claude Code — Add a Qibla compass to the Time tab

> Paste everything below the line into Claude Code.

---

## Context

**Islami** — Flutter, `flutter_bloc` + `get_it`, clean architecture
(`lib/features/<feature>/{data,domain,presentation}`, shared code in `lib/core`).

New feature: **Qibla direction**. It is **not in the Figma** — there is no reference frame, so the
design is specified below. Match the app's existing visual language exactly (gold `#E2BE7F` on
`#202020`, Janna font, `AppColors` only).

**What already exists and must be reused:**
- `LocationService` (`lib/core/services/location_service.dart`) — geolocator wrapper with
  service/permission checks, throws `LocationException`. **Reuse it, don't add another location package.**
- `geolocator` is already a dependency; `ACCESS_FINE_LOCATION` / `ACCESS_COARSE_LOCATION` are already
  in `AndroidManifest.xml`.
- `AppColors`, the Janna theme, `CacheManager`, and the existing `Failure`/`Exception` types.

**New dependency: `flutter_compass: ^0.8.1`** (MIT, no transitive deps).
Do **not** use `smooth_compass_plus` — it pulls in the `location` package, which conflicts with the
`geolocator` already in this project.

> Heads-up: `flutter_compass` was last published Nov 2024. If it breaks the Android build on this
> project's toolchain (namespace/AGP issues are the usual failure), **stop and tell me** before
> swapping in an alternative — don't silently switch to a different sensor package.

## Architecture — keep it proportionate

Qibla has **no data source**: it's a sensor stream plus a pure function. Do **not** invent a
repository/data-source/usecase stack for it. Follow the precedent already in this codebase —
`TasbehCubit` and `SplashCubit` are plain cubits with no data layer.

- `lib/core/services/compass_service.dart` — thin wrapper over `FlutterCompass.events`, exposing a
  `Stream<CompassReading>` (heading + accuracy). Mirrors how `LocationService` is written. Register in `service_locator.dart`.
- `lib/core/utils/qibla_calculator.dart` — a **pure, testable function**. No Flutter imports.
- `lib/features/qibla/presentation/` — `QiblaCubit` + `QiblaState` + `QiblaView`.

## The maths — get this right, it's the whole feature

Kaaba coordinates: **21.4225° N, 39.8262° E**.

Great-circle **initial bearing** from the user to the Kaaba:

```
φ1 = user latitude (radians)
φ2 = Kaaba latitude (radians)
Δλ = Kaaba longitude − user longitude (radians)

θ = atan2( sin(Δλ) · cos(φ2),
           cos(φ1)·sin(φ2) − sin(φ1)·cos(φ2)·cos(Δλ) )

bearing = (θ in degrees + 360) % 360
```

This bearing is relative to **true north**.

**The needle rotation** on screen is `qiblaBearing − deviceHeading`, normalised to 0–360, converted to
turns for `AnimatedRotation` (`degrees / 360`).

### ⚠️ Magnetic vs true north — do not ignore this

`flutter_compass` reports heading relative to **magnetic north** on Android, while the bearing computed
above is relative to **true north**. The gap between them (magnetic declination) is location-dependent
and can be **10°+** in some regions — a real error for a prayer-direction feature.

Handle it explicitly, and **tell me which route you took**:
- If `flutter_compass` exposes a true-heading value on the platform, prefer it; or
- apply a declination correction; or
- if you decide the error is acceptable and skip the correction, **say so plainly in your report** and
  add a code comment — do not leave it silently wrong.

### Unit tests (required)
`qibla_calculator.dart` is pure — test it:
- Cairo (30.0444, 31.2357) → ~**136°**
- Jakarta (−6.2, 106.8) → ~**295°**
- Riyadh (24.7136, 46.6753) → ~**245°**
- Edge cases: user exactly at the Kaaba, antipodal point, and coordinates across the ±180° meridian.
Verify the expected values yourself before asserting them — don't take my numbers on faith.

## UI — Part 1: the entry card on the Time tab

In `time_view.dart`, **below the existing Azkar row** (do not disturb it — that row matches the Figma):

- A **full-width** card, same visual language as the Azkar cards: dark vertical gradient
  (`#262019` → `#0A0806`), **1px gold border**, radius **16**, horizontal margin matching the Azkar row.
- Height ~**110** (shorter than the 200-tall Azkar cards).
- Contents: a gold compass/Kaaba glyph on the left, then `Qibla` (white, bold, 18) with a smaller
  cream subtitle line under it (e.g. the live bearing, `136° from North`, or `Tap to find the Qibla`
  before location is known).
- Tapping it pushes `QiblaView`. Register the route in `AppRoutes` like the other screens.

## UI — Part 2: the Qibla screen

- Background: reuse `Assets.images.timeBackground` (same as the Time tab) so it feels native to the app.
- Transparent `AppBar`, gold back arrow, centered gold title `Qibla` (20 bold) — mirror `AzkarView`'s AppBar.
- **Centered compass dial**, ~70% of screen width:
  - **Draw everything with `CustomPainter` — do not add any new image assets.**
  - Gold circular ring on the dark background, with degree ticks (long every 30°, short every 10°) and
    `N / E / S / W` letters in gold.
  - The dial **counter-rotates with the device heading**, so N always points at real north.
  - A distinct **gold Kaaba needle/arrow** pointing at the Qibla bearing.
- **Aligned state:** when the device is within **±5°** of the Qibla, make it obvious — brighten the
  needle, add a soft gold glow, and a light haptic (`HapticFeedback.mediumImpact()`, once per
  alignment, not on every frame).
- Below the dial: the Qibla bearing in numbers (e.g. `136° NE`) and the **great-circle distance to Mecca in km**.
- Smooth the needle with `AnimatedRotation` (~300ms) so raw sensor jitter doesn't make it twitch.
  Take the **shortest rotation path** — the needle must never spin the long way round when crossing 0°/360°.

### States to handle — all of them
- **Loading** — gold `CircularProgressIndicator` while location resolves.
- **Location denied / disabled** — readable gold message + a retry button. Reuse `LocationException`.
- **No compass sensor** — `FlutterCompass.events` yields `null` heading on devices without a
  magnetometer. Show a clear message rather than a stuck needle.
- **Low sensor accuracy** — show a calibration hint ("Move your phone in a figure-8 to calibrate").
- **Offline** — this feature needs **no network at all**. Once the coordinates are known it works fully
  offline. Cache the last known coordinates (use the existing `CacheManager`) so the screen still works
  offline on a later launch.

## Ground rules

- No hardcoded colours/fonts — `AppColors` + `Theme.of(context).textTheme`, Janna everywhere.
- Don't touch the prayer card, the Azkar cards, the bloc, or the caching layer.
- `flutter analyze` clean; existing tests still pass. Commit: `feat(qibla): add qibla compass to Time tab`.

## Verify & report

1. `flutter analyze` clean, `flutter test` green (including the new calculator tests).
2. On the device: open the Time tab → tap the Qibla card → the dial should track the phone as you turn it.
   **Sanity-check the direction against a known-good qibla app or a known local qibla angle** — a
   compass that points confidently in the wrong direction is worse than no compass.
3. Report: the declination decision you made, anything you had to guess, and any state you couldn't
   test on the device.
