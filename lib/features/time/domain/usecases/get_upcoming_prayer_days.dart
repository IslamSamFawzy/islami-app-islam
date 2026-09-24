import 'package:dartz/dartz.dart';

import '../../../../core/error/failures.dart';
import '../../../../core/usecase/usecase.dart';
import '../entities/prayer_times.dart';
import '../repositories/prayer_repository.dart';

/// Every downloaded day from now on — what the adhan alarms are armed from.
class GetUpcomingPrayerDays implements UseCase<List<PrayerTimes>, NoParams> {
  final PrayerRepository repository;

  GetUpcomingPrayerDays(this.repository);

  @override
  Future<Either<Failure, List<PrayerTimes>>> call(NoParams params) {
    return repository.getUpcomingDays();
  }
}
