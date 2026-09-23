import 'package:flutter_test/flutter_test.dart';
import 'package:islami/core/cache/json_store.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late SharedPreferences prefs;
  late JsonStore store;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    prefs = await SharedPreferences.getInstance();
    store = JsonStore(sharedPreferences: prefs);
  });

  test('writeMap then readMap round-trips, under the key as given', () async {
    final index = {
      '1/2': {'suraId': '2', 'bytes': 10},
    };
    await store.writeMap('downloads_index', index);

    // No namespacing: the key on disk is exactly the one that was asked for.
    expect(prefs.getString('downloads_index'), isNotNull);
    expect(store.readMap('downloads_index'), index);
  });

  test('readMap returns an empty map when absent, corrupt or not a map',
      () async {
    expect(store.readMap('missing'), isEmpty);

    await prefs.setString('junk', 'not json at all');
    expect(store.readMap('junk'), isEmpty);

    await prefs.setString('list', '[1, 2]');
    expect(store.readMap('list'), isEmpty);
  });
}
