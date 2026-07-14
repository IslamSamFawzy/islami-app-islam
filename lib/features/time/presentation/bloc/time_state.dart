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

  /// Whether the device currently has no network connection.
  final bool isOffline;

  const TimeState({
    this.status = TimeStatus.initial,
    this.prayerTimes,
    this.nextPrayerName = '',
    this.countdown = Duration.zero,
    this.muted = false,
    this.errorMessage = '',
    this.isFromCache = false,
    this.isOffline = false,
  });

  /// Whether to surface the "showing saved data" strip: offline while a saved
  /// schedule is on screen (data shown while offline is saved data either way).
  bool get showOfflineBanner => isOffline && prayerTimes != null;

  TimeState copyWith({
    TimeStatus? status,
    PrayerTimes? prayerTimes,
    String? nextPrayerName,
    Duration? countdown,
    bool? muted,
    String? errorMessage,
    bool? isFromCache,
    bool? isOffline,
  }) {
    return TimeState(
      status: status ?? this.status,
      prayerTimes: prayerTimes ?? this.prayerTimes,
      nextPrayerName: nextPrayerName ?? this.nextPrayerName,
      countdown: countdown ?? this.countdown,
      muted: muted ?? this.muted,
      errorMessage: errorMessage ?? this.errorMessage,
      isFromCache: isFromCache ?? this.isFromCache,
      isOffline: isOffline ?? this.isOffline,
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
        isOffline,
      ];
}
