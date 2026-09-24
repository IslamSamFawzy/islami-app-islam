import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:islami/core/error/failures.dart';
import 'package:islami/features/quran/domain/entities/reading_progress.dart';
import 'package:islami/features/quran/domain/entities/sura.dart';
import 'package:islami/features/quran/domain/repositories/quran_repository.dart';
import 'package:islami/features/quran/domain/services/sura_search_filter.dart';
import 'package:islami/features/quran/domain/usecases/add_recent_sura.dart';
import 'package:islami/features/quran/domain/usecases/get_all_suras.dart';
import 'package:islami/features/quran/domain/usecases/get_reading_progress.dart';
import 'package:islami/features/quran/domain/usecases/get_recent_suras.dart';
import 'package:islami/features/quran/presentation/bloc/quran_bloc.dart';

const _fatiha = Sura(id: 1, nameEn: 'Al-Fatiha', nameAr: 'الفاتحه', ayaCount: 7);
const _baqarah = Sura(
  id: 2,
  nameEn: 'Al-Baqarah',
  nameAr: 'البقرة',
  ayaCount: 286,
);

class _FakeRepository implements QuranRepository {
  List<Sura> recents = const [];
  final Map<int, ReadingProgress> progress = {};

  @override
  Future<Either<Failure, List<Sura>>> getAllSuras() async =>
      const Right([_fatiha, _baqarah]);

  @override
  Future<Either<Failure, List<Sura>>> getRecentSuras() async => Right(recents);

  @override
  Future<Either<Failure, ReadingProgress?>> getProgress(int suraId) async =>
      Right(progress[suraId]);

  @override
  Future<Either<Failure, Unit>> addRecentSura(int suraId) async =>
      const Right(unit);
  @override
  Future<Either<Failure, Unit>> saveProgress(ReadingProgress p) async =>
      const Right(unit);
  @override
  Future<Either<Failure, List<String>>> getSuraVerses(int suraId) async =>
      const Right([]);
}

void main() {
  late _FakeRepository repository;

  QuranBloc build() => QuranBloc(
    getAllSuras: GetAllSuras(repository),
    getRecentSuras: GetRecentSuras(repository),
    addRecentSura: AddRecentSura(repository),
    getReadingProgress: GetReadingProgress(repository),
    suraSearchFilter: DefaultSuraSearchFilter(),
  );

  setUp(() => repository = _FakeRepository());

  test('recents carry how far the reader got, where there is progress',
      () async {
    repository.recents = const [_baqarah, _fatiha];
    repository.progress[2] = ReadingProgress(
      suraId: 2,
      ayahIndex: 41,
      updatedAt: DateTime(2026),
    );
    final bloc = build();

    bloc.add(const LoadSurasEvent());
    final state = await bloc.stream.firstWhere(
      (s) => s.recentSuras.isNotEmpty,
    );

    expect(state.recentSuras, [_baqarah, _fatiha]);
    expect(state.recentProgress[2]?.ayahNumber, 42);
    expect(state.recentProgress.containsKey(1), isFalse);
    await bloc.close();
  });

  test('recents keep their order', () async {
    repository.recents = const [_fatiha, _baqarah];
    final bloc = build();

    bloc.add(const LoadSurasEvent());
    final state = await bloc.stream.firstWhere((s) => s.recentSuras.isNotEmpty);

    expect(state.recentSuras.map((s) => s.id), [1, 2]);
    await bloc.close();
  });
}
