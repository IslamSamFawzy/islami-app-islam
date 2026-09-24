import 'package:dartz/dartz.dart';

import '../../../../core/error/failures.dart';
import '../../../../core/usecase/usecase.dart';
import '../repositories/prayer_repository.dart';

/// Downloads next month's prayer times so the alarms do not run out at the
/// turn of the month. Does nothing if it is already cached.
class PrefetchNextMonth implements UseCase<Unit, NoParams> {
  final PrayerRepository repository;

  PrefetchNextMonth(this.repository);

  @override
  Future<Either<Failure, Unit>> call(NoParams params) {
    return repository.prefetchNextMonth();
  }
}
