import 'package:dartz/dartz.dart';

import '../../../../core/error/failures.dart';
import '../../../../core/services/download_service.dart';
import '../../domain/entities/download_entry.dart';
import '../../domain/entities/download_key.dart';
import '../../domain/repositories/downloads_repository.dart';
import '../datasources/downloads_local_data_source.dart';
import '../models/download_entry_model.dart';

/// Keeps the index ([DownloadsLocalDataSource]) and the files
/// ([DownloadService]) in step: an entry without a file is not a download.
class DownloadsRepositoryImpl implements DownloadsRepository {
  final DownloadsLocalDataSource localDataSource;
  final DownloadService downloadService;

  DownloadsRepositoryImpl({
    required this.localDataSource,
    required this.downloadService,
  });

  @override
  Future<Either<Failure, List<DownloadEntry>>> getDownloads() {
    return _guard<List<DownloadEntry>>(() async => localDataSource.getAll());
  }

  @override
  Future<Either<Failure, List<DownloadEntry>>> reconcile() {
    return _guard<List<DownloadEntry>>(() async {
      final surviving = <DownloadEntry>[];
      for (final entry in localDataSource.getAll()) {
        if (await downloadService.pathExists(entry.path)) {
          surviving.add(entry);
        } else {
          await localDataSource.remove(entry.key);
        }
      }
      return surviving;
    });
  }

  @override
  Future<Either<Failure, Unit>> save(DownloadEntry entry) {
    return _guard(() async {
      await localDataSource.put(DownloadEntryModel.fromEntry(entry));
      return unit;
    });
  }

  @override
  Future<Either<Failure, Unit>> delete(DownloadKey key) {
    return _guard(() async {
      await downloadService.delete(key.reciterId, key.suraId);
      await localDataSource.remove(key);
      return unit;
    });
  }

  @override
  Future<Either<Failure, Unit>> deleteReciter(String reciterId) {
    return _guard(() async {
      await downloadService.deleteReciter(reciterId);
      await localDataSource.removeReciter(reciterId);
      return unit;
    });
  }

  @override
  Future<Either<Failure, String?>> findDownloadedFile(DownloadKey key) {
    return _guard(() async {
      final entry = localDataSource.get(key);
      if (entry == null) return null;
      return await downloadService.pathExists(entry.path) ? entry.path : null;
    });
  }

  /// Stored preferences and the file system can both throw; callers get a
  /// [Failure] instead of an exception crossing out of the data layer.
  Future<Either<Failure, T>> _guard<T>(Future<T> Function() action) async {
    try {
      return Right(await action());
    } on Exception catch (e) {
      return Left(CacheFailure('Downloads storage failed: $e'));
    }
  }
}
