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

/// Turns every adhan on or off — the volume icon on the prayer card.
class ToggleAdhanEvent extends TimeEvent {
  const ToggleAdhanEvent();
}

/// Internal: the adhan settings changed (here or on the settings screen).
class _SettingsChangedEvent extends TimeEvent {
  final AdhanSettings settings;

  const _SettingsChangedEvent(this.settings);

  @override
  List<Object?> get props => [settings];
}

/// Internal: forwards connectivity changes (drives the offline strip and
/// retries a failed load on reconnect).
class _ConnectivityChangedEvent extends TimeEvent {
  final bool online;

  const _ConnectivityChangedEvent(this.online);

  @override
  List<Object?> get props => [online];
}
