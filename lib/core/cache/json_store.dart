import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

/// Plain JSON storage over [SharedPreferences] for state the app owns — as
/// opposed to cached API payloads, which belong in `CacheManager` with its key
/// namespace and timestamp envelope.
///
/// Keys are used exactly as given, so data written by earlier versions of the
/// app keeps being found.
class JsonStore {
  final SharedPreferences sharedPreferences;

  JsonStore({required this.sharedPreferences});

  /// The map stored under [key]; an empty map when it is absent or corrupt.
  Map<String, dynamic> readMap(String key) {
    final raw = sharedPreferences.getString(key);
    if (raw == null) return {};
    try {
      final decoded = json.decode(raw);
      return decoded is Map ? decoded.cast<String, dynamic>() : {};
    } catch (_) {
      return {};
    }
  }

  Future<void> writeMap(String key, Map<String, dynamic> value) {
    return sharedPreferences.setString(key, json.encode(value));
  }
}
