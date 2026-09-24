# Privacy policy (draft)

> Draft for review, not final legal text. Everything below is taken from what
> the code actually does; the owner should confirm the contact address and the
> effective date before publishing it.

**Islami** does not have accounts, does not show adverts, and does not use
analytics or any tracking SDK. There is no server of ours: what the app keeps,
it keeps on the phone.

## What the app uses

**Approximate location.** Prayer times and the Qibla direction depend on where
you are. The app asks Android for a coarse location (roughly the nearest
kilometre — it never requests precise location) at the moment it needs one.

* The coordinates are sent to **api.aladhan.com** to fetch that month's prayer
  times. That request contains the coordinates, the month and the calculation
  method, and nothing else — no identifier, no device information we add.
* The same coordinates are used on the device to compute the Qibla direction,
  and are kept on the device so the Qibla still works offline.
* If you refuse the location permission, the app uses Cairo as a fallback and
  keeps working.

**Internet.** Besides prayer times, the app fetches the radio-station and
reciter lists from **mp3quran.net**, and streams or downloads recitations from
the servers those lists point to. Those requests carry no identifier of you
beyond what any HTTP request unavoidably carries (your IP address, which those
services see as their own visitors').

**Notifications.** If you turn the adhan on, the app asks for permission to
post notifications so the adhan can sound and be stopped from the notification.

## What is stored, and where

All of it is on your device, in the app's own storage, and all of it goes away
when the app is uninstalled:

* the month of prayer times most recently downloaded, and your last known
  coordinates;
* the radio and reciter lists (cached for a week);
* suras you have downloaded for offline listening, and an index of them;
* which adhans you want, which suras you read recently and where you stopped
  in them, and whether you have seen the intro.

Nothing is uploaded, backed up to us, or shared with anyone. We cannot see any
of it.

## Children

The app is suitable for all ages and collects nothing that identifies anyone.

## Changes and contact

If this policy changes, the new version will be published at the same address
and the app's store listing will point at it.

Contact: **<owner to fill in — the address the store listing will show>**
