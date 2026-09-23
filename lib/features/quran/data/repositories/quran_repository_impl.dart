import 'package:dartz/dartz.dart';

import '../../../../core/data/guard.dart';
import '../../../../core/error/failures.dart';
import '../../domain/entities/sura.dart';
import '../../domain/repositories/quran_repository.dart';
import '../datasources/quran_local_data_source.dart';

class QuranRepositoryImpl implements QuranRepository {
  final QuranLocalDataSource localDataSource;

  QuranRepositoryImpl({required this.localDataSource});

  @override
  Future<Either<Failure, List<Sura>>> getAllSuras() {
    return guardLocalData(localDataSource.getAllSuras);
  }

  @override
  Future<Either<Failure, List<String>>> getSuraVerses(String suraId) {
    return guardLocalData(() => localDataSource.getSuraVerses(suraId));
  }

  @override
  Future<Either<Failure, List<Sura>>> getRecentSuras() {
    return guardLocalData(() async {
      final recentIds = await localDataSource.getRecentSuraIds();
      final allSuras = await localDataSource.getAllSuras();
      final byId = {for (final sura in allSuras) sura.id: sura};
      // Preserve the recency order; skip any unknown IDs defensively.
      return recentIds.map((id) => byId[id]).whereType<Sura>().toList();
    });
  }

  @override
  Future<Either<Failure, Unit>> addRecentSura(String suraId) {
    return guardLocalData(() async {
      await localDataSource.addRecentSuraId(suraId);
      return unit;
    });
  }
}
