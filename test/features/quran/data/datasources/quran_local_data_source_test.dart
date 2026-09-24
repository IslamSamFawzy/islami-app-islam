import 'package:flutter_test/flutter_test.dart';
import 'package:islami/features/quran/data/datasources/quran_local_data_source.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late SharedPreferences prefs;
  late QuranLocalDataSourceImpl ds;

  Future<void> build([Map<String, Object> initial = const {}]) async {
    SharedPreferences.setMockInitialValues(initial);
    prefs = await SharedPreferences.getInstance();
    ds = QuranLocalDataSourceImpl(sharedPreferences: prefs);
  }

  setUp(() => build());

  test('the sura list carries numbers, not strings', () async {
    final suras = await ds.getAllSuras();

    expect(suras.length, 114);
    expect(suras.first.id, 1);
    expect(suras.first.ayaCount, 7);
    expect(suras.last.id, 114);
  });

  test('recents keep their stored string form, newest first', () async {
    await ds.addRecentSuraId(2);
    await ds.addRecentSuraId(36);

    // The on-disk shape is unchanged, so an update does not lose anyone's
    // recents.
    expect(prefs.getStringList('recent_sura_ids'), ['36', '2']);
    expect(await ds.getRecentSuraIds(), [36, 2]);
  });

  test('re-reading a sura moves it to the front without duplicating', () async {
    await ds.addRecentSuraId(2);
    await ds.addRecentSuraId(36);
    await ds.addRecentSuraId(2);

    expect(await ds.getRecentSuraIds(), [2, 36]);
  });

  test('recents are capped at ten', () async {
    for (var i = 1; i <= 12; i++) {
      await ds.addRecentSuraId(i);
    }

    final recents = await ds.getRecentSuraIds();
    expect(recents.length, 10);
    expect(recents.first, 12);
  });

  test('a list written by an older version still reads', () async {
    await build({
      'recent_sura_ids': ['18', 'not-a-number', '2'],
    });

    expect(await ds.getRecentSuraIds(), [18, 2]);
  });
}
