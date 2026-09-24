import '../entities/adhan_settings.dart';
import '../entities/adhan_time.dart';
import '../entities/prayer_name.dart';
import '../entities/prayer_times.dart';

/// Decides which prayers in a [PrayerTimes] schedule should trigger an adhan
/// and how they map to [AdhanTime] values.
abstract class AdhanPrayerPolicy {
  /// The adhans to arm for [times], given what the user asked for.
  List<AdhanTime> adhanTimes(PrayerTimes times, AdhanSettings settings);
}

/// Default policy: a prayer is armed when the user has it switched on. Sunrise
/// is informational only, so it is never one of them — see [PrayerName].
class DefaultAdhanPrayerPolicy implements AdhanPrayerPolicy {
  @override
  List<AdhanTime> adhanTimes(PrayerTimes times, AdhanSettings settings) => [
    for (final prayer in times.prayers)
      if (PrayerName.of(prayer.name) case final name?)
        if (settings.callsAdhanFor(name))
          AdhanTime(
            name: prayer.name,
            time: prayer.time,
            isFajr: name == PrayerName.fajr,
          ),
  ];
}
