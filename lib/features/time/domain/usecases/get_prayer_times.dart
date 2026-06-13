import 'package:dartz/dartz.dart';

import '../../../../core/error/failures.dart';
import '../../../../core/usecase/usecase.dart';
import '../entities/prayer_times.dart';
import '../repositories/prayer_repository.dart';

class GetPrayerTimes implements UseCase<PrayerTimes, NoParams> {
  final PrayerRepository repository;

  GetPrayerTimes(this.repository);

  @override
  Future<Either<Failure, PrayerTimes>> call(NoParams params) {
    return repository.getPrayerTimes();
  }
}
