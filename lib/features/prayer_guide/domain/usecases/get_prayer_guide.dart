import 'package:dartz/dartz.dart';

import '../../../../core/error/failures.dart';
import '../../../../core/usecase/usecase.dart';
import '../entities/prayer_guide.dart';
import '../repositories/prayer_guide_repository.dart';

class GetPrayerGuide implements UseCase<PrayerGuide, NoParams> {
  final PrayerGuideRepository repository;

  GetPrayerGuide(this.repository);

  @override
  Future<Either<Failure, PrayerGuide>> call(NoParams params) {
    return repository.getPrayerGuide();
  }
}
