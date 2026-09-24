# Foreground service declaration (draft)

Play asks every app that declares a foreground service type to justify it in
the console, and for `mediaPlayback` it asks for a short screen recording.

## What the service does

`AdhanService` (`android/app/src/main/kotlin/.../AdhanService.kt`) plays the
adhan — a two to three minute recitation — at a prayer time, from
`res/raw/adhan.mp3` (or `adhan_fajr.mp3` for Fajr). It is started by an exact
alarm set by the app, shows an ongoing notification for as long as it plays,
with a **Stop** action, and stops itself when the recitation ends.

## Suggested justification text

> The app is a prayer-times app. When a prayer time arrives it plays the adhan
> (the call to prayer) — an audio recitation of two to three minutes — which is
> the core function users install it for. Playback starts at a time the user
> has scheduled by switching that prayer on in the app's settings, and
> continues while the app is in the background or closed, so a foreground
> service of type mediaPlayback is required. The notification it posts shows
> which prayer it is and offers Stop, which ends both the audio and the
> service. Users can switch individual prayers, or all of them, off at any
> time in the app's settings screen.

## Why `mediaPlayback` is the right type

The service does one thing: play an audio file to the user, with a
notification that can stop it. It is not doing data sync, location work or
anything else in the background.

## The screen recording Play asks for

Record one pass, about 30-45 seconds, no narration needed:

1. Open the app and go to the **Time** tab, so the prayer times are visible.
2. Tap the **gear** and show the **Adhan notifications** master switch on, and
   the per-prayer switches — this is the user enabling it.
3. Go back to the Time tab. (For the recording, set one prayer a minute or two
   ahead — either by changing the device clock, or by recording at a real
   prayer time.)
4. Let the adhan fire with the app in the background or the screen locked, so
   the notification appears and the adhan is audible.
5. Tap **Stop** on the notification and show that the audio ends.

That covers what Play looks for: the user turning it on, the service running
with its notification, and the user being able to stop it.
