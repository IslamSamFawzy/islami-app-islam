import 'package:dartz/dartz.dart';

import '../../../../core/cache/cache_result.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/usecase/usecase.dart';
import '../entities/prayer_times.dart';
import '../repositories/prayer_repository.dart';

class GetPrayerTimes
    implements UseCase<CacheResult<PrayerTimes>, NoParams> {
  final PrayerRepository repository;

  GetPrayerTimes(this.repository);

  @override
  Future<Either<Failure, CacheResult<PrayerTimes>>> call(NoParams params) {
    return repository.getPrayerTimes();
  }
}
