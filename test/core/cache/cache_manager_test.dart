import 'dart:convert';

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

  test('writeList then readList round-trips the items', () async {
    await cache.writeList('radios', const [1, 2], (n) => {'id': n});

    expect(cache.readList('radios', (j) => j['id'] as int), [1, 2]);
  });

  test('readList returns null past the TTL, and ignores age without one',
      () async {
    SharedPreferences.setMockInitialValues({
      'cache_radios': json.encode({
        'cachedAt': DateTime.now()
            .subtract(const Duration(days: 8))
            .toIso8601String(),
        'data': [
          {'id': 1},
        ],
      }),
    });
    cache = CacheManager(
      sharedPreferences: await SharedPreferences.getInstance(),
    );

    expect(
      cache.readList(
        'radios',
        (j) => j['id'] as int,
        ttl: const Duration(days: 7),
      ),
      isNull,
    );
    expect(cache.readList('radios', (j) => j['id'] as int), [1]);
  });

  test('readList returns null when the entry is missing or unparsable',
      () async {
    expect(cache.readList('missing', (j) => j['id'] as int), isNull);

    await cache.write('radios', {'not': 'a list'});
    expect(cache.readList('radios', (j) => j['id'] as int), isNull);

    await cache.writeList('radios', const [1], (n) => {'id': n});
    expect(cache.readList('radios', (j) => j['nope'] as int), isNull);
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
