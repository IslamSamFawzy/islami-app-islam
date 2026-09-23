import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../error/exceptions.dart';

/// A thin persistence layer over [SharedPreferences] for caching API payloads.
///
/// Every value is stored as an envelope:
/// ```json
/// { "cachedAt": "<ISO-8601>", "data": <payload> }
/// ```
/// so the age of any cached entry can be inspected independently of its data.
///
/// Keys are namespaced with [_prefix] internally, which keeps cached entries
/// isolated from other preferences (e.g. recent suras) — [clearAll] only wipes
/// the cache, never the rest of the app's stored state.
class CacheManager {
  final SharedPreferences sharedPreferences;

  CacheManager({required this.sharedPreferences});

  /// Prefix applied to every cache key so [clearAll] can target only the cache.
  static const String _prefix = 'cache_';

  String _k(String key) => '$_prefix$key';

  /// Stores [jsonSerialisable] under [key] wrapped in a timestamped envelope.
  ///
  /// Throws [CacheException] if [jsonSerialisable] cannot be encoded as JSON.
  Future<void> write(String key, Object jsonSerialisable) async {
    final String encoded;
    try {
      encoded = json.encode({
        'cachedAt': DateTime.now().toIso8601String(),
        'data': jsonSerialisable,
      });
    } catch (e) {
      throw CacheException('Failed to serialise cache for "$key": $e');
    }
    await sharedPreferences.setString(_k(key), encoded);
  }

  /// Returns the stored envelope for [key], or `null` if it is absent or
  /// the stored value is corrupt (not decodable / wrong shape).
  Map<String, dynamic>? read(String key) {
    final raw = sharedPreferences.getString(_k(key));
    if (raw == null) return null;
    try {
      final decoded = json.decode(raw);
      if (decoded is! Map) return null;
      return decoded.cast<String, dynamic>();
    } catch (_) {
      return null;
    }
  }

  /// Stores [items] under [key] as a JSON list, via [toJson].
  Future<void> writeList<T>(
    String key,
    List<T> items,
    Map<String, dynamic> Function(T) toJson,
  ) {
    return write(key, items.map(toJson).toList());
  }

  /// The list stored under [key], or `null` when it is absent, corrupt, or —
  /// when [ttl] is given — older than [ttl].
  List<T>? readList<T>(
    String key,
    T Function(Map<String, dynamic>) fromJson, {
    Duration? ttl,
  }) {
    if (ttl != null && isStale(key, ttl)) return null;
    final data = read(key)?['data'];
    if (data is! List) return null;
    try {
      return data
          .map((e) => fromJson((e as Map).cast<String, dynamic>()))
          .toList();
    } catch (_) {
      // A corrupt entry is treated as a cache miss rather than crashing.
      return null;
    }
  }

  /// The instant [key] was last written, or `null` if absent/corrupt.
  DateTime? cachedAt(String key) {
    final envelope = read(key);
    final raw = envelope?['cachedAt'];
    return raw is String ? DateTime.tryParse(raw) : null;
  }

  /// Whether [key]'s entry is older than [ttl] (or missing, which counts as
  /// stale).
  bool isStale(String key, Duration ttl) {
    final at = cachedAt(key);
    if (at == null) return true;
    return DateTime.now().difference(at) > ttl;
  }

  /// Removes the entry stored under [key].
  Future<void> clear(String key) => sharedPreferences.remove(_k(key));

  /// Removes every cache entry (keys prefixed with [_prefix]) while leaving
  /// other preferences untouched.
  Future<void> clearAll() async {
    final keys = sharedPreferences
        .getKeys()
        .where((k) => k.startsWith(_prefix))
        .toList();
    for (final k in keys) {
      await sharedPreferences.remove(k);
    }
  }
}
