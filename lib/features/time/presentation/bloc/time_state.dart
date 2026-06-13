part of 'time_bloc.dart';

enum TimeStatus { initial, loading, success, failure }

class TimeState extends Equatable {
  final TimeStatus status;
  final PrayerTimes? prayerTimes;
  final String nextPrayerName;
  final Duration countdown;
  final bool muted;
  final String errorMessage;

  const TimeState({
    this.status = TimeStatus.initial,
    this.prayerTimes,
    this.nextPrayerName = '',
    this.countdown = Duration.zero,
    this.muted = false,
    this.errorMessage = '',
  });

  TimeState copyWith({
    TimeStatus? status,
    PrayerTimes? prayerTimes,
    String? nextPrayerName,
    Duration? countdown,
    bool? muted,
    String? errorMessage,
  }) {
    return TimeState(
      status: status ?? this.status,
      prayerTimes: prayerTimes ?? this.prayerTimes,
      nextPrayerName: nextPrayerName ?? this.nextPrayerName,
      countdown: countdown ?? this.countdown,
      muted: muted ?? this.muted,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }

  @override
  List<Object?> get props =>
      [status, prayerTimes, nextPrayerName, countdown, muted, errorMessage];
}
