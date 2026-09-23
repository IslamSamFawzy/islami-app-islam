import '../../../../core/services/adhan_scheduler.dart';
import '../entities/prayer_times.dart';

/// Decides which prayers in a [PrayerTimes] schedule should trigger an adhan
/// and how they map to [AdhanTime] values.
abstract class AdhanPrayerPolicy {
  /// The list of adhan notifications to schedule for [times].
  List<AdhanTime> adhanTimes(PrayerTimes times);
}

/// Default policy: Fajr, Dhuhr, Asr, Maghrib and Isha trigger an adhan;
/// Sunrise is informational only and is excluded.
class DefaultAdhanPrayerPolicy implements AdhanPrayerPolicy {
  static const List<String> _adhanPrayers = [
    'Fajr',
    'Dhuhr',
    'Asr',
    'Maghrib',
    'Isha',
  ];

  @override
  List<AdhanTime> adhanTimes(PrayerTimes times) => times.prayers
      .where((p) => _adhanPrayers.contains(p.name))
      .map(
        (p) => AdhanTime(name: p.name, time: p.time, isFajr: p.name == 'Fajr'),
      )
      .toList();
}
