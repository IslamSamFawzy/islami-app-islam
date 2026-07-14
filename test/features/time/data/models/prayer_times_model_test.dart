import 'package:flutter_test/flutter_test.dart';
import 'package:islami/features/time/data/models/prayer_times_model.dart';
import 'package:islami/features/time/domain/entities/prayer_times.dart';

void main() {
  test('PrayerTimesModel round-trips through toJson/fromJson', () {
    final model = PrayerTimesModel(
      weekday: 'Tuesday',
      gregorianDate: '16 Jul',
      gregorianYear: '2024',
      hijriDate: '09 Muh',
      hijriYear: '1446',
      prayers: [
        Prayer(name: 'Fajr', time: DateTime(2024, 7, 16, 4, 24)),
        Prayer(name: 'Dhuhr', time: DateTime(2024, 7, 16, 12, 59)),
        Prayer(name: 'Isha', time: DateTime(2024, 7, 16, 20, 15)),
      ],
    );

    expect(PrayerTimesModel.fromJson(model.toJson()), model);
  });
}
