import 'dart:async';

import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/services/adhan_scheduler.dart';
import '../../../../core/services/connectivity_service.dart';
import '../../../../core/usecase/usecase.dart';
import '../../domain/entities/prayer_times.dart';
import '../../domain/services/adhan_prayer_policy.dart';
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
    emit(state.copyWith(status: TimeStatus.loading));
    final result = await getPrayerTimes(const NoParams());
    await result.fold(
      (failure) async => emit(
        state.copyWith(
          status: TimeStatus.failure,
          errorMessage: failure.message,
        ),
      ),
      (cached) async {
        final times = cached.data;
        await _syncAdhans(times);
        final next = nextPrayerCalculator.findNext(times);
        emit(
          state.copyWith(
            status: TimeStatus.success,
            prayerTimes: times,
            isFromCache: cached.fromCache,
            // Seed the offline flag so a cold start with no connection shows the
            // strip immediately (the stream only fires on subsequent changes).
            isOffline: !await connectivityService.isConnected,
            nextPrayerName: next?.name ?? '',
            countdown: next == null
                ? Duration.zero
                : next.time.difference(DateTime.now()),
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
    emit(state.copyWith(isOffline: !event.online));
    // Back online after failing to load (e.g. the month wasn't cached yet):
    // retry. If we already have a schedule, keep it — the month is still valid.
    if (event.online && state.status == TimeStatus.failure) {
      add(const LoadPrayerTimesEvent());
    }
  }

  void _onTick(_TickEvent event, Emitter<TimeState> emit) {
    final times = state.prayerTimes;
    if (times == null) return;

    final next = nextPrayerCalculator.findNext(times);
    emit(
      state.copyWith(
        nextPrayerName: next?.name ?? '',
        countdown: next == null
            ? Duration.zero
            : next.time.difference(DateTime.now()),
      ),
    );
  }

  Future<void> _onToggleMute(
    ToggleMuteEvent event,
    Emitter<TimeState> emit,
  ) async {
    final muted = !state.muted;
    emit(state.copyWith(muted: muted));

    if (muted) {
      // Muted must mean nothing fires — cancel the alarms and stop any adhan
      // currently playing.
      await adhanScheduler.cancel();
      await adhanScheduler.stopNow();
    } else {
      final times = state.prayerTimes;
      if (times != null) {
        await adhanScheduler.schedule(adhanPrayerPolicy.adhanTimes(times));
      }
    }
  }

  void _startTicker() {
    _ticker?.cancel();
    _ticker = Timer.periodic(const Duration(seconds: 30), (_) {
      if (!isClosed) add(const _TickEvent());
    });
  }

  /// Arms (or clears, when muted) the native adhan alarms for [times].
  Future<void> _syncAdhans(PrayerTimes times) async {
    if (state.muted) {
      await adhanScheduler.cancel();
    } else {
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
