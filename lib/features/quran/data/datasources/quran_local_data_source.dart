import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../../core/cache/json_store.dart';
import '../../../../core/constants/sura_names.dart';
import '../../../../core/error/exceptions.dart';
import '../models/reading_progress_model.dart';
import '../models/sura_model.dart';

/// Contract for the local Quran data source.
abstract class QuranLocalDataSource {
  /// Returns the static list of all 114 suras.
  Future<List<SuraModel>> getAllSuras();

  /// Loads the verses of a sura from its bundled text file.
  Future<List<String>> getSuraVerses(int suraId);

  /// Returns the numbers of recently read suras, most recent first.
  Future<List<int>> getRecentSuraIds();

  /// Records [suraId] as the most recently read sura (deduped, capped).
  Future<void> addRecentSuraId(int suraId);

  /// How far the reader got in [suraId], or `null` if they never read it.
  Future<ReadingProgressModel?> getProgress(int suraId);

  /// Stores how far the reader got.
  Future<void> saveProgress(ReadingProgressModel progress);
}

class QuranLocalDataSourceImpl implements QuranLocalDataSource {
  final SharedPreferences sharedPreferences;
  final JsonStore jsonStore;

  QuranLocalDataSourceImpl({
    required this.sharedPreferences,
    required this.jsonStore,
  });

  /// Key under which the recent sura IDs are stored.
  static const String _recentKey = 'recent_sura_ids';

  /// Key for the `suraId -> {ayahIndex, updatedAt}` map. Separate from the
  /// recents, which keep their own order and their own key.
  static const String _progressKey = 'reading_progress';

  /// Maximum number of recent suras kept.
  static const int _recentLimit = 10;

  @override
  Future<List<SuraModel>> getAllSuras() async {
    try {
      // Built from the shared canonical list.
      return SuraNames.all
          .map((s) => SuraModel(
                id: s.number,
                nameEn: s.nameEn,
                nameAr: s.nameAr,
                ayaCount: s.ayaCount,
              ))
          .toList();
    } catch (e) {
      throw LocalDataException('Failed to load suras: $e');
    }
  }

  @override
  Future<List<int>> getRecentSuraIds() async {
    try {
      // Stored as strings (SharedPreferences has no int list) and parsed here,
      // so the key and its contents stay as earlier versions wrote them.
      return (sharedPreferences.getStringList(_recentKey) ?? <String>[])
          .map(int.tryParse)
          .whereType<int>()
          .toList();
    } catch (e) {
      throw LocalDataException('Failed to load recent suras: $e');
    }
  }

  @override
  Future<void> addRecentSuraId(int suraId) async {
    try {
      final current = sharedPreferences.getStringList(_recentKey) ?? <String>[];
      // Move to front, remove duplicates, cap length.
      current
        ..remove('$suraId')
        ..insert(0, '$suraId');
      final capped = current.take(_recentLimit).toList();
      await sharedPreferences.setStringList(_recentKey, capped);
    } catch (e) {
      throw LocalDataException('Failed to save recent sura: $e');
    }
  }

  @override
  Future<ReadingProgressModel?> getProgress(int suraId) async {
    try {
      final stored = jsonStore.readMap(_progressKey)['$suraId'];
      if (stored is! Map) return null;
      return ReadingProgressModel.fromEntry(
        suraId,
        stored.cast<String, dynamic>(),
      );
    } catch (e) {
      throw LocalDataException('Failed to load reading progress: $e');
    }
  }

  @override
  Future<void> saveProgress(ReadingProgressModel progress) async {
    try {
      final all = jsonStore.readMap(_progressKey);
      all['${progress.suraId}'] = progress.toJson();
      await jsonStore.writeMap(_progressKey, all);
    } catch (e) {
      throw LocalDataException('Failed to save reading progress: $e');
    }
  }

  @override
  Future<List<String>> getSuraVerses(int suraId) async {
    try {
      final content =
          await rootBundle.loadString('assets/files/suras/$suraId.txt');
      return content
          .split('\n')
          .map((line) => line.trim())
          .where((line) => line.isNotEmpty)
          .toList();
    } catch (e) {
      throw LocalDataException('Failed to load verses for sura $suraId');
    }
  }
}
