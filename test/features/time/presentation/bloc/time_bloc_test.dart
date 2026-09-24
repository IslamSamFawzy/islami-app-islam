import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:islami/core/cache/cache_result.dart';
import 'package:islami/core/error/failures.dart';
import 'package:islami/core/services/connectivity_service.dart';
import 'package:islami/features/time/domain/entities/adhan_time.dart';
import 'package:islami/features/time/domain/entities/prayer_times.dart';
import 'package:islami/features/time/domain/repositories/prayer_repository.dart';
import 'package:islami/features/time/domain/services/adhan_prayer_policy.dart';
import 'package:islami/features/time/domain/services/adhan_scheduler.dart';
import 'package:islami/features/time/domain/services/next_prayer_calculator.dart';
import 'package:islami/features/time/domain/usecases/get_prayer_times.dart';
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
    ],
  );

  late _FakeScheduler scheduler;
  late TimeBloc bloc;

  setUp(() {
    scheduler = _FakeScheduler();
    bloc = TimeBloc(
      getPrayerTimes: GetPrayerTimes(_FakeRepository(times)),
      adhanScheduler: scheduler,
      adhanPrayerPolicy: DefaultAdhanPrayerPolicy(),
      nextPrayerCalculator: AdhanNextPrayerCalculator(),
      connectivityService: _FakeConnectivity(),
    );
  });

  tearDown(() => bloc.close());

  Future<void> load() async {
    bloc.add(const LoadPrayerTimesEvent());
    await bloc.stream.firstWhere((s) => s.prayerTimes != null);
  }

  test('loading arms the adhans and reports the next prayer', () async {
    await load();

    expect(scheduler.scheduled.single.map((a) => a.name), ['Fajr', 'Dhuhr']);
    expect(bloc.state.nextPrayerName, 'Dhuhr');
    expect(bloc.state.countdown.inMinutes, greaterThan(0));
  });

  test('muting cancels the alarms and silences a playing adhan', () async {
    await load();

    bloc.add(const ToggleMuteEvent());
    await bloc.stream.firstWhere((s) => s.muted);
    // The state flips before the scheduler calls finish.
    await pumpEventQueue();

    expect(scheduler.cancels, 1);
    expect(scheduler.stops, 1);
  });

  test('unmuting arms them again', () async {
    await load();
    bloc.add(const ToggleMuteEvent());
    await bloc.stream.firstWhere((s) => s.muted);

    bloc.add(const ToggleMuteEvent());
    await bloc.stream.firstWhere((s) => !s.muted);
    await pumpEventQueue();

    expect(scheduler.scheduled.length, 2);
    expect(scheduler.stops, 1, reason: 'unmuting must not stop anything');
  });
}
