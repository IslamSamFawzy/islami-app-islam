import 'dart:async';

import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:islami/core/cache/cache_result.dart';
import 'package:islami/core/error/failures.dart';
import 'package:islami/core/services/connectivity_service.dart';
import 'package:islami/features/time/domain/entities/adhan_settings.dart';
import 'package:islami/features/time/domain/entities/adhan_time.dart';
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
import 'package:islami/features/time/domain/usecases/save_adhan_settings.dart';
import 'package:islami/features/time/domain/usecases/watch_adhan_settings.dart';
import 'package:islami/features/time/presentation/bloc/time_bloc.dart';

class _FakeScheduler implements AdhanScheduler {
  final List<List<AdhanTime>> scheduled = [];
  int cancels = 0;
  int stops = 0;

  @override
  Future<void> schedule(List<AdhanTime> adhans) async => scheduled.add(adhans);
  @override
  Future<void> cancel() async => cancels++;
  @override
  Future<void> stopNow() async => stops++;

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

  _FakeRepository(this.times);

  @override
  Future<Either<Failure, CacheResult<PrayerTimes>>> getPrayerTimes() async =>
      Right(CacheResult(times, fromCache: true));
}

class _FakeConnectivity implements ConnectivityService {
  @override
  Future<bool> get isConnected async => true;
  @override
  Stream<bool> get onConnectivityChanged => const Stream.empty();
}

void main() {
  final now = DateTime.now();
  final times = PrayerTimes(
    weekday: 'Monday',
    gregorianDate: '24 Sep',
    gregorianYear: '2026',
    hijriDate: '12 Rab',
    hijriYear: '1448',
    prayers: [
      Prayer(name: 'Fajr', time: now.subtract(const Duration(hours: 4))),
      Prayer(name: 'Sunrise', time: now.subtract(const Duration(hours: 3))),
      Prayer(name: 'Dhuhr', time: now.add(const Duration(hours: 2))),
      Prayer(name: 'Isha', time: now.add(const Duration(hours: 8))),
    ],
  );

  late _FakeScheduler scheduler;
  late _FakeSettingsRepository settings;
  late _FakePermission permission;
  late TimeBloc bloc;

  TimeBloc build() {
    return TimeBloc(
      getPrayerTimes: GetPrayerTimes(_FakeRepository(times)),
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
