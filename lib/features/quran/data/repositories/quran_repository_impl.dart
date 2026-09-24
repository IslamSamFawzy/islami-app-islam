import 'package:dartz/dartz.dart';

import '../../../../core/data/guard.dart';
import '../../../../core/error/failures.dart';
import '../../domain/entities/reading_progress.dart';
import '../../domain/entities/sura.dart';
import '../../domain/repositories/quran_repository.dart';
import '../datasources/quran_local_data_source.dart';
import '../models/reading_progress_model.dart';

class QuranRepositoryImpl implements QuranRepository {
  final QuranLocalDataSource localDataSource;

  QuranRepositoryImpl({required this.localDataSource});

  @override
  Future<Either<Failure, List<Sura>>> getAllSuras() {
    return guardLocalData(localDataSource.getAllSuras);
  }

  @override
  Future<Either<Failure, List<String>>> getSuraVerses(int suraId) {
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
  Future<Either<Failure, Unit>> addRecentSura(int suraId) {
    return guardLocalData(() async {
      await localDataSource.addRecentSuraId(suraId);
      return unit;
    });
  }

  @override
  Future<Either<Failure, ReadingProgress?>> getProgress(int suraId) {
    return guardLocalData(() => localDataSource.getProgress(suraId));
  }

  @override
  Future<Either<Failure, Unit>> saveProgress(ReadingProgress progress) {
    return guardLocalData(() async {
      await localDataSource.saveProgress(
        ReadingProgressModel(
          suraId: progress.suraId,
          ayahIndex: progress.ayahIndex,
          updatedAt: progress.updatedAt,
        ),
      );
      return unit;
    });
  }
}
