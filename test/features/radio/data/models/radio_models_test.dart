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
        moshafServer: 'https://server.mp3quran.net/sds/',
        surahList: [1, 2, 3, 114],
      );
      expect(ReciterModel.fromJson(model.toJson()), model);
    });

    test('fromApi normalises the server and parses surah_list', () {
      final model = ReciterModel.fromApi({
        'id': 3,
        'name': 'عبد الرحمن السديس',
        'moshaf': [
          {
            'server': 'https://server.mp3quran.net/sds', // no trailing slash
            'surah_list': '1,2,3,114',
          },
        ],
      });

      expect(model.moshafServer, 'https://server.mp3quran.net/sds/');
      expect(model.surahList, [1, 2, 3, 114]);
    });

    test('audioUrlFor zero-pads the sura number to three digits', () {
      const model = ReciterModel(
        id: 3,
        name: 'x',
        moshafServer: 'https://server.mp3quran.net/sds/',
        surahList: [2],
      );
      expect(model.audioUrlFor(2), 'https://server.mp3quran.net/sds/002.mp3');
    });
  });
}
