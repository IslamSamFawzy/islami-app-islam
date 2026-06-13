part of 'time_bloc.dart';

abstract class TimeEvent extends Equatable {
  const TimeEvent();

  @override
  List<Object?> get props => [];
}

/// Fetches location + prayer times and (re)schedules adhan notifications.
class LoadPrayerTimesEvent extends TimeEvent {
  const LoadPrayerTimesEvent();
}

/// Internal periodic tick (recomputes next prayer + foreground adhan).
class _TickEvent extends TimeEvent {
  const _TickEvent();
}

/// Mutes/unmutes the in-app adhan sound.
class ToggleMuteEvent extends TimeEvent {
  const ToggleMuteEvent();
}
