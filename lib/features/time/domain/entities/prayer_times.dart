import 'package:equatable/equatable.dart';

/// A single prayer with its time for today (local).
class Prayer extends Equatable {
  final String name;
  final DateTime time;

  const Prayer({required this.name, required this.time});

  @override
  List<Object?> get props => [name, time];
}

/// Today's prayer schedule plus the Gregorian/Hijri date labels.
class PrayerTimes extends Equatable {
  final String weekday;
  final String gregorianDate; // e.g. "16 Jul"
  final String gregorianYear; // e.g. "2024"
  final String hijriDate; // e.g. "09 Muh"
  final String hijriYear; // e.g. "1446"
  final List<Prayer> prayers;

  const PrayerTimes({
    required this.weekday,
    required this.gregorianDate,
    required this.gregorianYear,
    required this.hijriDate,
    required this.hijriYear,
    required this.prayers,
  });

  @override
  List<Object?> get props =>
      [weekday, gregorianDate, gregorianYear, hijriDate, hijriYear, prayers];
}
