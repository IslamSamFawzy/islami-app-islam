# Prompt for Claude Code — 50 hadiths · Sebha redesign · Adhan notification

> Three **independent** parts. Do them **one at a time** — finish and commit Part A before starting B.
> `flutter analyze` clean + the 71 tests green after each.

---

# PART A — Load the 50 hadiths from assets

## What's there now
`HadithLocalDataSourceImpl` returns **5 hardcoded** `HadithModel`s from a `static const _hadiths` list.

## What's new
Yehia added **50 files** at `assets/files/hadeeth/` — `h1.txt` … `h50.txt` (all 50 present, no gaps,
64 KB total). Format:

```
<line 1>  = the title, e.g. "الحد يث الأول"
<lines 2+> = the hadith body (one or more paragraphs)
```

## Landmines — handle each explicitly

1. **BOM.** Every file starts with a UTF-8 BOM, and **`h1.txt` has a double BOM** (`﻿﻿`).
   Strip **all** leading BOMs, not just one, or the first title renders with an invisible glyph.
2. **Natural sort.** `h1, h2, … h10` — **not** lexicographic (`h1, h10, h11, h2…`). Sort by the parsed
   integer. Don't glob-and-sort as strings.
3. **Don't "fix" the Arabic.** Titles read `الحد يث الأول` with a space inside `الحديث`. That looks like
   a typo but **the Figma hadith card shows exactly the same spacing** — it's intentional. Load the
   text **verbatim**. Do not normalise, re-space, or re-punctuate anything.
4. **Line count varies** — `h1` has 3 lines, `h2` has 17. Join lines 2+ preserving the paragraph breaks
   (`\n`), so the body still reads as paragraphs in the card.
5. **pubspec** — `assets/files/hadeeth/` is **not** declared yet. Add it under `flutter: assets:`.

## Implementation
- Follow the pattern that already exists: `QuranLocalDataSourceImpl.getSuraVerses` loads bundled text
  with `rootBundle.loadString`. Mirror it — don't invent a new approach.
- `getAllHadiths()` reads the 50 files and returns them in order (1→50). Loading 50 small files is fine;
  load them **in parallel** (`Future.wait`), not in a serial loop.
- Delete the 5 hardcoded hadiths. Keep the `Hadith` entity (`title` + `content`) and `HadithModel` as-is.
- A missing/unreadable file must throw `LocalDataException` (as today) — **don't** silently skip it and
  quietly show 49 hadiths.

## Verify
- Hadith tab shows **50** cards; carousel peeks still work; the long ones (h2) scroll **inside** the card.
- Tapping a card opens the details view with the full text; `Hadith N` numbering runs 1→50.
- Arabic RTL renders correctly, no clipping, no stray BOM glyph on card 1.
- A test asserting `getAllHadiths().length == 50` and that the first title is exactly `الحد يث الأول`.

---

# PART B — Sebha screen: match the Figma + the bead animation

**Figma frame:** `https://www.figma.com/design/rYIdiZRmbIhvvoGbLPQ9Al/Islami?node-id=34333-496`
(view-only file — the Figma MCP will error; work from this spec and compare on-device.)

## Differences I measured against the current code — fix these

1. **The title has NO underline.** `tasbeh_view.dart` sets `decoration: TextDecoration.underline` on
   `سَبِّحِ اسْمَ رَبِّكَ الأَعْلَى`. The Figma has **no underline** — plain cream/white text with the
   tashkeel intact. Remove the decoration.
2. **The top marker is wrong.** `_BeadsPainter` draws bead `i == 0` as a slightly larger cream circle.
   The Figma has a **distinct gold finial** ("imam" head-piece) sitting **above and outside** the ring:
   a tulip/bulb body with **three short prongs** on top, pointing down toward the beads.
   Draw it with `CustomPainter` (no new assets) as a separate, **static** element.
3. **The finial must NOT rotate.** This is the whole point of the animation: on a real misbaha the head
   stays put and you pull beads past it. Currently `AnimatedRotation` wraps the entire painter, so the
   marker spins with the ring. Restructure: **rotate only the bead ring**; the finial is a fixed sibling
   in the `Stack`, and the centre text (`سبحان الله` / `30`) is also fixed — it must never rotate.
4. **Beads are denser and 3-D.** The Figma ring is ~33 gold beads that **touch** each other, each with a
   soft radial highlight (light top-left → deeper gold bottom-right). Current beads are flat circles with
   a hard offset shadow dot and visible gaps. Size the beads from the ring circumference so they sit
   shoulder-to-shoulder, and use a `RadialGradient` shader for the 3-D look.
5. **Centre text** — `سبحان الله` above, the count (`30`) below, both centred inside the ring, white.

