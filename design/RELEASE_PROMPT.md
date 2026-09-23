# Prompt for Claude Code — App icon + release APK

> Paste everything below the line into Claude Code.
> **Read the "What only Yehia can do" section at the bottom first** — one step needs the user, not you.

---

## Context

**Islami** — Flutter app, currently only ever built in debug. Goal: a **release APK to share and
sideload** (not Play Store, for now).

**The icon assets are already generated and in the repo** — do not regenerate or redraw them:
- `assets/icon/ic_launcher.png` — 1024×1024, the gold mosque on a **black** background, mosque at 78%.
  This is the legacy/fallback icon.
- `assets/icon/ic_launcher_foreground.png` — 1024×1024, mosque only, **transparent**, at 58% so it
  survives Android's adaptive-icon circular mask (safe zone is the centre 66%).

Both were cut from `assets/images/logo_splsh.png` with the "Islami" wordmark removed (unreadable at
icon size).

## Phase 1 — Launcher icon

- Add `flutter_launcher_icons` to `dev_dependencies`.
- Config (in `pubspec.yaml` or `flutter_launcher_icons.yaml`):
  - `image_path: assets/icon/ic_launcher.png`
  - `adaptive_icon_background: "#000000"`
  - `adaptive_icon_foreground: assets/icon/ic_launcher_foreground.png`
  - Android only for now (`android: true`, `ios: false` — no iOS build in scope).
- Run it, then **confirm** the generated `mipmap-*` icons and `mipmap-anydpi-v26/ic_launcher.xml`
  actually changed from the default Flutter icon.
- `assets/icon/` is a build-time source, **not** a runtime asset — do **not** add it to the `flutter:
  assets:` list in pubspec, and don't let it into `assets.gen.dart`.

## Phase 2 — App identity

- **App label**: `android:label="islami"` → **`Islami`** (capital I) in `AndroidManifest.xml`.
- **applicationId**: currently `com.example.islami`. Since this is sideload-only, `com.example.*`
  technically installs — **but** it's a Google-reserved prefix that Play Store rejects outright, and
  the applicationId can **never** be changed after a Play release without shipping a brand-new app.
  Change it now while it's free: **`com.route.islami`** (the design credits "Route").
  - Update `applicationId` **and** `namespace` in `android/app/build.gradle.kts`.
  - Move `MainActivity.kt` to the matching directory and update its `package` line — **this file has
    the Qibla `GeomagneticField` MethodChannel in it, don't lose that code.**
  - Rebuild and confirm the Qibla declination channel still works (its channel name
    `islami/geomagnetic` is unrelated to the package, so it should — but verify, don't assume).
  - **If you hit anything you're unsure about here, stop and ask** rather than half-renaming.

## Phase 3 — Splash screen

`flutter_native_splash.yaml` currently has `color: "#ffffff"` (white) — the app is dark-themed
end-to-end, so the launch flashes white before the dark splash. Fix it:
- `color` and `color_dark` → **`#202020`** (`AppColors.backgroundColor`, matching every screen).
- Same for `android_12.icon_background_color` / `icon_background_color_dark`.
- Re-run `flutter_native_splash:create` and verify no white flash on cold start.

## Phase 4 — Release build config

- **minSdk**: `build.gradle.kts` uses `flutter.minSdkVersion`, but the comment says geolocator +
  flutter_local_notifications need **23**. Check what `flutter.minSdkVersion` actually resolves to on
  this toolchain; if it's below 23, pin `minSdk = 23` explicitly. Report the resolved value.
- **Signing**: release currently uses `signingConfig = signingConfigs.getByName("debug")`. Wire it to
  read a real keystore from `android/key.properties` (the standard Flutter pattern:
  `storeFile` / `storePassword` / `keyAlias` / `keyPassword`), and **fall back to debug signing if
  `key.properties` is absent** so the build never breaks for someone without the key.
  - **Do NOT create the keystore and do NOT invent passwords** — Yehia does that (see below).
  - Add `android/key.properties` and `*.jks` / `*.keystore` to `.gitignore`. **Verify they're ignored
    before anything is committed** — a leaked keystore is unrecoverable.
- **Minification**: enable R8 (`isMinifyEnabled = true`, `isShrinkResources = true`) for release. Add a
  ProGuard rule file if any plugin needs it. If enabling it breaks the build or crashes at runtime,
  **turn it back off and tell me** — a working unminified APK beats a broken small one.

## Phase 5 — Build & verify

1. `flutter clean && flutter pub get`
2. `flutter build apk --release` (single fat APK — it's for manual sharing, so `--split-per-abi` would
   just create three files people have to choose between).
3. Report: the **APK path**, its **size**, and the **signing certificate** it actually used
   (`keytool -printcert -jarfile <apk>` — confirm it's the release key, not the debug key).
4. Install it on the device and check:
   - launcher icon = gold mosque on black, correct on the home screen **and** in the app drawer
   - app name reads **Islami**
   - no white flash on launch
   - the app opens and the Time + Qibla + Radio tabs still work **in release mode** (R8 can break
     reflection-based plugins — this is exactly where that shows up)
5. `flutter analyze` clean; the 71 tests still pass.

---

## What only Yehia can do — do not attempt these yourself

**Creating the keystore.** This involves choosing passwords; Claude must not generate, type, or store
them. Print these instructions and stop:

```
keytool -genkey -v -keystore %USERPROFILE%\islami-release.jks ^
  -storetype JKS -keyalg RSA -keysize 2048 -validity 10000 -alias islami
```

Then create `android/key.properties` (never commit it):

```
storePassword=<the store password you chose>
keyPassword=<the key password you chose>
keyAlias=islami
storeFile=C:/Users/Islam/islami-release.jks
```

⚠️ **Back this .jks file up somewhere safe.** If it's lost, every future update must be a different
app — users would have to uninstall and reinstall, losing their downloads and settings. There is no
recovery.

If `key.properties` isn't there when you build, the fallback keeps debug signing — the APK still
installs, but it's tied to whatever machine's debug key built it, so updates from a different machine
will refuse to install over it.
