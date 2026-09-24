# Exact alarms (draft)

## Why the app asks for `SCHEDULE_EXACT_ALARM`

A prayer time is a minute, not a window. Maghrib is called at sunset, and an
adhan a few minutes late is the wrong adhan — people break their fast by it.
The app therefore arms one exact alarm per prayer
(`AlarmManager.setExactAndAllowWhileIdle`), which is the only way to get the
system to fire at a given minute while the device is dozing.

The alarms are set from the prayer times the app has downloaded: every prayer
carries the real instant of each day, so the times follow the calendar instead
of repeating one clock time.

## Why not `USE_EXACT_ALARM`

`USE_EXACT_ALARM` is granted without asking, but Play restricts it to apps
whose primary purpose is alarms or calendars. A prayer-times app is not that,
so the app declares `SCHEDULE_EXACT_ALARM` and asks the user instead.

## What happens without the permission

On Android 14 and later the permission is not granted to new installs, so the
app has to work without it, and it does:

* Before arming, it checks `AlarmManager.canScheduleExactAlarms()`.
* If exact alarms are not allowed, it uses `setAndAllowWhileIdle` instead. The
  adhan still plays, but the system may hold the alarm back by some minutes.
* Android 12+ only exempts a background foreground-service start when the
  alarm that triggered it was exact. So when the inexact alarm fires and the
  service start is refused, the app posts a high-priority notification with a
  sound saying it is time for that prayer, instead of the full adhan. Tapping
  it opens the app.
* The settings screen shows a row, **"Allow exact alarms for on-time adhan"**,
  which opens the system screen for it. The row explains that without it the
  adhan may be late or arrive as a notification. It disappears as soon as the
  user comes back having granted it, and the device re-arms the alarms itself.

## Suggested console text

> Islami is a prayer-times app. It plays the adhan (call to prayer) at each
> prayer time, which is defined to the minute by the daily prayer schedule for
> the user's location — an adhan delivered minutes late is incorrect for
> worship, particularly at Maghrib, when fasts are broken. The app therefore
> schedules one exact alarm per prayer the user has enabled. It requests
> SCHEDULE_EXACT_ALARM at runtime rather than declaring USE_EXACT_ALARM, and
> it degrades gracefully when the permission is not granted: it falls back to
> inexact alarms and a high-priority notification.
