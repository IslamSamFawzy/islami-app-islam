import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:islami/core/cache/json_store.dart';
import 'package:islami/features/quran/data/datasources/mushaf_local_data_source.dart';
import 'package:islami/features/quran/data/datasources/quran_local_data_source.dart';
import 'package:islami/features/quran/data/models/reading_progress_model.dart';
import 'package:islami/features/quran/data/repositories/mushaf_repository_impl.dart';
import 'package:islami/features/quran/domain/entities/ayah_ref.dart';
import 'package:islami/features/quran/domain/usecases/get_page_for_ayah.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late SharedPreferences prefs;
  late QuranLocalDataSourceImpl ds;

  Future<void> build([Map<String, Object> initial = const {}]) async {
    SharedPreferences.setMockInitialValues(initial);
    prefs = await SharedPreferences.getInstance();
    ds = QuranLocalDataSourceImpl(
      sharedPreferences: prefs,
      jsonStore: JsonStore(sharedPreferences: prefs),
    );
  }

  setUp(() => build());

  test('the sura list carries numbers, not strings', () async {
    final suras = await ds.getAllSuras();

    expect(suras.length, 114);
    expect(suras.first.id, 1);
    expect(suras.first.ayaCount, 7);
    expect(suras.last.id, 114);
  });

  test('recents keep their stored string form, newest first', () async {
    await ds.addRecentSuraId(2);
    await ds.addRecentSuraId(36);

    // The on-disk shape is unchanged, so an update does not lose anyone's
    // recents.
    expect(prefs.getStringList('recent_sura_ids'), ['36', '2']);
    expect(await ds.getRecentSuraIds(), [36, 2]);
  });

  test('re-reading a sura moves it to the front without duplicating', () async {
    await ds.addRecentSuraId(2);
    await ds.addRecentSuraId(36);
    await ds.addRecentSuraId(2);

    expect(await ds.getRecentSuraIds(), [2, 36]);
  });

  test('recents are capped at ten', () async {
    for (var i = 1; i <= 12; i++) {
      await ds.addRecentSuraId(i);
    }

    final recents = await ds.getRecentSuraIds();
    expect(recents.length, 10);
    expect(recents.first, 12);
  });

  group('reading progress', () {
    test('round-trips under its own key, leaving recents alone', () async {
      await ds.addRecentSuraId(2);
      await ds.saveProgress(
        ReadingProgressModel(
          suraId: 2,
          ayah: 42,
          updatedAt: DateTime(2026, 9, 24, 8),
        ),
      );

      final progress = await ds.getProgress(2);
      expect(progress?.ayah, 42);
      expect(progress?.updatedAt, DateTime(2026, 9, 24, 8));

      // Its own key; the recents list is untouched.
      expect(prefs.getString('reading_progress'), isNotNull);
      expect(prefs.getStringList('recent_sura_ids'), ['2']);
    });

    test('keeps one entry per sura', () async {
      await ds.saveProgress(
        ReadingProgressModel(
          suraId: 2,
          ayah: 6,
          updatedAt: DateTime(2026),
        ),
      );
      await ds.saveProgress(
        ReadingProgressModel(
          suraId: 36,
          ayah: 10,
          updatedAt: DateTime(2026),
        ),
      );
      await ds.saveProgress(
        ReadingProgressModel(
          suraId: 2,
          ayah: 8,
          updatedAt: DateTime(2026),
        ),
      );

      expect((await ds.getProgress(2))?.ayah, 8);
      expect((await ds.getProgress(36))?.ayah, 10);
    });

    test('a sura never read has none', () async {
      expect(await ds.getProgress(114), isNull);
    });

    test('an unreadable entry reads as none, not a crash', () async {
      await build({
        'reading_progress': json.encode({'2': 'nonsense'}),
      });

      expect(await ds.getProgress(2), isNull);
    });
  });

  group('progress saved by 1.0.1 and earlier', () {
    // Those versions stored the 0-based index of the ayah in the old list.
    test('reads as the ayah after its index', () async {
      await build({
        'reading_progress': json.encode({
          '2': {'ayahIndex': 41, 'updatedAt': '2026-09-24T08:00:00.000'},
          '18': {'ayahIndex': 0, 'updatedAt': '2026-09-24T08:00:00.000'},
        }),
      });

      expect((await ds.getProgress(2))?.ayah, 42);
      expect((await ds.getProgress(18))?.ayah, 1);
      expect((await ds.getProgress(2))?.updatedAt, DateTime(2026, 9, 24, 8));
    });

    test('is written in the new form on the next save', () async {
      await build({
        'reading_progress': json.encode({
          '2': {'ayahIndex': 41, 'updatedAt': '2026-09-24T08:00:00.000'},
        }),
      });

      await ds.saveProgress(await ds.getProgress(2) as ReadingProgressModel);

      final stored =
          json.decode(prefs.getString('reading_progress')!) as Map;
      expect(stored['2'], {'ayah': 42, 'updatedAt': '2026-09-24T08:00:00.000'});
    });

    test('resumes on the Mushaf page of that ayah', () async {
      await build({
        'reading_progress': json.encode({
          '2': {'ayahIndex': 41, 'updatedAt': '2026-09-24T08:00:00.000'},
          '18': {'ayahIndex': 0, 'updatedAt': '2026-09-24T08:00:00.000'},
          '114': {'ayahIndex': 5, 'updatedAt': '2026-09-24T08:00:00.000'},
        }),
      });
      final pageFor = GetPageForAyah(
        MushafRepositoryImpl(localDataSource: MushafLocalDataSourceImpl()),
      );

      Future<int?> resumePage(int sura) async {
        final progress = await ds.getProgress(sura);
        final page = await pageFor(AyahRef(sura, progress!.ayah));
        return page.fold((_) => null, (p) => p);
      }

      expect(await resumePage(2), 7); // 2:42
      expect(await resumePage(18), 293); // 18:1
      expect(await resumePage(114), 604); // 114:6
    });
  });

  test('a list written by an older version still reads', () async {
    await build({
      'recent_sura_ids': ['18', 'not-a-number', '2'],
    });

    expect(await ds.getRecentSuraIds(), [18, 2]);
  });
}
