import 'dart:async';

import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:islami/core/cache/cache_result.dart';
import 'package:islami/core/error/failures.dart';
import 'package:islami/core/services/connectivity_service.dart';
import 'package:islami/features/time/domain/entities/adhan_settings.dart';
import 'package:islami/features/time/domain/entities/adhan_schedule.dart';
import 'package:islami/features/time/domain/entities/prayer_name.dart';
import 'package:islami/features/time/domain/entities/prayer_times.dart';
import 'package:islami/features/time/domain/repositories/adhan_settings_repository.dart';
import 'package:islami/features/time/domain/repositories/prayer_repository.dart';
import 'package:islami/features/time/domain/services/adhan_prayer_policy.dart';
import 'package:islami/features/time/domain/services/adhan_scheduler.dart';
import 'package:islami/features/time/domain/services/next_prayer_calculator.dart';
import 'package:islami/features/time/domain/services/notification_permission.dart';
import 'package:islami/features/time/domain/usecases/ensure_adhan_permitted.dart';
import 'package:islami/features/time/domain/usecases/get_prayer_times.dart';
import 'package:islami/features/time/domain/usecases/get_upcoming_prayer_days.dart';
import 'package:islami/features/time/domain/usecases/prefetch_next_month.dart';
import 'package:islami/features/time/domain/usecases/save_adhan_settings.dart';
import 'package:islami/features/time/domain/usecases/watch_adhan_settings.dart';
import 'package:islami/features/time/presentation/bloc/time_bloc.dart';

class _FakeScheduler implements AdhanScheduler {
  final List<List<AdhanSchedule>> scheduled = [];
  int cancels = 0;
  int stops = 0;
  bool exactAllowed = true;
  int exactRequests = 0;

  @override
  Future<void> schedule(List<AdhanSchedule> adhans) async =>
      scheduled.add(adhans);
  @override
  Future<void> cancel() async => cancels++;
  @override
  Future<void> stopNow() async => stops++;
  @override
  Future<bool> canScheduleExactAlarms() async => exactAllowed;
  @override
  Future<void> requestExactAlarms() async => exactRequests++;

  List<String> get lastNames =>
      scheduled.isEmpty ? const [] : scheduled.last.map((a) => a.name).toList();
}

class _FakeSettingsRepository implements AdhanSettingsRepository {
  AdhanSettings settings;
  final _changes = StreamController<AdhanSettings>.broadcast();

  _FakeSettingsRepository(this.settings);

  @override
  Future<Either<Failure, AdhanSettings>> getAdhanSettings() async =>
      Right(settings);

  @override
  Future<Either<Failure, Unit>> saveAdhanSettings(AdhanSettings s) async {
    settings = s;
    _changes.add(s);
    return const Right(unit);
  }

  @override
  Stream<AdhanSettings> watch() => _changes.stream;

  Future<void> dispose() => _changes.close();
}

class _FakePermission implements NotificationPermission {
  bool granted = true;
  int requests = 0;

  @override
  Future<bool> isGranted() async => granted;

  @override
  Future<bool> request() async {
    requests++;
    return granted;
  }
}

class _FakeRepository implements PrayerRepository {
  final PrayerTimes times;

  /// Days the app has downloaded, today first.
  List<PrayerTimes> upcoming;
  int prefetches = 0;

  _FakeRepository(this.times, {List<PrayerTimes>? upcoming})
      : upcoming = upcoming ?? [times];

  @override
  Future<Either<Failure, CacheResult<PrayerTimes>>> getPrayerTimes() async =>
      Right(CacheResult(times, fromCache: true));

  @override
  Future<Either<Failure, List<PrayerTimes>>> getUpcomingDays() async =>
      Right(upcoming);

  @override
  Future<Either<Failure, Unit>> prefetchNextMonth() async {
    prefetches++;
    return const Right(unit);
  }
}

class _FakeConnectivity implements ConnectivityService {
  @override
  Future<bool> get isConnected async => true;
  @override
  Stream<bool> get onConnectivityChanged => const Stream.empty();
}

