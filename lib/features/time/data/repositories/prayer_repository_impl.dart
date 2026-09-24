import 'package:dartz/dartz.dart';

import '../../../../core/cache/cache_result.dart';
import '../../../../core/error/exceptions.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/services/location_service.dart';
import '../../domain/entities/prayer_times.dart';
import '../../domain/repositories/prayer_repository.dart';
import '../datasources/prayer_local_data_source.dart';
import '../datasources/prayer_remote_data_source.dart';
import '../models/prayer_times_model.dart';

class PrayerRepositoryImpl implements PrayerRepository {
  final PrayerRemoteDataSource remoteDataSource;
  final PrayerLocalDataSource localDataSource;
  final LocationService locationService;

  PrayerRepositoryImpl({
    required this.remoteDataSource,
    required this.localDataSource,
    required this.locationService,
  });

  // Fallback coordinates (Cairo) when location is unavailable/denied.
  static const double _fallbackLat = 30.0444;
  static const double _fallbackLng = 31.2357;

  @override
  Future<Either<Failure, CacheResult<PrayerTimes>>> getPrayerTimes() async {
    final (latitude, longitude) = await _coordinates();

    final now = DateTime.now();
    final key = _monthKey(latitude, longitude, now);

    // Serve today's entry straight from a cached month — zero network calls
    // for the rest of the month.
    final cached = localDataSource.getCachedMonth(key);
    if (cached != null) {
      final today = _pickToday(cached, now);
      if (today != null) {
        return Right(CacheResult(today, fromCache: true));
      }
    }

    // Not cached yet (first run, a new month, or moved > ~1 km) — download the
    // whole month once.
    try {
      final month = await remoteDataSource.getMonthlyPrayerTimes(
        latitude: latitude,
        longitude: longitude,
        month: now.month,
        year: now.year,
      );
      await localDataSource.cacheMonth(key, month);
      final today = _pickToday(month, now);
      if (today != null) {
        return Right(CacheResult(today, fromCache: false));
      }
      return const Left(
        ServerFailure('No prayer times were returned for today.'),
      );
    } on ServerException {
      // Offline (or the API failed) and this month has not been saved yet.
      return const Left(
        CacheFailure(
          "You're offline and this month's prayer times haven't been saved "
          'yet. Connect to the internet once to download them.',
        ),
      );
    }
  }

  @override
  Future<Either<Failure, List<PrayerTimes>>> getUpcomingDays() async {
    final (latitude, longitude) = await _coordinates();
    final now = DateTime.now();

    final days = <PrayerTimesModel>[
      ...?localDataSource.getCachedMonth(_monthKey(latitude, longitude, now)),
      // Next month is only there once it has been prefetched; without it the
      // alarms simply run out at the end of this month.
      ...?localDataSource.getCachedMonth(
        _monthKey(latitude, longitude, _nextMonth(now)),
      ),
    ];

    return Right(
      days.where((day) => day.prayers.any((p) => p.time.isAfter(now))).toList(),
    );
  }

  @override
  Future<Either<Failure, Unit>> prefetchNextMonth() async {
    final (latitude, longitude) = await _coordinates();
    final next = _nextMonth(DateTime.now());
    final key = _monthKey(latitude, longitude, next);

    if (localDataSource.getCachedMonth(key) != null) return const Right(unit);

    try {
      final month = await remoteDataSource.getMonthlyPrayerTimes(
        latitude: latitude,
        longitude: longitude,
        month: next.month,
        year: next.year,
      );
      await localDataSource.cacheMonth(key, month);
      return const Right(unit);
    } on ServerException catch (e) {
      // Nothing is lost: the alarms keep this month's instants and the app
      // tries again next time it is opened online.
      return Left(ServerFailure(e.message));
    }
  }

  /// The device's coordinates, or Cairo when they cannot be had.
  Future<(double, double)> _coordinates() async {
    try {
      final position = await locationService.getCurrentPosition();
      return (position.latitude, position.longitude);
    } on LocationException {
      return (_fallbackLat, _fallbackLng);
    }
  }

  DateTime _nextMonth(DateTime from) => DateTime(from.year, from.month + 1);

  /// Cache key: rounded coordinates (2 dp ≈ 1.1 km) + `YYYY-MM`. Moving more
  /// than ~1 km or crossing into a new month produces a new key, which forces
  /// a refetch on the next load.
  String _monthKey(double lat, double lng, DateTime when) {
    final la = lat.toStringAsFixed(2);
    final ln = lng.toStringAsFixed(2);
    final mm = when.month.toString().padLeft(2, '0');
    return 'prayer_month_${la}_${ln}_${when.year}-$mm';
  }

  /// Finds the cached entry whose Gregorian date matches [now].
  PrayerTimesModel? _pickToday(List<PrayerTimesModel> month, DateTime now) {
    for (final day in month) {
      if (day.prayers.isEmpty) continue;
      final date = day.prayers.first.time;
      if (date.year == now.year &&
          date.month == now.month &&
          date.day == now.day) {
        return day;
      }
    }
    return null;
  }
}
