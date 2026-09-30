import 'dart:convert';
import 'dart:io';

import 'package:dartz/dartz.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:islami/core/error/failures.dart';
import 'package:islami/features/quran/data/datasources/mushaf_local_data_source.dart';
import 'package:islami/features/quran/data/repositories/mushaf_repository_impl.dart';
import 'package:islami/features/quran/domain/entities/ayah.dart';
import 'package:islami/features/quran/domain/entities/mushaf_page.dart';
import 'package:islami/features/quran/domain/entities/sura_info.dart';

/// A bundle with nothing in it.
class _EmptyBundle extends CachingAssetBundle {
  @override
  Future<ByteData> load(String key) => Future.error(StateError('no $key'));
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late MushafLocalDataSourceImpl source;
  late MushafRepositoryImpl repo;

  setUp(() {
    source = MushafLocalDataSourceImpl();
    repo = MushafRepositoryImpl(localDataSource: source);
  });

  T right<T>(Either<Failure, T> either) =>
      either.fold((f) => fail('unexpected $f'), (v) => v);

  test('page 1: Al-Fatiha, 8 lines, header then seven ayat', () async {
    final page = right<MushafPage>(await repo.getPage(1));
    expect(page.lines, hasLength(8));
    expect(page.lines.first, const SuraHeaderLine(1));
    expect(page.lines.whereType<BasmalaLine>(), isEmpty);
    expect(
      page.words.where((w) => w.kind == MushafWordKind.ayahEnd),
      hasLength(7),
    );
    expect((page.juz, page.hizb, page.quarter), (1, 1, 1));
  });

  test('page 2: Al-Baqarah header, basmala, then 2:1', () async {
    final page = right<MushafPage>(await repo.getPage(2));
    expect(page.lines[0], const SuraHeaderLine(2));
    expect(page.lines[1], isA<BasmalaLine>());
    final first = page.words.first;
    expect((first.sura, first.ayah, first.index), (2, 1, 0));
  });

  test('a full page has 15 lines and ends at the right word', () async {
    final page = right<MushafPage>(await repo.getPage(293));
    expect(page.lines, hasLength(15));
    expect(page.words.any((w) => w.sura == 18 && w.ayah == 1), isTrue);
  });

  test('ayah lookups: page, juz, hizb, sajdah', () async {
    expect(right<Ayah>(await repo.getAyah(18, 1)).page, 293);
    expect(right<Ayah>(await repo.getAyah(114, 1)).page, 604);
    expect(right<Ayah>(await repo.getAyah(22, 77)).sajdah, Sajdah.recommended);
    expect(right<Ayah>(await repo.getAyah(32, 15)).sajdah, Sajdah.obligatory);
    expect(right<Ayah>(await repo.getAyah(2, 1)).sajdah, Sajdah.none);
    final last = right<Ayah>(await repo.getAyah(114, 6));
    expect((last.juz, last.hizb, last.quarter), (30, 60, 240));
  });

  test('sura info: An-Nisa opens on page 77 and is Madani', () async {
    final info = right<SuraInfo>(await repo.getSuraInfo(4));
    expect(info.firstPage, 77);
    expect(info.ayahCount, 176);
    expect(info.revelation, Revelation.madani);
    expect(
      right<SuraInfo>(await repo.getSuraInfo(96)).revelation,
      Revelation.makki,
    );
  });

  test('juz starts follow the rub signs in the text', () async {
    final juz4 = right<Ayah>(await repo.getJuzStart(4));
    expect((juz4.sura, juz4.number), (3, 93));
    final juz30 = right<Ayah>(await repo.getJuzStart(30));
    expect((juz30.sura, juz30.number, juz30.page), (78, 1, 582));
  });

  test(
    'every ayah text is exactly the KFGQPC source text',
    () async {
      final raw = File(
        'tool/quran_source/kfgqpc/hafsData_v2-0.json',
      ).readAsStringSync().replaceFirst('\uFEFF', '');
      final rows = (jsonDecode(raw) as List).cast<Map<String, dynamic>>();
      final differ = <String>[];
      for (final r in rows) {
        final s = r['sura_no'] as int, a = r['aya_no'] as int;
        final text = right<String>(await repo.getAyahText(s, a));
        if (text != r['aya_text']) differ.add('$s:$a');
      }
      expect(differ, isEmpty);
    },
    timeout: const Timeout(Duration(minutes: 3)),
  );

  test('out-of-range requests fail instead of throwing', () async {
    expect((await repo.getPage(0)).isLeft(), isTrue);
    expect((await repo.getPage(605)).isLeft(), isTrue);
    expect((await repo.getAyah(1, 8)).isLeft(), isTrue);
    expect((await repo.getAyah(115, 1)).isLeft(), isTrue);
    expect((await repo.getSuraInfo(0)).isLeft(), isTrue);
    expect((await repo.getJuzStart(31)).isLeft(), isTrue);
  });

  test('a missing asset is a LocalDataFailure, and is retried', () async {
    final broken = MushafRepositoryImpl(
      localDataSource: MushafLocalDataSourceImpl(bundle: _EmptyBundle()),
    );
    final result = await broken.getPage(1);
    expect(result.fold((f) => f, (_) => null), isA<LocalDataFailure>());
    // Still failing, not stuck on a cached error: it asked again.
    expect((await broken.getAyah(1, 1)).isLeft(), isTrue);
  });

  test('keeps only the most recently used pages', () async {
    final small = MushafLocalDataSourceImpl(cacheSize: 3);
    for (final p in [1, 2, 3, 4]) {
      await small.getPageLines(p);
    }
    expect(small.cachedPages, [2, 3, 4]);
    await small.getPageLines(2); // touch 2
    await small.getPageLines(5);
    expect(small.cachedPages, [4, 2, 5]);
  });

  test('two requests for a page share one load', () async {
    final a = source.getPageLines(50);
    final b = source.getPageLines(50);
    expect(identical(a, b), isTrue);
    expect(await a, await b);
  });
}
