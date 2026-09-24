import '../entities/adhan_time.dart';
import '../entities/prayer_name.dart';
import '../entities/prayer_times.dart';

/// Decides which prayers in a [PrayerTimes] schedule should trigger an adhan
/// and how they map to [AdhanTime] values.
abstract class AdhanPrayerPolicy {
  /// The list of adhan notifications to schedule for [times].
  List<AdhanTime> adhanTimes(PrayerTimes times);
}

/// Default policy: the five [PrayerName] prayers trigger an adhan; Sunrise is
/// informational only and is excluded.
class DefaultAdhanPrayerPolicy implements AdhanPrayerPolicy {
  @override
  List<AdhanTime> adhanTimes(PrayerTimes times) => [
    for (final prayer in times.prayers)
      if (PrayerName.of(prayer.name) case final name?)
        AdhanTime(
          name: prayer.name,
          time: prayer.time,
          isFajr: name == PrayerName.fajr,
        ),
  ];
}
