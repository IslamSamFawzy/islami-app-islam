import 'package:dartz/dartz.dart';

import '../../../../core/error/failures.dart';
import '../entities/prayer_guide.dart';

abstract class PrayerGuideRepository {
  /// Returns the bundled prayer guide content.
  Future<Either<Failure, PrayerGuide>> getPrayerGuide();
}
