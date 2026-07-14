import 'package:flutter_test/flutter_test.dart';
import 'package:islami/features/radio/data/models/radio_station_model.dart';
import 'package:islami/features/radio/data/models/reciter_model.dart';

void main() {
  group('RadioStationModel', () {
    test('round-trips through toJson/fromJson', () {
      const model = RadioStationModel(
        id: 7,
        name: 'إذاعة القرآن الكريم',
        url: 'https://stream.example/quran',
      );
      expect(RadioStationModel.fromJson(model.toJson()), model);
    });
  });

  group('ReciterModel', () {
    test('round-trips through toJson/fromJson', () {
      const model = ReciterModel(
        id: 3,
        name: 'عبد الرحمن السديس',
        playUrl: 'https://server.mp3quran.net/sds/001.mp3',
      );
      expect(ReciterModel.fromJson(model.toJson()), model);
    });

    test('fromApi derives a sample playUrl from the first moshaf server', () {
      final model = ReciterModel.fromApi({
        'id': 3,
        'name': 'عبد الرحمن السديس',
        'moshaf': [
          {'server': 'https://server.mp3quran.net/sds'},
        ],
      });
      expect(model.playUrl, 'https://server.mp3quran.net/sds/001.mp3');
    });
  });
}
