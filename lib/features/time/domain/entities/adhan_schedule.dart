import 'package:equatable/equatable.dart';

/// When one prayer's adhan should sound, for as many days ahead as are known.
///
/// Prayer times drift by up to a minute a day, so the alarms carry the real
/// instant of each day rather than one clock time repeated every 24 hours.
class AdhanSchedule extends Equatable {
  final String name;

  /// What the notification calls this prayer (Arabic, like the rest of its
  /// text).
  final String displayName;

  /// Fajr has its own adhan.
  final bool isFajr;

  /// Future instants, ascending. The device arms the first and moves on to the
  /// next as each one fires.
  final List<DateTime> times;

  const AdhanSchedule({
    required this.name,
    required this.displayName,
    required this.isFajr,
    required this.times,
  });

  @override
  List<Object?> get props => [name, displayName, isFajr, times];
}
