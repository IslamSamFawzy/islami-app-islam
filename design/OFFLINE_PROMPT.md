# Prompt for Claude Code — Islami: offline support (API cache + downloadable audio)

> Paste everything below the line into Claude Code. Same rules as before: one phase at a time,
> `flutter analyze` clean after each, one commit per phase.

---

## Context

**Islami** — Flutter, `flutter_bloc` + `get_it` + clean architecture
(`lib/features/<feature>/{data,domain,presentation}`, shared code in `lib/core`).

Only **two** features hit the network today; everything else already reads from bundled assets:

| Feature | Endpoint | Data |
|---|---|---|
| Radio | `https://mp3quran.net/api/v3/radios?language=ar` | radio stations |
| Radio | `https://mp3quran.net/api/v3/reciters?language=ar` | reciters (moshaf servers) |
| Time | `https://api.aladhan.com/v1/timings?...&method=5` | today's prayer times |

Quran, Hadith and Azkar are local assets — leave them alone.

**Goal:** the app must be **useful with no internet**.

Two parts:
- **Part A** — cache API responses locally so the Radio and Time tabs render offline.
- **Part B** — let the user **download suras for offline listening**, and play the local file when it exists.

## Decisions already made — do not re-litigate

1. **Storage: `shared_preferences` + JSON.** It's already a dependency and already registered in
   `service_locator.dart`. No Hive, no sqflite.
2. **Strategy: cache-first, then refresh in the background.** The screen renders instantly from cache;
   the network fetch runs after and updates the UI if it succeeds. It must **never** blank the screen
   or show a spinner over good cached data.
3. **Audio downloads are in scope** (Part B).

## Ground rules

- Don't break the architecture. Cache lives in the **data layer** (new `LocalDataSource` per feature);
  blocs and the domain layer stay clean.
- `CacheException` and `CacheFailure` **already exist** in `core/error/` — use them, don't add new ones.
- No hardcoded colours/fonts in widgets: `AppColors` + `Theme.of(context).textTheme`.
- `flutter analyze` clean after every phase. One commit per phase.
- If something in this prompt turns out to be wrong once you read the code, **say so and stop** —
  don't silently invent a different design.

---

# PART A — Offline cache for API data

## Phase A1 — Cache infrastructure

- `lib/core/cache/cache_manager.dart` — a thin wrapper over `SharedPreferences`:
  - `Future<void> write(String key, Object jsonSerialisable)` — stores
    `{"cachedAt": <ISO-8601>, "data": <payload>}`.
  - `Map<String, dynamic>? read(String key)` — returns the envelope, or `null` if absent/corrupt.
  - `DateTime? cachedAt(String key)` and `bool isStale(String key, Duration ttl)`.
  - `Future<void> clear(String key)` / `clearAll()`.
  - Throws `CacheException` on malformed JSON.
- Register it in `service_locator.dart` as a lazy singleton.
- Add `toJson()` to `RadioStationModel`, `ReciterModel` and `PrayerTimesModel` — they only have
  `fromJson` today. `Prayer.time` is a `DateTime`; serialise as ISO-8601 and parse back.
  **Round-trip test each model** (`fromJson(toJson(x)) == x`) before moving on.

## Phase A2 — Radio cache

- `RadioLocalDataSource` (+ `Impl`) with `cacheRadios` / `getCachedRadios` / `cacheReciters` /
  `getCachedReciters`. TTL: **7 days**.
- `RadioRepositoryImpl` takes both data sources. Behaviour:
  1. Read the cache. If present → return it immediately.
  2. Hit the network. On success → overwrite the cache and return the fresh list.
  3. On `ServerException` → if a cache exists, return it (**not** a `Failure`); if not, return
     `ServerFailure`.
- To get "render cached, then refresh" without rewriting every bloc into streams: add a
  `forceRefresh` flag to the use-case params. `RadioBloc` handles `LoadRadioDataEvent` by loading from
  cache first (emit), then dispatching an internal refresh that re-emits if the network returns
  something different. Keep `state.isFromCache` (or similar) so the UI can tell.

## Phase A3 — Prayer times cache

