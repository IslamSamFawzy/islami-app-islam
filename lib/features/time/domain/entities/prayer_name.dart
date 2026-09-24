/// The five daily prayers that call an adhan.
///
/// A schedule also carries Sunrise, which is informational only — so it is
/// deliberately not one of these, and "does this one get an adhan?" is
/// `PrayerName.of(name) != null` rather than a list of five strings copied
/// into every service that asks.
enum PrayerName {
  fajr('Fajr'),
  dhuhr('Dhuhr'),
  asr('Asr'),
  maghrib('Maghrib'),
  isha('Isha');

  /// The name the prayer goes by in the API, the cache and on screen.
  final String label;

  const PrayerName(this.label);

  /// The prayer [label] names, or `null` for anything else (Sunrise, …).
  static PrayerName? of(String label) {
    for (final prayer in values) {
      if (prayer.label == label) return prayer;
    }
    return null;
  }

  /// Sunrise is part of a day's schedule and is shown on the prayer card, but
  /// it never calls an adhan — which is exactly why it is not one of these.
  static const String sunriseLabel = 'Sunrise';

  /// Every name a day's schedule carries, in the order they are shown.
  static List<String> get scheduleLabels => [
    for (final prayer in values) ...[
      prayer.label,
      if (prayer == fajr) sunriseLabel,
    ],
  ];
}
