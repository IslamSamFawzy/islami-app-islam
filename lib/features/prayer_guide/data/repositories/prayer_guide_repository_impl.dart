import 'package:dartz/dartz.dart';

import '../../../../core/error/exceptions.dart';
import '../../../../core/error/failures.dart';
import '../../domain/entities/prayer_guide.dart';
import '../../domain/repositories/prayer_guide_repository.dart';
import '../datasources/prayer_guide_local_data_source.dart';

class PrayerGuideRepositoryImpl implements PrayerGuideRepository {
  final PrayerGuideLocalDataSource localDataSource;

  PrayerGuideRepositoryImpl({required this.localDataSource});

  @override
  Future<Either<Failure, PrayerGuide>> getPrayerGuide() async {
    try {
      return Right(await localDataSource.getPrayerGuide());
    } on LocalDataException catch (e) {
      return Left(LocalDataFailure(e.message));
    }
  }
}
