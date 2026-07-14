import 'package:dartz/dartz.dart';

import '../../../../core/cache/cache_result.dart';
import '../../../../core/error/failures.dart';
import '../entities/prayer_times.dart';

abstract class PrayerRepository {
  /// Resolves the device location (with a Cairo fallback) and returns today's
  /// prayer times.
  ///
  /// The whole month is cached under a key derived from the rounded coordinates
  /// and `YYYY-MM`, so once a month has been downloaded, today's schedule is a
  /// pure cache lookup. When offline and the month has not been cached yet, a
  /// [CacheFailure] with a user-facing message is returned. The [CacheResult]
  /// reports whether the data came from cache.
  Future<Either<Failure, CacheResult<PrayerTimes>>> getPrayerTimes();
}
