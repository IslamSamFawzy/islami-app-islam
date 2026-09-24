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

    test('a cleartext stream URL is upgraded to https', () {
      // One factory serves both the API and the cache, so this covers a
      // cleartext URL from either.
      final model = RadioStationModel.fromJson({
        'id': 7,
        'name': 'إذاعة القرآن الكريم',
        'url': 'http://stream.radiojar.com/8s5u5tpdtwzuv',
      });

      expect(model.url, 'https://stream.radiojar.com/8s5u5tpdtwzuv');
    });

    test('an https stream URL is left exactly as it is', () {
      final model = RadioStationModel.fromJson({
        'id': 7,
        'name': 'x',
        'url': 'https://stream.radiojar.com/8s5u5tpdtwzuv',
      });

      expect(model.url, 'https://stream.radiojar.com/8s5u5tpdtwzuv');
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

    test('fromApi upgrades a cleartext server to https', () {
      // Android blocks cleartext, so an http:// server from the API would
      // silently break that reciter's streams and downloads.
      final model = ReciterModel.fromApi({
        'id': 41,
        'name': 'محمود خليل الحصري',
        'moshaf': [
          {
            'server': 'http://server12.mp3quran.net/tblawi/Al-Mojawwad/',
            'surah_list': '1,2',
          },
        ],
      });

      expect(
        model.moshafServer,
        'https://server12.mp3quran.net/tblawi/Al-Mojawwad/',
      );
      expect(model.audioUrlFor(1), startsWith('https://'));
    });

    test('fromJson upgrades a cleartext server cached by an older build', () {
      final model = ReciterModel.fromJson({
        'id': 41,
        'name': 'محمود خليل الحصري',
        'moshafServer': 'http://server12.mp3quran.net/tblawi/Al-Mojawwad/',
        'surahList': [1, 2],
      });

      expect(model.moshafServer, startsWith('https://'));
    });

    test('an https server is left exactly as it is', () {
      final model = ReciterModel.fromApi({
        'id': 3,
        'name': 'x',
        'moshaf': [
          {'server': 'https://server.mp3quran.net/sds/', 'surah_list': '1'},
        ],
      });

      expect(model.moshafServer, 'https://server.mp3quran.net/sds/');
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
