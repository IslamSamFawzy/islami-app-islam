import 'dart:async';

import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/presentation/view_status.dart';
import '../../../../core/services/connectivity_service.dart';
import '../../../../core/usecase/usecase.dart';
import '../../domain/entities/prayer_times.dart';
import '../../domain/services/adhan_prayer_policy.dart';
import '../../domain/services/adhan_scheduler.dart';
import '../../domain/services/next_prayer_calculator.dart';
import '../../domain/usecases/get_prayer_times.dart';

part 'time_event.dart';
part 'time_state.dart';

class TimeBloc extends Bloc<TimeEvent, TimeState> {
  final GetPrayerTimes getPrayerTimes;
  final AdhanScheduler adhanScheduler;
  final AdhanPrayerPolicy adhanPrayerPolicy;
  final NextPrayerCalculator nextPrayerCalculator;
  final ConnectivityService connectivityService;

  Timer? _ticker;
  StreamSubscription<bool>? _connectivitySub;

  TimeBloc({
    required this.getPrayerTimes,
    required this.adhanScheduler,
    required this.adhanPrayerPolicy,
    required this.nextPrayerCalculator,
    required this.connectivityService,
  }) : super(const TimeState()) {
    on<LoadPrayerTimesEvent>(_onLoad);
    on<_TickEvent>(_onTick);
    on<ToggleMuteEvent>(_onToggleMute);
    on<_ConnectivityChangedEvent>(_onConnectivityChanged);

    _connectivitySub = connectivityService.onConnectivityChanged.listen((
      online,
    ) {
      if (!isClosed) add(_ConnectivityChangedEvent(online));
    });
  }

  Future<void> _onLoad(
    LoadPrayerTimesEvent event,
    Emitter<TimeState> emit,
  ) async {
    emit(state.copyWith(status: ViewStatus.loading));
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
        await _syncAdhans(times);
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

  Future<void> _onToggleMute(
    ToggleMuteEvent event,
    Emitter<TimeState> emit,
  ) async {
    final muted = !state.muted;
    emit(state.copyWith(muted: muted));

    await _syncAdhans(state.prayerTimes);
    // Muted must also mean nothing is heard right now.
    if (muted) await adhanScheduler.stopNow();
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

  /// Arms the native adhan alarms for [times], or clears them when muted.
  ///
  /// With no schedule yet there is nothing to arm, and yesterday's alarms
  /// repeat daily, so they are left alone rather than cancelled.
  Future<void> _syncAdhans(PrayerTimes? times) async {
    if (state.muted) {
      await adhanScheduler.cancel();
      return;
    }
    if (times != null) {
      await adhanScheduler.schedule(adhanPrayerPolicy.adhanTimes(times));
    }
  }

  @override
  Future<void> close() {
    _ticker?.cancel();
    _connectivitySub?.cancel();
    return super.close();
  }
}
