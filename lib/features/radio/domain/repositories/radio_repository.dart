import 'package:dartz/dartz.dart';

import '../../../../core/cache/cache_result.dart';
import '../../../../core/error/failures.dart';
import '../entities/radio_station.dart';
import '../entities/reciter.dart';

abstract class RadioRepository {
  /// Returns radios. When [forceRefresh] is false the cache is preferred (and
  /// returned immediately when present); otherwise the network is hit and the
  /// cache overwritten. On a network error a cache falls back rather than
  /// failing. The [CacheResult] reports whether the data came from cache.
  Future<Either<Failure, CacheResult<List<RadioStation>>>> getRadios({
    bool forceRefresh = false,
  });

  Future<Either<Failure, CacheResult<List<Reciter>>>> getReciters({
    bool forceRefresh = false,
  });
}
