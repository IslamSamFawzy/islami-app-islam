import '../entities/prayer_times.dart';

/// Finds the next upcoming prayer from a [PrayerTimes] schedule.
abstract class NextPrayerCalculator {
  /// The next adhan prayer after now, or `null` if all have passed.
  Prayer? findNext(PrayerTimes times);
}

/// [NextPrayerCalculator] that considers only the canonical adhan prayers
/// (Fajr, Dhuhr, Asr, Maghrib, Isha) and picks the earliest one still in the
/// future.
class AdhanNextPrayerCalculator implements NextPrayerCalculator {
  static const List<String> _adhanPrayers = [
    'Fajr',
    'Dhuhr',
    'Asr',
    'Maghrib',
    'Isha',
  ];

  @override
  Prayer? findNext(PrayerTimes times) {
    final now = DateTime.now();
    final upcoming =
        times.prayers
            .where((p) => _adhanPrayers.contains(p.name) && p.time.isAfter(now))
            .toList()
          ..sort((a, b) => a.time.compareTo(b.time));
    return upcoming.isEmpty ? null : upcoming.first;
  }
}
