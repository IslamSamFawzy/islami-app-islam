import 'package:flutter_test/flutter_test.dart';
import 'package:islami/features/time/domain/entities/prayer_name.dart';
import 'package:islami/features/time/domain/entities/prayer_times.dart';
import 'package:islami/features/time/domain/services/adhan_prayer_policy.dart';
import 'package:islami/features/time/domain/services/next_prayer_calculator.dart';

PrayerTimes _schedule(List<Prayer> prayers) => PrayerTimes(
      weekday: 'Monday',
      gregorianDate: '24 Sep',
      gregorianYear: '2026',
      hijriDate: '12 Rab',
      hijriYear: '1448',
      prayers: prayers,
    );

void main() {
  final today = DateTime.now();
  Prayer at(String name, int hour) =>
      Prayer(name: name, time: DateTime(today.year, today.month, today.day, hour));

  group('PrayerName', () {
    test('knows the five prayers and nothing else', () {
      expect(PrayerName.of('Fajr'), PrayerName.fajr);
      expect(PrayerName.of('Isha'), PrayerName.isha);
      expect(PrayerName.of('Sunrise'), isNull);
      expect(PrayerName.of('Midnight'), isNull);
      expect(PrayerName.values.map((p) => p.label), [
        'Fajr',
        'Dhuhr',
        'Asr',
        'Maghrib',
        'Isha',
      ]);
    });

    test('a schedule lists them in order, with Sunrise after Fajr', () {
      expect(PrayerName.scheduleLabels, [
        'Fajr',
        'Sunrise',
        'Dhuhr',
        'Asr',
        'Maghrib',
        'Isha',
      ]);
    });
  });

  group('DefaultAdhanPrayerPolicy', () {
    test('schedules the five prayers, skipping Sunrise', () {
      final times = _schedule([
        at('Fajr', 4),
        at('Sunrise', 6),
        at('Dhuhr', 12),
        at('Asr', 15),
        at('Maghrib', 18),
        at('Isha', 20),
      ]);

      final adhans = DefaultAdhanPrayerPolicy().adhanTimes(times);

      expect(adhans.map((a) => a.name), [
        'Fajr',
        'Dhuhr',
        'Asr',
        'Maghrib',
        'Isha',
      ]);
      expect(adhans.where((a) => a.isFajr).map((a) => a.name), ['Fajr']);
    });
  });

  group('AdhanNextPrayerCalculator', () {
    test('picks the earliest prayer still ahead', () {
      final now = DateTime.now();
      final times = _schedule([
        Prayer(name: 'Fajr', time: now.subtract(const Duration(hours: 2))),
        Prayer(name: 'Dhuhr', time: now.add(const Duration(hours: 1))),
        Prayer(name: 'Asr', time: now.add(const Duration(hours: 4))),
      ]);

      expect(AdhanNextPrayerCalculator().findNext(times)?.name, 'Dhuhr');
    });

    test('never picks Sunrise', () {
      final now = DateTime.now();
      final times = _schedule([
        Prayer(name: 'Sunrise', time: now.add(const Duration(minutes: 10))),
        Prayer(name: 'Dhuhr', time: now.add(const Duration(hours: 3))),
      ]);

      expect(AdhanNextPrayerCalculator().findNext(times)?.name, 'Dhuhr');
    });

    test('returns null once the day is done', () {
      final now = DateTime.now();
      final times = _schedule([
        Prayer(name: 'Isha', time: now.subtract(const Duration(minutes: 5))),
      ]);

      expect(AdhanNextPrayerCalculator().findNext(times), isNull);
    });
  });
}