Background (`taspeh_background.png`), the header wordmark and the counter behaviour (1→33, then the
dhikr advances) are already correct — **leave them alone**.

> The Figma's bottom nav labels the Sebha tab "Hadith" — that's a **Figma bug**, our labels are right.
> Ignore it.

## The animation
- One tap = the ring advances **exactly one bead step**, smoothly (`AnimatedRotation`, ~250–300ms, `easeOut`).
- Rotation stays **monotonic** — it must never snap backwards when the counter resets at 33.
  (The current `totalCount / beadCount` approach is correct; preserve that property.)
- Add a light `HapticFeedback.selectionClick()` per tap.

## Verify
Screenshot the running screen against the Figma frame: finial static at top, ring rotating under it,
no underline, beads touching, centre text steady.

---

# PART C — Adhan in the notification (unblocked — audio is in place)

**The audio files are already in the repo at the correct location — do not move, rename or re-encode them:**

| File | Duration | Format |
|---|---|---|
| `android/app/src/main/res/raw/adhan.mp3` | **3:24** | 16 kbps · 16 kHz · mono · 461 KB |
| `android/app/src/main/res/raw/adhan_fajr.mp3` | **3:34** | 16 kbps · 16 kHz · mono · 481 KB |

The Fajr file is the longer one — correct, it carries *الصلاة خير من النوم*. Both verified as valid,
non-truncated MP3s.

**Cleanup:** the originals are still sitting at `assets/files/adhan/` (I copied them to `res/raw`
but couldn't delete the source). **Delete `assets/files/adhan/` — it is not needed and is not declared
in pubspec, so it would just bloat the APK by ~1 MB.** Confirm nothing references that path.

## What's there now (and why it's wrong)
`TimeBloc._maybePlayAdhan` streams the adhan from a **hardcoded online URL**
(`https://www.islamcan.com/audio/adhan/azan2.mp3`) and only while the app is open on the Time tab.
So: no internet → no adhan; app closed → no adhan. The notification itself just uses the **default**
system sound.

## Target
At each prayer time the **full adhan plays even if the app is closed**, via a foreground service.
**Fajr uses `adhan_fajr.mp3`; every other prayer uses `adhan.mp3`.**
(Sunrise is informational — no adhan, as today.)

## The hard parts — do not skip these

1. **Notification channels are immutable.** On Android 8+, sound is a property of the *channel*, set at
   creation and **unchangeable afterwards**. The existing `adhan_channel` is already installed on
   devices with the default sound — editing its sound in code will silently do nothing.
   → Create **new** channel IDs (e.g. `adhan_regular_v2`, `adhan_fajr_v2`) and **delete** the old
   `adhan_channel`. Two sounds = two channels, always.
2. **Foreground service, native.** The reliable chain is:
   exact `AlarmManager` alarm → `BroadcastReceiver` → start a foreground `Service` → `MediaPlayer`
   plays the adhan → ongoing notification with a **Stop** action → service stops itself on completion.
   Write it in Kotlin. `MainActivity.kt` already hosts the Qibla `GeomagneticField` MethodChannel —
   follow that precedent, and **don't disturb that code**.
3. **Manifest.** `SCHEDULE_EXACT_ALARM` / `USE_EXACT_ALARM` are already declared. You'll also need
   `FOREGROUND_SERVICE` and, for Android 14+, `FOREGROUND_SERVICE_MEDIA_PLAYBACK` plus
   `android:foregroundServiceType="mediaPlayback"` on the `<service>`.
4. **Reboot.** Alarms die on reboot. `RECEIVE_BOOT_COMPLETED` is already declared — add a boot receiver
   that reschedules from the cached prayer month.
5. **Respect the existing mute toggle.** `TimeState.muted` already exists and the prayer card has the
   mute icon — muted must mean *no adhan fires at all*, not "fires silently".
6. **Doze / OEM killers.** Xiaomi/Samsung/Huawei aggressively kill alarms. Use
   `setExactAndAllowWhileIdle`. If it still doesn't fire on the test device, **tell me** — don't paper
   over it with a workaround that only appears to work.

## Verify
- Set a prayer time ~2 minutes out (temporarily), **close the app fully**, confirm the adhan fires and
  plays to the end, and that Stop works.
- Confirm **Fajr plays the Fajr adhan** and another prayer plays the regular one — this is the one thing
  most likely to be silently wrong.
- Confirm muted = nothing fires.
- Reboot the phone, confirm the next adhan still fires.
- Remove the online `_adhanUrl` path once the service works — don't leave two adhan mechanisms racing.

---

## Report
Per part: what changed, anything you guessed, and anything you couldn't verify on-device.
