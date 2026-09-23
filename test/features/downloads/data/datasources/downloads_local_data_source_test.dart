import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:islami/core/cache/json_store.dart';
import 'package:islami/features/downloads/data/datasources/downloads_local_data_source.dart';
import 'package:islami/features/downloads/data/models/download_entry_model.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late DownloadsLocalDataSourceImpl ds;

  DownloadEntryModel entry(String r, String s) => DownloadEntryModel(
        reciterId: r,
        reciterName: 'Reciter $r',
        suraId: s,
        path: '/audio/$r/$s.mp3',
        bytes: 100,
        downloadedAt: DateTime(2026, 1, 1),
      );

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    ds = DownloadsLocalDataSourceImpl(
      jsonStore: JsonStore(
        sharedPreferences: await SharedPreferences.getInstance(),
      ),
    );
  });

  test('put then get/getAll', () async {
    await ds.put(entry('1', '2'));
    await ds.put(entry('1', '3'));

    expect(ds.get('1', '2'), entry('1', '2'));
    expect(ds.getAll().length, 2);
  });

  test('remove drops a single entry', () async {
    await ds.put(entry('1', '2'));
    await ds.put(entry('1', '3'));

    await ds.remove('1', '2');

    expect(ds.get('1', '2'), isNull);
    expect(ds.getAll().length, 1);
  });

  test('reads an index written under the pre-existing storage key', () async {
    // The key is part of the app's on-disk contract: change it and every
    // user's downloads disappear from the library.
    SharedPreferences.setMockInitialValues({
      'downloads_index': json.encode({'1/2': entry('1', '2').toJson()}),
    });
    ds = DownloadsLocalDataSourceImpl(
      jsonStore: JsonStore(
        sharedPreferences: await SharedPreferences.getInstance(),
      ),
    );

    expect(ds.get('1', '2'), entry('1', '2'));
  });

  test('removeReciter drops every entry for that reciter', () async {
    await ds.put(entry('1', '2'));
    await ds.put(entry('1', '3'));
    await ds.put(entry('9', '2'));

    await ds.removeReciter('1');

    expect(ds.getAll().map((e) => e.reciterId).toSet(), {'9'});
  });
}
