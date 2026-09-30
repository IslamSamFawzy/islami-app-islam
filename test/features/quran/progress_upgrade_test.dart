// The first launch after upgrading from 1.0.1+2: the reading progress that
// version saved must show on the Most Recently cards and resume on the right
// Mushaf page, straight away, with nothing read in between.
import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:islami/core/cache/json_store.dart';
import 'package:islami/features/quran/data/datasources/mushaf_local_data_source.dart';
import 'package:islami/features/quran/data/datasources/quran_local_data_source.dart';
import 'package:islami/features/quran/data/repositories/mushaf_repository_impl.dart';
import 'package:islami/features/quran/data/repositories/quran_repository_impl.dart';
import 'package:islami/features/quran/domain/entities/ayah_ref.dart';
import 'package:islami/features/quran/domain/services/sura_search_filter.dart';
import 'package:islami/features/quran/domain/usecases/add_recent_sura.dart';
import 'package:islami/features/quran/domain/usecases/get_all_suras.dart';
import 'package:islami/features/quran/domain/usecases/get_juz_start.dart';
import 'package:islami/features/quran/domain/usecases/get_mushaf_page.dart';
import 'package:islami/features/quran/domain/usecases/get_page_for_ayah.dart';
import 'package:islami/features/quran/domain/usecases/get_reading_progress.dart';
import 'package:islami/features/quran/domain/usecases/get_recent_suras.dart';
import 'package:islami/features/quran/domain/usecases/get_sura_info.dart';
import 'package:islami/features/quran/domain/usecases/save_reading_progress.dart';
import 'package:islami/features/quran/presentation/bloc/mushaf/mushaf_reader_bloc.dart';
import 'package:islami/features/quran/presentation/bloc/quran_bloc.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Exactly what 1.0.1+2 left in SharedPreferences after reading 2:283, 3:11
/// and 4:176: its ReadingProgressModel.toJson() under `reading_progress`
/// (0-based `ayahIndex`), and the recents as strings, most recent first.
Map<String, Object> savedBy101() => {
  'recent_sura_ids': ['4', '3', '2'],
  'reading_progress': json.encode({
    '2': {'ayahIndex': 282, 'updatedAt': '2026-09-29T20:10:00.000'},
    '3': {'ayahIndex': 10, 'updatedAt': '2026-09-29T20:20:00.000'},
    '4': {'ayahIndex': 175, 'updatedAt': '2026-09-29T20:30:00.000'},
  }),
};

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late QuranRepositoryImpl quran;
  late MushafRepositoryImpl mushaf;

  /// A cold start: a fresh SharedPreferences over what is on disk.
  Future<void> launch(Map<String, Object> onDisk) async {
    SharedPreferences.setMockInitialValues(onDisk);
    final prefs = await SharedPreferences.getInstance();
    quran = QuranRepositoryImpl(
      localDataSource: QuranLocalDataSourceImpl(
        sharedPreferences: prefs,
        jsonStore: JsonStore(sharedPreferences: prefs),
      ),
    );
    mushaf = MushafRepositoryImpl(localDataSource: MushafLocalDataSourceImpl());
  }

  MushafReaderBloc reader() => MushafReaderBloc(
    getPage: GetPage(mushaf),
    getPageForAyah: GetPageForAyah(mushaf),
    getSuraInfo: GetSuraInfo(mushaf),
    getJuzStart: GetJuzStart(mushaf),
    getReadingProgress: GetReadingProgress(quran),
    saveReadingProgress: SaveReadingProgress(quran),
    addRecentSura: AddRecentSura(quran),
  );

  test(
    'the first launch shows the saved ayat on the Most Recently cards',
    () async {
      await launch(savedBy101());
      final bloc = QuranBloc(
        getAllSuras: GetAllSuras(quran),
        getRecentSuras: GetRecentSuras(quran),
        addRecentSura: AddRecentSura(quran),
        getReadingProgress: GetReadingProgress(quran),
        suraSearchFilter: DefaultSuraSearchFilter(),
      )..add(const LoadSurasEvent());

      final state = await bloc.stream.firstWhere(
        (s) => s.recentSuras.isNotEmpty,
      );

      expect(state.recentSuras.map((s) => s.id), [4, 3, 2]);
      expect(state.recentProgress[2]?.ayah, 283);
      expect(state.recentProgress[3]?.ayah, 11);
      expect(state.recentProgress[4]?.ayah, 176);
      await bloc.close();
    },
  );

  for (final (sura, ayah, page) in [(2, 283, 49), (3, 11, 51), (4, 176, 106)]) {
    test(
      'the first launch resumes $sura:$ayah on page $page, highlighted',
      () async {
        await launch(savedBy101());
        final bloc = reader()..add(MushafOpenedEvent(sura, resume: true));
        final state = await bloc.stream.firstWhere((s) => s.status.isSuccess);

        expect(state.page, page);
        expect(state.selected, AyahRef(sura, ayah));
        await bloc.close();
      },
    );
  }

  test('resuming does not rewrite the saved position', () async {
    await launch(savedBy101());
    final bloc = reader()..add(const MushafOpenedEvent(2, resume: true));
    await bloc.stream.firstWhere((s) => s.status.isSuccess);
    await bloc.close();

    final progress = (await quran.getProgress(2)).getOrElse(() => null);
    expect(progress?.ayah, 283);
  });

  test('an entry with no usable ayah shows no ayah, never "Ayah 1"', () async {
    await launch({
      'recent_sura_ids': ['2'],
      'reading_progress': json.encode({
        '2': {'updatedAt': '2026-09-29T20:10:00.000'},
        '3': {'ayahIndex': 'ten'},
        '4': {'ayah': 0},
      }),
    });
    for (final sura in [2, 3, 4]) {
      expect((await quran.getProgress(sura)).getOrElse(() => null), isNull);
    }
  });
}
