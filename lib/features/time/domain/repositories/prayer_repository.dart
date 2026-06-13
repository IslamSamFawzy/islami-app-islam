import 'package:dartz/dartz.dart';

import '../../../../core/error/failures.dart';
import '../entities/prayer_times.dart';

abstract class PrayerRepository {
  /// Resolves the device location (with a sensible fallback) and fetches
  /// today's prayer times for it.
  Future<Either<Failure, PrayerTimes>> getPrayerTimes();
}
