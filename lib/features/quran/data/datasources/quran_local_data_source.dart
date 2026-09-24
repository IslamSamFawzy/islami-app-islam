import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../../core/constants/sura_names.dart';
import '../../../../core/error/exceptions.dart';
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
}

class QuranLocalDataSourceImpl implements QuranLocalDataSource {
  final SharedPreferences sharedPreferences;

  QuranLocalDataSourceImpl({required this.sharedPreferences});

  /// Key under which the recent sura IDs are stored.
  static const String _recentKey = 'recent_sura_ids';

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
