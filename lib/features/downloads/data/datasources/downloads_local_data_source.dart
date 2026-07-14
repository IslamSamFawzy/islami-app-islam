import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../models/download_entry_model.dart';

/// A SharedPreferences-backed index of downloaded suras, keyed by
/// `<reciterId>/<suraId>`.
abstract class DownloadsLocalDataSource {
  List<DownloadEntryModel> getAll();

  DownloadEntryModel? get(String reciterId, String suraId);

  Future<void> put(DownloadEntryModel entry);

  Future<void> remove(String reciterId, String suraId);

  Future<void> removeReciter(String reciterId);
}

class DownloadsLocalDataSourceImpl implements DownloadsLocalDataSource {
  final SharedPreferences sharedPreferences;

  DownloadsLocalDataSourceImpl({required this.sharedPreferences});

  static const String _key = 'downloads_index';

  Map<String, dynamic> _read() {
    final raw = sharedPreferences.getString(_key);
    if (raw == null) return {};
    try {
      final decoded = json.decode(raw);
      return decoded is Map ? decoded.cast<String, dynamic>() : {};
    } catch (_) {
      return {};
    }
  }

  Future<void> _write(Map<String, dynamic> map) =>
      sharedPreferences.setString(_key, json.encode(map));

  @override
  List<DownloadEntryModel> getAll() {
    return _read()
        .values
        .whereType<Map>()
        .map((e) => DownloadEntryModel.fromJson(e.cast<String, dynamic>()))
        .toList();
  }

  @override
  DownloadEntryModel? get(String reciterId, String suraId) {
    final raw = _read()['$reciterId/$suraId'];
    if (raw is! Map) return null;
    return DownloadEntryModel.fromJson(raw.cast<String, dynamic>());
  }

  @override
  Future<void> put(DownloadEntryModel entry) async {
    final map = _read();
    map[entry.key] = entry.toJson();
    await _write(map);
  }

  @override
  Future<void> remove(String reciterId, String suraId) async {
    final map = _read();
    map.remove('$reciterId/$suraId');
    await _write(map);
  }

  @override
  Future<void> removeReciter(String reciterId) async {
    final map = _read()..removeWhere((k, _) => k.startsWith('$reciterId/'));
    await _write(map);
  }
}
