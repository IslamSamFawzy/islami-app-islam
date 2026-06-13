import 'package:dartz/dartz.dart';

import '../../../../core/error/exceptions.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/services/location_service.dart';
import '../../domain/entities/prayer_times.dart';
import '../../domain/repositories/prayer_repository.dart';
import '../datasources/prayer_remote_data_source.dart';

class PrayerRepositoryImpl implements PrayerRepository {
  final PrayerRemoteDataSource remoteDataSource;
  final LocationService locationService;

  PrayerRepositoryImpl({
    required this.remoteDataSource,
    required this.locationService,
  });

  // Fallback coordinates (Cairo) when location is unavailable/denied.
  static const double _fallbackLat = 30.0444;
  static const double _fallbackLng = 31.2357;

  @override
  Future<Either<Failure, PrayerTimes>> getPrayerTimes() async {
    double latitude = _fallbackLat;
    double longitude = _fallbackLng;

    try {
      final position = await locationService.getCurrentPosition();
      latitude = position.latitude;
      longitude = position.longitude;
    } on LocationException {
      // Keep fallback coordinates.
    }

    try {
      final times = await remoteDataSource.getPrayerTimes(
        latitude: latitude,
        longitude: longitude,
      );
      return Right(times);
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    }
  }
}