void main() {
  final now = DateTime.now();

  PrayerTimes day(Duration offset) => PrayerTimes(
        weekday: 'Monday',
        gregorianDate: '24 Sep',
        gregorianYear: '2026',
        hijriDate: '12 Rab',
        hijriYear: '1448',
        prayers: [
          Prayer(name: 'Fajr', time: now.add(offset - const Duration(hours: 4))),
          Prayer(
            name: 'Sunrise',
            time: now.add(offset - const Duration(hours: 3)),
          ),
          Prayer(name: 'Dhuhr', time: now.add(offset + const Duration(hours: 2))),
          Prayer(name: 'Isha', time: now.add(offset + const Duration(hours: 8))),
        ],
      );

  // Today (its Fajr already passed) and tomorrow, as the cache would hold them.
  final times = day(Duration.zero);
  final tomorrow = day(const Duration(days: 1));

  late _FakeScheduler scheduler;
  late _FakeSettingsRepository settings;
  late _FakePermission permission;
  late _FakeRepository prayers;
  late TimeBloc bloc;

  TimeBloc build({DateTime Function()? clock}) {
    return TimeBloc(
      clock: clock ?? DateTime.now,
      getPrayerTimes: GetPrayerTimes(prayers),
      getUpcomingPrayerDays: GetUpcomingPrayerDays(prayers),
      prefetchNextMonth: PrefetchNextMonth(prayers),
      adhanScheduler: scheduler,
      adhanPrayerPolicy: DefaultAdhanPrayerPolicy(),
      nextPrayerCalculator: AdhanNextPrayerCalculator(),
      connectivityService: _FakeConnectivity(),
      ensureAdhanPermitted: EnsureAdhanPermitted(
        repository: settings,
        notificationPermission: permission,
      ),
      saveAdhanSettings: SaveAdhanSettings(settings),
      watchAdhanSettings: WatchAdhanSettings(settings),
    );
  }

  Future<void> load() async {
    bloc.add(const LoadPrayerTimesEvent());
    await bloc.stream.firstWhere((s) => s.prayerTimes != null);
    await pumpEventQueue();
  }

  setUp(() {
    scheduler = _FakeScheduler();
    permission = _FakePermission();
    prayers = _FakeRepository(times, upcoming: [times, tomorrow]);
    settings = _FakeSettingsRepository(AdhanSettings.defaults);
  });

  tearDown(() async {
    await bloc.close();
    await settings.dispose();
  });

  test('arms only the prayers the user has switched on', () async {
    settings.settings = AdhanSettings(
      enabled: true,
      prayers: {PrayerName.fajr, PrayerName.isha},
    );
    bloc = build();

    await load();

    expect(scheduler.lastNames, ['Fajr', 'Isha']);
    expect(bloc.state.muted, isFalse);
  });

  test('sends each prayer its real instants, not one time per day', () async {
    bloc = build();

    await load();

    final armed = scheduler.scheduled.single;
    final isha = armed.firstWhere((a) => a.name == 'Isha');
    // Today's Isha and tomorrow's, as the cached month gives them — a day
    // apart only by coincidence of this fixture, but each its own instant.
    expect(isha.times.length, 2);
    expect(isha.times.first.isAfter(DateTime.now()), isTrue);
    expect(isha.times.first.isBefore(isha.times.last), isTrue);

    // Today's Fajr has passed, so only tomorrow's is armed.
    final fajr = armed.firstWhere((a) => a.name == 'Fajr');
    expect(fajr.times.length, 1);
    expect(fajr.isFajr, isTrue);

    // Sunrise never sounds.
    expect(armed.map((a) => a.name), isNot(contains('Sunrise')));
  });

  test('the master switch off cancels the alarms and silences the adhan',
      () async {
    bloc = build();
    await load();

    bloc.add(const ToggleAdhanEvent());
    await bloc.stream.firstWhere((s) => s.muted);
    await pumpEventQueue();

    expect(scheduler.cancels, greaterThanOrEqualTo(1));
    expect(scheduler.stops, 1);
    expect(settings.settings.enabled, isFalse, reason: 'it is persisted');
  });

  test('switching it back on arms everything again', () async {
    bloc = build();
    await load();
    final armed = scheduler.scheduled.length;

    bloc.add(const ToggleAdhanEvent());
    await bloc.stream.firstWhere((s) => s.muted);
    bloc.add(const ToggleAdhanEvent());
    await bloc.stream.firstWhere((s) => !s.muted);
    await pumpEventQueue();

    expect(scheduler.scheduled.length, armed + 1);
    expect(scheduler.stops, 1, reason: 'turning it on silences nothing');
  });

  test('a change made on the settings screen re-arms straight away', () async {
    bloc = build();
    await load();

    // What the settings screen does: save, and let everything follow.
    await settings.saveAdhanSettings(
      AdhanSettings(enabled: true, prayers: {PrayerName.dhuhr}),
    );
    await bloc.stream.firstWhere((s) => s.settings.prayers.length == 1);
    await pumpEventQueue();

    expect(scheduler.lastNames, ['Dhuhr']);
  });

  test('switching every prayer off clears the alarms', () async {
    bloc = build();
    await load();

    await settings.saveAdhanSettings(
      AdhanSettings(enabled: true, prayers: const {}),
    );
    await bloc.stream.firstWhere((s) => s.settings.prayers.isEmpty);
    await pumpEventQueue();

    // Armed with nothing, rather than left holding the previous set.
    expect(scheduler.scheduled.last, isEmpty);
  });

  test('with nothing downloaded it leaves the armed alarms alone', () async {
    prayers.upcoming = const [];
    bloc = build();

    await load();

    expect(scheduler.scheduled, isEmpty);
  });

  test('near the end of the month it fetches the next one', () async {
    // The 28th of a 30-day month: three days of alarms left.
    bloc = build(clock: () => DateTime(2026, 9, 28, 10));

    await load();

    expect(prayers.prefetches, 1);
  });

  test('mid-month it leaves the network alone', () async {
    bloc = build(clock: () => DateTime(2026, 9, 10, 10));

    await load();

    expect(prayers.prefetches, 0);
  });

  test('a refused notification permission turns the adhan off', () async {
    permission.granted = false;
    bloc = build();

    await load();

    expect(permission.requests, 1);
    expect(bloc.state.muted, isTrue);
    expect(settings.settings.enabled, isFalse);
    expect(scheduler.scheduled, isEmpty);
    expect(scheduler.cancels, greaterThanOrEqualTo(1));
  });
}
