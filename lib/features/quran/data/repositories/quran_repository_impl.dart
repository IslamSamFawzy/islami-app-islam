import 'package:dartz/dartz.dart';

import '../../../../core/error/exceptions.dart';
import '../../../../core/error/failures.dart';
import '../../domain/entities/sura.dart';
import '../../domain/repositories/quran_repository.dart';
import '../datasources/quran_local_data_source.dart';

class QuranRepositoryImpl implements QuranRepository {
  final QuranLocalDataSource localDataSource;

  QuranRepositoryImpl({required this.localDataSource});

  @override
  Future<Either<Failure, List<Sura>>> getAllSuras() async {
    try {
      final suras = await localDataSource.getAllSuras();
      return Right(suras);
    } on LocalDataException catch (e) {
      return Left(LocalDataFailure(e.message));
    }
  }

  @override
  Future<Either<Failure, List<String>>> getSuraVerses(String suraId) async {
    try {
      final verses = await localDataSource.getSuraVerses(suraId);
      return Right(verses);
    } on LocalDataException catch (e) {
      return Left(LocalDataFailure(e.message));
    }
  }

  @override
  Future<Either<Failure, List<Sura>>> getRecentSuras() async {
    try {
      final recentIds = await localDataSource.getRecentSuraIds();
      final allSuras = await localDataSource.getAllSuras();
      final byId = {for (final sura in allSuras) sura.id: sura};
      // Preserve the recency order; skip any unknown IDs defensively.
      final recent = recentIds
          .map((id) => byId[id])
          .whereType<Sura>()
          .toList();
      return Right(recent);
    } on LocalDataException catch (e) {
      return Left(LocalDataFailure(e.message));
    }
  }

  @override
  Future<Either<Failure, Unit>> addRecentSura(String suraId) async {
    try {
      await localDataSource.addRecentSuraId(suraId);
      return const Right(unit);
    } on LocalDataException catch (e) {
      return Left(LocalDataFailure(e.message));
    }
  }
}
