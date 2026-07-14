import 'dart:async';

import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/services/audio_player_service.dart';
import '../../../../core/services/connectivity_service.dart';
import '../../../../core/services/notification_service.dart';
import '../../../../core/usecase/usecase.dart';
import '../../domain/entities/prayer_times.dart';
import '../../domain/usecases/get_prayer_times.dart';

part 'time_event.dart';
part 'time_state.dart';

class TimeBloc extends Bloc<TimeEvent, TimeState> {
  final GetPrayerTimes getPrayerTimes;
  final NotificationService notificationService;
  final AudioPlayerService audioPlayerService;
  final ConnectivityService connectivityService;

  Timer? _ticker;
  StreamSubscription<bool>? _connectivitySub;
  String _lastAdhanKey = '';

  /// Free online adhan audio (played in-app when a prayer time arrives).
  static const String _adhanUrl =
      'https://www.islamcan.com/audio/adhan/azan2.mp3';

  /// Prayer names that trigger an adhan (Sunrise is informational only).
  static const List<String> _adhanPrayers = [
    'Fajr',
    'Dhuhr',
    'Asr',
    'Maghrib',
    'Isha',
  ];

  TimeBloc({
    required this.getPrayerTimes,
    required this.notificationService,
    required this.audioPlayerService,
    required this.connectivityService,
  }) : super(const TimeState()) {
    on<LoadPrayerTimesEvent>(_onLoad);
    on<_TickEvent>(_onTick);
    on<ToggleMuteEvent>(_onToggleMute);
    on<_ConnectivityChangedEvent>(_onConnectivityChanged);

    _connectivitySub = connectivityService.onConnectivityChanged.listen((online) {
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
      (failure) async => emit(state.copyWith(
        status: TimeStatus.failure,
        errorMessage: failure.message,
      )),
      (cached) async {
        final times = cached.data;
        await _scheduleNotifications(times);
        final next = _nextPrayer(times);
        emit(state.copyWith(
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
        ));
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

    final next = _nextPrayer(times);
    emit(state.copyWith(
      nextPrayerName: next?.name ?? '',
      countdown: next == null
          ? Duration.zero
          : next.time.difference(DateTime.now()),
    ));

    _maybePlayAdhan(times);
  }

  void _onToggleMute(ToggleMuteEvent event, Emitter<TimeState> emit) {
    final muted = !state.muted;
    if (muted) {
      audioPlayerService.stop();
    }
    emit(state.copyWith(muted: muted));
  }

  void _startTicker() {
    _ticker?.cancel();
    _ticker = Timer.periodic(const Duration(seconds: 30), (_) {
      if (!isClosed) add(const _TickEvent());
    });
  }

  Future<void> _scheduleNotifications(PrayerTimes times) async {
    await notificationService.cancelAll();
    var id = 0;
    for (final prayer in times.prayers) {
      if (!_adhanPrayers.contains(prayer.name)) continue;
      await notificationService.schedulePrayer(
        id: id++,
        title: 'حان وقت صلاة ${prayer.name}',
        body: 'الله أكبر — حيّ على الصلاة',
        time: prayer.time,
      );
    }
  }

  /// Returns the next upcoming adhan prayer today, or null if all have passed.
  Prayer? _nextPrayer(PrayerTimes times) {
    final now = DateTime.now();
    final upcoming = times.prayers
        .where((p) => _adhanPrayers.contains(p.name) && p.time.isAfter(now))
        .toList()
      ..sort((a, b) => a.time.compareTo(b.time));
    return upcoming.isEmpty ? null : upcoming.first;
  }

  void _maybePlayAdhan(PrayerTimes times) {
    if (state.muted) return;
    final now = DateTime.now();
    for (final prayer in times.prayers) {
      if (!_adhanPrayers.contains(prayer.name)) continue;
      if (prayer.time.hour == now.hour && prayer.time.minute == now.minute) {
        final key = '${prayer.name}-${now.day}-${now.hour}-${now.minute}';
        if (key != _lastAdhanKey) {
          _lastAdhanKey = key;
          audioPlayerService.playUrl(_adhanUrl);
        }
      }
    }
  }

  @override
  Future<void> close() {
    _ticker?.cancel();
    _connectivitySub?.cancel();
    return super.close();
  }
}
