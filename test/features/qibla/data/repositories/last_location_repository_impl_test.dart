import 'package:flutter_test/flutter_test.dart';
import 'package:islami/core/cache/cache_manager.dart';
import 'package:islami/features/qibla/data/repositories/last_location_repository_impl.dart';
import 'package:islami/features/qibla/domain/entities/saved_location.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late CacheManager cache;
  late LastLocationRepositoryImpl repository;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    cache = CacheManager(
      sharedPreferences: await SharedPreferences.getInstance(),
    );
    repository = LastLocationRepositoryImpl(cacheManager: cache);
  });

  test('round-trips a saved location', () async {
    const location = SavedLocation(
      latitude: 30.0444,
      longitude: 31.2357,
      declination: 5,
    );

    await repository.save(location);

    expect(repository.read(), location);
  });

  test('reads what an earlier version stored, under the same key', () async {
    await cache.write('qibla_last_location', {
      'lat': 21.4225,
      'lng': 39.8262,
      'declination': 3.5,
    });

    expect(
      repository.read(),
      const SavedLocation(
        latitude: 21.4225,
        longitude: 39.8262,
        declination: 3.5,
      ),
    );
  });

  test('returns null when there is nothing, or the entry is unusable',
      () async {
    expect(repository.read(), isNull);

    await cache.write('qibla_last_location', {'lat': 'north'});
    expect(repository.read(), isNull);
  });

  test('a location saved without a declination reads back as zero', () async {
    await cache.write('qibla_last_location', {'lat': 30.0, 'lng': 31.0});

    expect(repository.read()?.declination, 0);
  });
}
