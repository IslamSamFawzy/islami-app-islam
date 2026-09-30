import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:islami/core/error/failures.dart';
import 'package:islami/features/quran/domain/entities/ayah.dart';
import 'package:islami/features/quran/domain/entities/ayah_ref.dart';
import 'package:islami/features/quran/domain/entities/mushaf_page.dart';
import 'package:islami/features/quran/domain/entities/sura_info.dart';
import 'package:islami/features/quran/domain/repositories/mushaf_repository.dart';
import 'package:islami/features/quran/domain/usecases/get_ayah.dart';
import 'package:islami/features/quran/domain/usecases/get_ayah_text.dart';
import 'package:islami/features/quran/domain/usecases/get_juz_start.dart';
import 'package:islami/features/quran/domain/usecases/get_mushaf_page.dart';
import 'package:islami/features/quran/domain/usecases/get_page_for_ayah.dart';
import 'package:islami/features/quran/domain/usecases/get_sura_info.dart';

const _ayah = Ayah(
  sura: 18,
  number: 1,
  page: 293,
  juz: 15,
  hizb: 30,
  quarter: 117,
  sajdah: Sajdah.none,
);

class _FakeRepository implements MushafRepository {
  final calls = <String>[];

  @override
  Future<Either<Failure, MushafPage>> getPage(int number) async {
    calls.add('page $number');
    return Right(
      MushafPage(number: number, lines: const [], juz: 1, hizb: 1, quarter: 1),
    );
  }

  @override
  Future<Either<Failure, Ayah>> getAyah(int sura, int number) async {
    calls.add('ayah $sura:$number');
    if (sura == 0) return const Left(LocalDataFailure('none'));
    return const Right(_ayah);
  }

  @override
  Future<Either<Failure, SuraInfo>> getSuraInfo(int number) async {
    calls.add('sura $number');
    return Right(
      SuraInfo(
        number: number,
        ayahCount: 110,
        firstPage: 293,
        revelation: Revelation.makki,
      ),
    );
  }

  @override
  Future<Either<Failure, Ayah>> getJuzStart(int number) async {
    calls.add('juz $number');
    return const Right(_ayah);
  }

  @override
  Future<Either<Failure, String>> getAyahText(int sura, int number) async {
    calls.add('text $sura:$number');
    return const Right('text');
  }
}

void main() {
  late _FakeRepository repo;

  setUp(() => repo = _FakeRepository());

  test('each use case asks the repository for what it names', () async {
    await GetPage(repo)(50);
    await GetAyah(repo)(const AyahRef(18, 1));
    await GetSuraInfo(repo)(18);
    await GetJuzStart(repo)(15);
    await GetAyahText(repo)(const AyahRef(1, 1));
    expect(repo.calls, [
      'page 50',
      'ayah 18:1',
      'sura 18',
      'juz 15',
      'text 1:1',
    ]);
  });

  test('GetPageForAyah answers with the page the ayah starts on', () async {
    expect(
      await GetPageForAyah(repo)(const AyahRef(18, 1)),
      const Right<Failure, int>(293),
    );
  });

  test('GetPageForAyah passes a failure through', () async {
    final result = await GetPageForAyah(repo)(const AyahRef(0, 1));
    expect(result, const Left<Failure, int>(LocalDataFailure('none')));
  });
}
