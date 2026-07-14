part of 'time_bloc.dart';

enum TimeStatus { initial, loading, success, failure }

class TimeState extends Equatable {
  final TimeStatus status;
  final PrayerTimes? prayerTimes;
  final String nextPrayerName;
  final Duration countdown;
  final bool muted;
  final String errorMessage;

  /// Whether the displayed schedule came from the cached month rather than a
  /// fresh network fetch.
  final bool isFromCache;

  const TimeState({
    this.status = TimeStatus.initial,
    this.prayerTimes,
    this.nextPrayerName = '',
    this.countdown = Duration.zero,
    this.muted = false,
    this.errorMessage = '',
    this.isFromCache = false,
  });

  TimeState copyWith({
    TimeStatus? status,
    PrayerTimes? prayerTimes,
    String? nextPrayerName,
    Duration? countdown,
    bool? muted,
    String? errorMessage,
    bool? isFromCache,
  }) {
    return TimeState(
      status: status ?? this.status,
      prayerTimes: prayerTimes ?? this.prayerTimes,
      nextPrayerName: nextPrayerName ?? this.nextPrayerName,
      countdown: countdown ?? this.countdown,
      muted: muted ?? this.muted,
      errorMessage: errorMessage ?? this.errorMessage,
      isFromCache: isFromCache ?? this.isFromCache,
    );
  }

  @override
  List<Object?> get props => [
        status,
        prayerTimes,
        nextPrayerName,
        countdown,
        muted,
        errorMessage,
        isFromCache,
      ];
}
