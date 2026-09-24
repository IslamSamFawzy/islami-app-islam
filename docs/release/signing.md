# Signing the release build

The app is signed with an **upload key** you create and keep. Google Play then
re-signs what you upload with the **app signing key**, which Play holds (Play
App Signing) — so losing the upload key is recoverable by asking Play for a
reset, while the app signing key is never in this repository at all.

## 1. Create the upload keystore

Run this once, outside the repository (the path below is an example):

```bash
keytool -genkeypair -v \
  -keystore ~/keys/islami-upload.jks \
  -storetype PKCS12 \
  -keyalg RSA -keysize 2048 -validity 10000 \
  -alias islami-upload
```

`keytool` comes with the JDK. It asks for a password and a name/organisation;
the name is not shown to users. Validity must comfortably outlive the app —
10000 days (~27 years) is the usual choice, and Play rejects keys expiring
before 2033.

## 2. Point the build at it

Create `android/key.properties` (this file is git-ignored and must stay that
way):

```properties
storePassword=<the password you chose>
keyPassword=<the key password, usually the same>
keyAlias=islami-upload
storeFile=/absolute/path/to/islami-upload.jks
```

`storeFile` may be absolute, or relative to `android/app/`.

## 3. Back it up

Keep the keystore **and** the passwords somewhere you will still have in five
years — a password manager entry with the file attached is enough. They are
not in this repository and cannot be regenerated. Without them you can still
ship (Play can reset the upload key), but the reset takes days.

## What happens without it

`flutter build apk --release` and `flutter build appbundle --release` **fail**:

```
Release builds need android/key.properties, which is missing.
See docs/release/signing.md ...
```

That is deliberate. Before this, a missing keystore silently fell back to the
debug key: the build succeeded, the APK installed, and Play rejected it. Debug
builds (`flutter run`, `flutter build apk --debug`) are unaffected.

## Version numbers

`pubspec.yaml` carries `version: 1.0.0+1` — the part before `+` is the version
name users see, the part after is the build number Play tracks.

* The first upload goes out as `1.0.0+1`.
* **Every** later upload needs a higher build number, even for a build that
  only fixes the store listing: `1.0.0+2`, `1.0.1+3`, and so on. Play refuses
  an upload whose build number it has already seen.

## Note for this repository's state

There is a local `android/app/dev-upload-test.jks` (with a matching
`key.properties`) that was generated only to prove the signing gate works and
to measure the release artifacts. It is git-ignored, it is **not** an upload
key, and it should be deleted once you create the real one:

```bash
rm android/app/dev-upload-test.jks android/key.properties
```