The current endpoint returns **only today**, which is useless the moment the user is offline tomorrow.
Switch to the **monthly calendar** endpoint so one online session covers the whole month:

```
https://api.aladhan.com/v1/calendar?latitude=<lat>&longitude=<lng>&method=5&month=<MM>&year=<YYYY>
```

- Cache the whole month under a key that includes the **rounded coordinates** (2 decimal places is
  plenty) and `YYYY-MM`. Then "today's prayer times" is a lookup into the cached month — **zero
  network calls** for the rest of the month.
- Keep the existing Cairo fallback coordinates when location is denied.
- If the user is offline *and* the month isn't cached, return `CacheFailure` with a clear message the
  Time tab can render.
- Refetch the month when: the month rolls over, or the cached coordinates differ from the current
  ones by more than ~1 km.

## Phase A4 — Offline indicator

- Add `connectivity_plus`.
- When the visible data came from cache **and** there's no connection, show a small non-blocking strip
  under the header: gold background, dark text, something like `Offline — showing saved data`.
  It must not cover content and must disappear on reconnect (and trigger a refresh).

---

# PART B — Downloadable suras for offline listening

## Phase B1 — Extend the reciter model

`ReciterModel.fromJson` currently throws away everything except a sample URL
(`<server>/001.mp3`). It needs the real data:

- Keep `moshafServer` (the `server` field) and `surahList` — the API returns `surah_list` as a
  comma-separated string of sura numbers; parse it to `List<int>`.
- A sura's audio URL is `<server>/<sura number, zero-padded to 3>.mp3` — e.g. `.../002.mp3`.
- Update `Reciter` (entity), `toJson`/`fromJson`, and anything that consumed the old `playUrl`.

## Phase B2 — Download service + index

- Add `dio` (download progress + cancellation) and `path_provider`.
- `lib/core/services/download_service.dart`:
  - Saves to `getApplicationDocumentsDirectory()/audio/<reciterId>/<sura>.mp3` — an app-private
    directory, so **no storage permission is needed** on Android or iOS.
  - Exposes a progress stream (`0.0 → 1.0`), `cancel()`, and `delete()`.
  - Downloads to a `.part` file and renames on completion, so an interrupted download never leaves a
    corrupt playable file.
- New feature `lib/features/downloads/`:
  - `DownloadsLocalDataSource` — a `SharedPreferences` index: `reciterId + suraId → {path, bytes, downloadedAt}`.
  - `DownloadsBloc` — a queue (one download at a time), per-item progress, cancel, delete.
  - On startup, reconcile the index against the filesystem and drop entries whose file is gone.

## Phase B3 — Download UI

- **Radio tab → Reciters:** tapping a reciter opens a sura list for that reciter; each row has a
  download button that turns into a progress ring, then a "downloaded" state (tap → delete).
- **New Downloads screen** (reachable from the Time tab's overflow or a nav entry — pick the least
  intrusive spot and tell me which you chose): grouped by reciter, shows total size on disk, allows
  deleting a sura or a whole reciter.
- Match the existing design language exactly: gold tiles on `#202020`, Janna font, `AppColors` only.

## Phase B4 — Play local first

- `AudioPlayerService`: add `playFile(String path)` using `DeviceFileSource`.
- Before playing any sura, check the downloads index: **local file exists → play the file**; otherwise
  stream. This is the whole point — a downloaded sura must play in airplane mode.
- Live radio streams stay online-only (that's expected — say so in the UI rather than failing silently
  when a stream is tapped with no connection).

---

# Phase C — Verify

1. `flutter analyze` clean; app builds and runs.
2. **Airplane-mode test on the device**, fresh from a normal online session:
   - Radio tab → station and reciter lists still render (from cache).
   - Time tab → today's prayer times still render (from the cached month).
   - A downloaded sura → plays.
   - The offline strip appears; nothing crashes; no infinite spinners.
3. **Cold-start-offline test:** clear app data, turn the network off, launch. Every screen must fail
   *gracefully* with a readable message — no crash, no blank screen.
4. Report back: what you changed per phase, any place you had to guess, and the new dependencies you added.
