import 'dart:async';

import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/presentation/view_status.dart';
import '../../../../core/services/connectivity_service.dart';
import '../../../../core/usecase/usecase.dart';
import '../../domain/entities/adhan_settings.dart';
import '../../domain/entities/prayer_times.dart';
import '../../domain/services/adhan_prayer_policy.dart';
import '../../domain/services/adhan_scheduler.dart';
import '../../domain/services/next_prayer_calculator.dart';
import '../../domain/usecases/ensure_adhan_permitted.dart';
import '../../domain/usecases/get_prayer_times.dart';
import '../../domain/usecases/get_upcoming_prayer_days.dart';
import '../../domain/usecases/prefetch_next_month.dart';
import '../../domain/usecases/save_adhan_settings.dart';
import '../../domain/usecases/watch_adhan_settings.dart';

part 'time_event.dart';
part 'time_state.dart';

class TimeBloc extends Bloc<TimeEvent, TimeState> {
  final GetPrayerTimes getPrayerTimes;

  /// Every downloaded day, so the alarms carry each prayer's real instant
  /// rather than one clock time repeated daily.
  final GetUpcomingPrayerDays getUpcomingPrayerDays;
  final PrefetchNextMonth prefetchNextMonth;

  final AdhanScheduler adhanScheduler;
  final AdhanPrayerPolicy adhanPrayerPolicy;
  final NextPrayerCalculator nextPrayerCalculator;
  final ConnectivityService connectivityService;

  /// Settings the user can also change from the settings screen, so they are
  /// watched rather than read once.
  final EnsureAdhanPermitted ensureAdhanPermitted;
  final SaveAdhanSettings saveAdhanSettings;
  final WatchAdhanSettings watchAdhanSettings;

  /// Reads the current time; injectable so a test can sit at a month's end.
  final DateTime Function() clock;

  /// How close to the end of the month counts as "about to run out".
  static const int _prefetchWindowDays = 5;

  Timer? _ticker;
  StreamSubscription<bool>? _connectivitySub;
  StreamSubscription<AdhanSettings>? _settingsSub;

  TimeBloc({
    required this.getPrayerTimes,
    required this.getUpcomingPrayerDays,
    required this.prefetchNextMonth,
    required this.adhanScheduler,
    required this.adhanPrayerPolicy,
    required this.nextPrayerCalculator,
    required this.connectivityService,
    required this.ensureAdhanPermitted,
    required this.saveAdhanSettings,
    required this.watchAdhanSettings,
    this.clock = DateTime.now,
  }) : super(TimeState(settings: AdhanSettings.defaults)) {
    on<LoadPrayerTimesEvent>(_onLoad);
    on<_TickEvent>(_onTick);
    on<ToggleAdhanEvent>(_onToggleAdhan);
    on<_SettingsChangedEvent>(_onSettingsChanged);
    on<_ConnectivityChangedEvent>(_onConnectivityChanged);

    _connectivitySub = connectivityService.onConnectivityChanged.listen((
      online,
    ) {
      if (!isClosed) add(_ConnectivityChangedEvent(online));
    });

    _settingsSub = watchAdhanSettings(const NoParams()).listen((settings) {
      if (!isClosed) add(_SettingsChangedEvent(settings));
    });
  }

  Future<void> _onLoad(
    LoadPrayerTimesEvent event,
    Emitter<TimeState> emit,
  ) async {
    emit(state.copyWith(status: ViewStatus.loading));

    // Opening the tab is where the adhan permission is asked for, if the user
    // has adhans on and has not been asked yet. A refusal turns them off.
    final settings = await ensureAdhanPermitted(const NoParams());
    emit(
      state.copyWith(
        settings: settings.getOrElse(() => state.settings),
      ),
    );

    final result = await getPrayerTimes(const NoParams());
    await result.fold(
      (failure) async => emit(
        state.copyWith(
          status: ViewStatus.failure,
          errorMessage: failure.message,
        ),
      ),
      (cached) async {
        final times = cached.data;
        await _syncAdhans(state.settings);
        final next = _nextPrayer(times);
        emit(
          state.copyWith(
            status: ViewStatus.success,
            prayerTimes: times,
            isFromCache: cached.fromCache,
            nextPrayerName: next.name,
            countdown: next.countdown,
          ),
        );
        _startTicker();
      },
    );
  }

