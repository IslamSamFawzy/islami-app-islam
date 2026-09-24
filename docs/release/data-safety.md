# Play Data safety form — suggested answers (draft)

Based on what the code does today. Each answer has the reason next to it, so a
reviewer can check it against the source rather than take it on trust.

## Does your app collect or share any of the required user data types?

**Yes — location (approximate), and only because it leaves the device.**

Play counts data as "collected" when it is transferred off the device, even to
a third party you do not control. The coordinates go to api.aladhan.com to
fetch prayer times, so they must be declared. Everything else the app stores
stays on the device, which Play does *not* count as collection.

## Location

| Question | Answer | Why |
|---|---|---|
| Data type | **Approximate location** | `LocationAccuracy.low`, and `ACCESS_FINE_LOCATION` is removed from the manifest. |
| Collected? | Yes | Sent to api.aladhan.com in the prayer-times request. |
| Shared? | Yes — with a third party | aladhan.com is not ours. |
| Processed ephemerally? | No | The month's response is cached on the device, and the coordinates are kept for offline Qibla. |
| Required or optional? | **Optional** | Refusing the permission falls back to Cairo; the app still works. |
| Purpose | **App functionality** | Prayer times and Qibla direction. Nothing else. |
| Used for tracking/advertising? | No | There is no advertising or analytics SDK in the project. |

## Everything else: not collected

Stored only on the device (prayer-time cache, radio/reciter cache, downloaded
recitations and their index, adhan settings, recent suras and reading
position, the "seen the intro" flag). Uninstalling removes all of it.

* No account, name, email, phone number or contacts — there is no sign-in.
* No photos, files, messages, calendar or contacts access.
* No device or advertising identifiers.
* No crash logs or analytics collected by us.
* No in-app purchases or payment data.

## Security answers

| Question | Answer | Why |
|---|---|---|
| Is data encrypted in transit? | **Yes** | Every request is HTTPS. The two APIs (api.aladhan.com, mp3quran.net) are HTTPS, and any `http://` recitation server the reciters API hands out is rewritten to `https://` before it is used — see `ReciterModel` in `lib/features/radio/data/models/reciter_model.dart`. Cleartext traffic is not enabled in the manifest, so nothing can fall back to HTTP. |
| Can users request deletion? | **Yes — by uninstalling** | Nothing is held anywhere else; there is nothing for us to delete. |
| Has your app been independently validated? | No | No such review has been done. |

## Privacy policy

The URL Play asks for: **https://islamsamfawzy.github.io/islami-app-islam/privacy/**
(source text in `privacy-policy.md`, published page in `docs/privacy/`).

## To confirm before submitting

* Nothing outstanding for the security answers. The recitation audio URLs come
  from the mp3quran.net API at runtime; all 287 servers in today's response
  were already HTTPS, all ten `serverN.mp3quran.net` hosts were checked to
  serve audio over TLS, and the app upgrades a cleartext server to HTTPS
  anyway.
