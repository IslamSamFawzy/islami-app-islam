import 'package:dartz/dartz.dart';

import '../../../../core/cache/cache_result.dart';
import '../../../../core/error/exceptions.dart';
import '../../../../core/error/failures.dart';
import '../../domain/entities/radio_station.dart';
import '../../domain/entities/reciter.dart';
import '../../domain/repositories/radio_repository.dart';
import '../datasources/radio_local_data_source.dart';
import '../datasources/radio_remote_data_source.dart';
import '../models/radio_station_model.dart';
import '../models/reciter_model.dart';

class RadioRepositoryImpl implements RadioRepository {
  final RadioRemoteDataSource remoteDataSource;
  final RadioLocalDataSource localDataSource;

  RadioRepositoryImpl({
    required this.remoteDataSource,
    required this.localDataSource,
  });

  @override
  Future<Either<Failure, CacheResult<List<RadioStation>>>> getRadios({
    bool forceRefresh = false,
  }) {
    return _load<RadioStationModel>(
      forceRefresh: forceRefresh,
      readCache: localDataSource.getCachedRadios,
      fetch: remoteDataSource.getRadios,
      writeCache: localDataSource.cacheRadios,
    );
  }

  @override
  Future<Either<Failure, CacheResult<List<Reciter>>>> getReciters({
    bool forceRefresh = false,
  }) {
    return _load<ReciterModel>(
      forceRefresh: forceRefresh,
      readCache: localDataSource.getCachedReciters,
      fetch: remoteDataSource.getReciters,
      writeCache: localDataSource.cacheReciters,
    );
  }

  /// Cache-first / network-refresh policy shared by radios and reciters:
  ///
  /// * `forceRefresh == false` → return the cache if present.
  /// * otherwise fetch the network, overwrite the cache and return the fresh
  ///   list; on a [ServerException] fall back to the cache if one exists, or
  ///   surface a [ServerFailure] when there is nothing cached.
  Future<Either<Failure, CacheResult<List<M>>>> _load<M>({
    required bool forceRefresh,
    required List<M>? Function() readCache,
    required Future<List<M>> Function() fetch,
    required Future<void> Function(List<M>) writeCache,
  }) async {
    if (!forceRefresh) {
      final cached = readCache();
      if (cached != null) {
        return Right(CacheResult(cached, fromCache: true));
      }
      // No usable cache — fall through so first-time users still get data.
    }
    try {
      final fresh = await fetch();
      await writeCache(fresh);
      return Right(CacheResult(fresh, fromCache: false));
    } on ServerException catch (e) {
      final cached = readCache();
      if (cached != null) {
        return Right(CacheResult(cached, fromCache: true));
      }
      return Left(ServerFailure(e.message));
    }
  }
}
