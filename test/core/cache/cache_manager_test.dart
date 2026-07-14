import 'package:flutter_test/flutter_test.dart';
import 'package:islami/core/cache/cache_manager.dart';
import 'package:islami/core/error/exceptions.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late CacheManager cache;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    cache = CacheManager(sharedPreferences: await SharedPreferences.getInstance());
  });

  test('write then read returns the payload in a timestamped envelope', () async {
    final payload = [
      {'id': 1, 'name': 'A', 'url': 'u'},
    ];
    await cache.write('radios', payload);

    final envelope = cache.read('radios');
    expect(envelope, isNotNull);
    expect(envelope!['data'], payload);
    expect(cache.cachedAt('radios'), isA<DateTime>());
  });

  test('read returns null for an absent key', () {
    expect(cache.read('missing'), isNull);
    expect(cache.cachedAt('missing'), isNull);
  });

  test('isStale is true when missing and false when fresh', () async {
    expect(cache.isStale('missing', const Duration(days: 7)), isTrue);
    await cache.write('k', {'a': 1});
    expect(cache.isStale('k', const Duration(days: 7)), isFalse);
  });

  test('write throws CacheException on a non-serialisable payload', () {
    expect(
      () => cache.write('bad', {'fn': () {}}),
      throwsA(isA<CacheException>()),
    );
  });

  test('clearAll wipes cache entries but leaves other prefs intact', () async {
    SharedPreferences.setMockInitialValues({
      'recent_sura_ids': ['1', '2'],
    });
    final prefs = await SharedPreferences.getInstance();
    cache = CacheManager(sharedPreferences: prefs);

    await cache.write('radios', {'a': 1});
    await cache.clearAll();

    expect(cache.read('radios'), isNull);
    expect(prefs.getStringList('recent_sura_ids'), ['1', '2']);
  });
}
