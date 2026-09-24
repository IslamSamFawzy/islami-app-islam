# Permissions

Everything the app asks for, and why. This is the full list from the merged
release manifest — no permission is inherited from a plugin without appearing
here.

| Permission | Why |
|---|---|
| `INTERNET` | Fetching prayer times from api.aladhan.com, the radio and reciter lists from mp3quran.net, and streaming or downloading recitations. |
| `ACCESS_NETWORK_STATE` | Telling the user when they are offline and retrying a failed load when the connection returns. |
| `ACCESS_COARSE_LOCATION` | Prayer times and the Qibla direction depend on where the user is. Asked for at the moment the Qibla or the prayer card needs it; declined, the app falls back to Cairo. |
| `POST_NOTIFICATIONS` | The adhan plays through a foreground service, which must post a notification; the same permission covers the "time to pray" reminder. Asked for when the user turns the adhan on. |
| `SCHEDULE_EXACT_ALARM` | The adhan has to sound at the prayer minute, not whenever the system batches work. See exact-alarms.md. |
| `RECEIVE_BOOT_COMPLETED` | Alarms are cleared by a reboot; this lets the app re-arm the saved schedule. |
| `FOREGROUND_SERVICE` + `FOREGROUND_SERVICE_MEDIA_PLAYBACK` | Playing the full adhan when the app is closed. See foreground-service.md. |
| `VIBRATE` | The reminder notification's channel vibrates. |
| `WAKE_LOCK` | Lets the device finish starting adhan playback after an alarm wakes it while dozing. Declared by the notification/audio plugins as well as here. |

## Deliberately not requested

* `ACCESS_FINE_LOCATION` — the app asks geolocator for `LocationAccuracy.low`
  and rounds coordinates to two decimals (~1 km) for its cache key, so a
  precise fix would buy nothing. geolocator declares it, so the manifest
  removes it explicitly with `tools:node="remove"`.
* `USE_EXACT_ALARM` — would grant exact alarms without asking, but Play
  restricts it to alarm-clock and calendar apps. The app requests
  `SCHEDULE_EXACT_ALARM` instead and works (less precisely) without it.
* No storage permissions: downloads live in the app's own directory.
* No account, contacts, camera, microphone or advertising permissions.
