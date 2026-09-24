import '../entities/adhan_schedule.dart';
import '../entities/adhan_settings.dart';
import '../entities/prayer_name.dart';
import '../entities/prayer_times.dart';

/// Turns the days the app knows about into the adhans to arm.
abstract class AdhanPrayerPolicy {
  /// One entry per prayer that should sound, carrying every future instant
  /// found in [days] (today first). An empty list means "nothing to arm".
  List<AdhanSchedule> schedulesFor(List<PrayerTimes> days, AdhanSettings settings);
}

/// Default policy: a prayer is armed when the user has it switched on, for
/// every day already downloaded. Sunrise is informational only, so it is never
/// one of them — see [PrayerName].
class DefaultAdhanPrayerPolicy implements AdhanPrayerPolicy {
  @override
  List<AdhanSchedule> schedulesFor(
    List<PrayerTimes> days,
    AdhanSettings settings, {
    DateTime? now,
  }) {
    final from = now ?? DateTime.now();
    final byPrayer = <PrayerName, List<DateTime>>{};

    for (final day in days) {
      for (final prayer in day.prayers) {
        final name = PrayerName.of(prayer.name);
        if (name == null || !settings.callsAdhanFor(name)) continue;
        // A time already past would fire the moment it is armed.
        if (!prayer.time.isAfter(from)) continue;
        byPrayer.putIfAbsent(name, () => []).add(prayer.time);
      }
    }

    return [
      for (final name in PrayerName.values)
        if (byPrayer[name] case final times?)
          AdhanSchedule(
            name: name.label,
            displayName: name.arabicLabel,
            isFajr: name == PrayerName.fajr,
            times: times..sort(),
          ),
    ];
  }
}
