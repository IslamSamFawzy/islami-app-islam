import 'package:flutter_test/flutter_test.dart';
import 'package:islami/core/error/exceptions.dart';
import 'package:islami/core/error/failures.dart';
import 'package:islami/core/services/location_service.dart';
import 'package:islami/features/time/data/datasources/prayer_local_data_source.dart';
import 'package:islami/features/time/data/datasources/prayer_remote_data_source.dart';
import 'package:islami/features/time/data/models/prayer_times_model.dart';
import 'package:islami/features/time/data/repositories/prayer_repository_impl.dart';
import 'package:islami/features/time/domain/entities/prayer_times.dart';

PrayerTimesModel _dayFor(DateTime d) {
  return PrayerTimesModel(
    weekday: 'Day',
    gregorianDate: '${d.day}',
    gregorianYear: '${d.year}',
    hijriDate: 'h',
    hijriYear: '1446',
    prayers: [
      Prayer(name: 'Fajr', time: DateTime(d.year, d.month, d.day, 4, 0)),
      Prayer(name: 'Dhuhr', time: DateTime(d.year, d.month, d.day, 12, 0)),
    ],
  );
}

class _FakeRemote implements PrayerRemoteDataSource {
  List<PrayerTimesModel> month = const [];
  bool throwServer = false;
  int calls = 0;

  @override
  Future<List<PrayerTimesModel>> getMonthlyPrayerTimes({
    required double latitude,
    required double longitude,
    required int month,
    required int year,
  }) async {
    calls++;
    if (throwServer) throw ServerException('down');
    return this.month;
  }
}

class _FakeLocal implements PrayerLocalDataSource {
  List<PrayerTimesModel>? cached;
  List<PrayerTimesModel>? written;

  @override
  Future<void> cacheMonth(String key, List<PrayerTimesModel> month) async {
    written = month;
  }

  @override
  List<PrayerTimesModel>? getCachedMonth(String key) => cached;
}

/// Forces the Cairo fallback so tests don't touch platform location services.
class _FakeLocation implements LocationService {
  @override
  Future<GeoPoint> getCurrentPosition() async {
    throw const LocationPermissionDeniedException();
  }
}

void main() {
  late _FakeRemote remote;
  late _FakeLocal local;
  late PrayerRepositoryImpl repo;

  final now = DateTime.now();

  setUp(() {
    remote = _FakeRemote();
    local = _FakeLocal();
    repo = PrayerRepositoryImpl(
      remoteDataSource: remote,
      localDataSource: local,
      locationService: _FakeLocation(),
    );
  });

  test('serves today from a cached month with no network call', () async {
    local.cached = [
      _dayFor(now.subtract(const Duration(days: 1))),
      _dayFor(now),
      _dayFor(now.add(const Duration(days: 1))),
    ];
    remote.throwServer = true; // would fail if it were hit

    final result = await repo.getPrayerTimes();

    result.fold((_) => fail('expected Right'), (r) {
      expect(r.fromCache, isTrue);
      expect(r.data.prayers.first.time.day, now.day);
    });
    expect(remote.calls, 0);
  });

  test(
    'cache miss downloads the month, caches it, and returns today',
    () async {
      remote.month = [_dayFor(now)];

      final result = await repo.getPrayerTimes();

      result.fold((_) => fail('expected Right'), (r) {
        expect(r.fromCache, isFalse);
        expect(r.data.prayers.first.time.day, now.day);
      });
      expect(local.written, isNotNull);
      expect(remote.calls, 1);
    },
  );

  test('offline with nothing cached returns a CacheFailure', () async {
    remote.throwServer = true;

    final result = await repo.getPrayerTimes();

    expect(result.isLeft(), isTrue);
    result.fold(
      (f) => expect(f, isA<CacheFailure>()),
      (_) => fail('expected Left'),
    );
  });
}
