import '../../domain/entities/prayer_times.dart';

/// Parses the Aladhan API `data` object into a [PrayerTimes].
class PrayerTimesModel extends PrayerTimes {
  const PrayerTimesModel({
    required super.weekday,
    required super.gregorianDate,
    required super.gregorianYear,
    required super.hijriDate,
    required super.hijriYear,
    required super.prayers,
  });

  factory PrayerTimesModel.fromJson(Map<String, dynamic> data) {
    final timings = (data['timings'] as Map).cast<String, dynamic>();
    final date = (data['date'] as Map).cast<String, dynamic>();
    final gregorian = (date['gregorian'] as Map).cast<String, dynamic>();
    final hijri = (date['hijri'] as Map).cast<String, dynamic>();

    final year = int.tryParse('${gregorian['year']}') ?? DateTime.now().year;
    final month = int.tryParse('${(gregorian['month'] as Map)['number']}') ??
        DateTime.now().month;
    final day = int.tryParse('${gregorian['day']}') ?? DateTime.now().day;

    DateTime parse(String key) {
      final raw = (timings[key] as String).trim();
      // Strip any trailing timezone annotation like "04:24 (EET)".
      final clean = raw.split(' ').first;
      final parts = clean.split(':');
      final h = int.tryParse(parts[0]) ?? 0;
      final m = parts.length > 1 ? (int.tryParse(parts[1]) ?? 0) : 0;
      return DateTime(year, month, day, h, m);
    }

    final order = ['Fajr', 'Sunrise', 'Dhuhr', 'Asr', 'Maghrib', 'Isha'];
    final prayers = [
      for (final name in order)
        if (timings.containsKey(name)) Prayer(name: name, time: parse(name)),
    ];

    String short(String s) => s.length <= 3 ? s : s.substring(0, 3);

    return PrayerTimesModel(
      weekday: '${(gregorian['weekday'] as Map)['en']}',
      gregorianDate: '${gregorian['day']} '
          '${short('${(gregorian['month'] as Map)['en']}')}',
      gregorianYear: '${gregorian['year']}',
      hijriDate: '${hijri['day']} ${short('${(hijri['month'] as Map)['en']}')}',
      hijriYear: '${hijri['year']}',
      prayers: prayers,
    );
  }
}
