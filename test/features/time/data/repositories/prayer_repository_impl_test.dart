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
  final Map<String, List<PrayerTimesModel>> months = {};
  final List<String> writtenKeys = [];
  List<PrayerTimesModel>? written;

  @override
  Future<void> cacheMonth(String key, List<PrayerTimesModel> month) async {
    months[key] = month;
    writtenKeys.add(key);
    written = month;
  }

  @override
  List<PrayerTimesModel>? getCachedMonth(String key) => months[key];
}

/// The cache key the repository builds for the Cairo fallback coordinates.
/// Spelled out here because it is a storage contract: change it and every
/// install re-downloads.
String _monthKey(DateTime when) =>
    'prayer_month_30.04_31.24_${when.year}-'
    '${when.month.toString().padLeft(2, '0')}';

/// Forces the Cairo fallback so tests don't touch platform location services.
class _FakeLocation implements LocationService {
  final LocationException error;

  const _FakeLocation([this.error = const LocationPermissionDeniedException()]);

  @override
  Future<GeoPoint> getCurrentPosition() async {
    throw error;
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

  test('a location timeout falls back to Cairo instead of throwing', () async {
    // The service now gives up after 15s rather than hanging; the repository
    // must treat that like any other missing location.
    repo = PrayerRepositoryImpl(
      remoteDataSource: remote,
      localDataSource: local,
      locationService: const _FakeLocation(LocationTimeoutException()),
    );
    remote.month = [_dayFor(now)];

    final result = await repo.getPrayerTimes();

    result.fold((f) => fail('expected Right, got $f'), (r) {
      expect(r.data.prayers.first.time.day, now.day);
    });
    // Cairo's key: proof the fallback coordinates were used.
    expect(local.writtenKeys, [_monthKey(now)]);
  });

  test('serves today from a cached month with no network call', () async {
    local.months[_monthKey(now)] = [
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

  group('getUpcomingDays', () {
    final nextMonth = DateTime(now.year, now.month + 1);

    test('returns the rest of this month, yesterday dropped', () async {
      local.months[_monthKey(now)] = [
        _dayFor(now.subtract(const Duration(days: 1))),
        _dayFor(now),
        _dayFor(now.add(const Duration(days: 1))),
      ];

      final days = (await repo.getUpcomingDays()).getOrElse(() => []);

      // Today counts while any of its prayers is still ahead; this fixture's
      // day is 04:00/12:00, so it depends on the clock — the day after is
      // always there, and yesterday never is.
      expect(days.length, inInclusiveRange(1, 2));
      expect(
        days.every((d) => d.prayers.any((p) => p.time.isAfter(DateTime.now()))),
        isTrue,
      );
    });

    test('adds next month once it has been prefetched', () async {
      local.months[_monthKey(now)] = [_dayFor(now.add(const Duration(days: 1)))];
      local.months[_monthKey(nextMonth)] = [
        _dayFor(DateTime(nextMonth.year, nextMonth.month, 2)),
        _dayFor(DateTime(nextMonth.year, nextMonth.month, 3)),
      ];

      final days = (await repo.getUpcomingDays()).getOrElse(() => []);

      expect(days.length, 3);
    });

    test('is empty, not an error, when nothing is cached', () async {
      expect((await repo.getUpcomingDays()).getOrElse(() => [_dayFor(now)]),
          isEmpty);
      expect(remote.calls, 0);
    });
  });

  group('prefetchNextMonth', () {
    final nextMonth = DateTime(now.year, now.month + 1);

    test('downloads and caches next month under its own key', () async {
      remote.month = [_dayFor(DateTime(nextMonth.year, nextMonth.month, 1))];

      final result = await repo.prefetchNextMonth();

      expect(result.isRight(), isTrue);
      expect(remote.calls, 1);
      expect(local.writtenKeys, [_monthKey(nextMonth)]);
    });

    test('does nothing when next month is already there', () async {
      local.months[_monthKey(nextMonth)] = [_dayFor(nextMonth)];

      await repo.prefetchNextMonth();

      expect(remote.calls, 0);
    });

    test('a failed fetch is reported, not thrown', () async {
      remote.throwServer = true;

      final result = await repo.prefetchNextMonth();

      expect(result.isLeft(), isTrue);
    });
  });
}
