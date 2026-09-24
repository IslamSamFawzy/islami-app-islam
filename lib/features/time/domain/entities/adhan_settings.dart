import 'package:equatable/equatable.dart';

import 'prayer_name.dart';

/// Which adhans the user wants to hear.
class AdhanSettings extends Equatable {
  /// Master switch. With this off nothing is armed and nothing sounds,
  /// whatever [prayers] says.
  final bool enabled;

  /// The prayers that call an adhan while [enabled].
  final Set<PrayerName> prayers;

  const AdhanSettings({required this.enabled, required this.prayers});

  /// What a fresh install gets: every adhan on.
  static final AdhanSettings defaults = AdhanSettings(
    enabled: true,
    prayers: PrayerName.values.toSet(),
  );

  /// Whether [prayer] should sound.
  bool callsAdhanFor(PrayerName prayer) => enabled && prayers.contains(prayer);

  AdhanSettings copyWith({bool? enabled, Set<PrayerName>? prayers}) {
    return AdhanSettings(
      enabled: enabled ?? this.enabled,
      prayers: prayers ?? this.prayers,
    );
  }

  /// The same settings with [prayer] switched the other way.
  AdhanSettings toggling(PrayerName prayer) {
    final next = prayers.toSet();
    if (!next.remove(prayer)) next.add(prayer);
    return copyWith(prayers: next);
  }

  @override
  List<Object?> get props => [enabled, prayers];
}