  Future<void> _onConnectivityChanged(
    _ConnectivityChangedEvent event,
    Emitter<TimeState> emit,
  ) async {
    // The offline strip is driven by ConnectivityCubit. Back online after
    // failing to load (e.g. the month wasn't cached yet): retry. If we already
    // have a schedule, keep it — the month is still valid.
    if (event.online && state.status == ViewStatus.failure) {
      add(const LoadPrayerTimesEvent());
    }
  }

  void _onTick(_TickEvent event, Emitter<TimeState> emit) {
    final times = state.prayerTimes;
    if (times == null) return;

    final next = _nextPrayer(times);
    emit(
      state.copyWith(
        nextPrayerName: next.name,
        countdown: next.countdown,
      ),
    );
  }

  /// The volume icon on the prayer card: the master switch, and nothing else.
  ///
  /// Saving is all this does — the settings stream brings the change back
  /// through [_onSettingsChanged], which is the one place alarms are armed.
  Future<void> _onToggleAdhan(
    ToggleAdhanEvent event,
    Emitter<TimeState> emit,
  ) async {
    final turningOn = !state.settings.enabled;
    await saveAdhanSettings(state.settings.copyWith(enabled: turningOn));
    if (turningOn) await ensureAdhanPermitted(const NoParams());
  }

  Future<void> _onSettingsChanged(
    _SettingsChangedEvent event,
    Emitter<TimeState> emit,
  ) async {
    final wasEnabled = state.settings.enabled;
    emit(state.copyWith(settings: event.settings));

    await _syncAdhans(event.settings);
    // Switching the adhan off must also silence one that is playing.
    if (wasEnabled && !event.settings.enabled) {
      await adhanScheduler.stopNow();
    }
  }

  void _startTicker() {
    _ticker?.cancel();
    _ticker = Timer.periodic(const Duration(seconds: 30), (_) {
      if (!isClosed) add(const _TickEvent());
    });
  }

  /// The next prayer's name and how long until it — the pair both the first
  /// load and every tick put on screen.
  ({String name, Duration countdown}) _nextPrayer(PrayerTimes times) {
    final next = nextPrayerCalculator.findNext(times);
    if (next == null) return (name: '', countdown: Duration.zero);
    return (
      name: next.name,
      countdown: next.time.difference(DateTime.now()),
    );
  }

  /// Arms the native adhan alarms for the prayers [settings] asks for, or
  /// clears them when the master switch is off.
  ///
  /// Every downloaded day is sent, so the device keeps firing at the right
  /// minute for weeks without the app being opened. With nothing downloaded
  /// yet there is nothing to arm, and the alarms already set keep running.
  Future<void> _syncAdhans(AdhanSettings settings) async {
    if (!settings.enabled) {
      await adhanScheduler.cancel();
      return;
    }

    await _prefetchIfMonthIsEnding();

    final result = await getUpcomingPrayerDays(const NoParams());
    final days = result.getOrElse(() => const []);
    // Nothing downloaded yet (first run offline): the alarms already set are
    // the best guess there is, so leave them be.
    if (days.isEmpty) return;

    // An empty result here means something else: every prayer is switched off,
    // which has to clear the alarms rather than leave the old set armed.
    await adhanScheduler.schedule(
      adhanPrayerPolicy.schedulesFor(days, settings),
    );
  }

  /// Near the end of the month the cached days are about to run out, so fetch
  /// the next one while there is a connection.
  Future<void> _prefetchIfMonthIsEnding() async {
    final now = clock();
    final daysLeft = DateTime(now.year, now.month + 1, 0).day - now.day;
    if (daysLeft > _prefetchWindowDays) return;
    if (!await connectivityService.isConnected) return;

    await prefetchNextMonth(const NoParams());
  }

  @override
  Future<void> close() {
    _ticker?.cancel();
    _connectivitySub?.cancel();
    _settingsSub?.cancel();
    return super.close();
  }
}
