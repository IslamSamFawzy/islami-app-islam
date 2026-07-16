import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:geolocator/geolocator.dart';
import 'package:islami/core/cache/cache_manager.dart';
import 'package:islami/core/error/exceptions.dart';
import 'package:islami/core/services/compass_service.dart';
import 'package:islami/core/services/location_service.dart';
import 'package:islami/features/qibla/presentation/cubit/qibla_cubit.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _FakeLocation implements LocationService {
  final Position? position;
  final LocationException? error;

  _FakeLocation({this.position, this.error});

  @override
  Future<Position> getCurrentPosition() async {
    if (error != null) throw error!;
    return position!;
  }
}

class _FakeCompass implements CompassService {
  final controller = StreamController<CompassReading>.broadcast();

  @override
  Stream<CompassReading> get readings => controller.stream;
}

Position _pos(double lat, double lng) => Position(
      latitude: lat,
      longitude: lng,
      timestamp: DateTime(2026),
      accuracy: 1,
      altitude: 0,
      altitudeAccuracy: 0,
      heading: 0,
      headingAccuracy: 0,
      speed: 0,
      speedAccuracy: 0,
    );

// Lets the broadcast compass reading propagate to the cubit's listener.
Future<void> _settle() => Future<void>.delayed(const Duration(milliseconds: 1));

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late CacheManager cache;

  Future<CacheManager> freshCache() async {
    SharedPreferences.setMockInitialValues({});
    return CacheManager(sharedPreferences: await SharedPreferences.getInstance());
  }

  setUp(() async {
    cache = await freshCache();
  });

  test('resolves location, computes the Qibla, and caches the coordinates',
      () async {
    final cubit = QiblaCubit(
      locationService: _FakeLocation(position: _pos(30.0444, 31.2357)), // Cairo
      compassService: _FakeCompass(),
      cacheManager: cache,
    );

    await cubit.init();

    expect(cubit.state.status, QiblaStatus.ready);
    expect(cubit.state.qiblaBearing, closeTo(136.14, 0.5));
    expect(cubit.state.distanceKm, closeTo(1287.2, 2));
    expect(cubit.state.usingCachedLocation, isFalse);

    // Coordinates were written to the cache for offline reuse.
    final data = cache.read('qibla_last_location')?['data'] as Map;
    expect(data['lat'], closeTo(30.0444, 0.0001));
    expect(data['lng'], closeTo(31.2357, 0.0001));

    await cubit.close();
  });

  test('alignment fires once per crossing and tracks accuracy', () async {
    final compass = _FakeCompass();
    final cubit = QiblaCubit(
      locationService: _FakeLocation(position: _pos(30.0444, 31.2357)),
      compassService: compass,
      cacheManager: cache,
    );
    await cubit.init(); // qiblaBearing ≈ 136.14

    // Pointing at the Qibla → aligned, seq bumps once, good accuracy.
    compass.controller.add(const CompassReading(heading: 136, accuracy: 15));
    await _settle();
    expect(cubit.state.isAligned, isTrue);
    expect(cubit.state.alignedSeq, 1);
    expect(cubit.state.hasCompass, isTrue);
    expect(cubit.state.lowAccuracy, isFalse);

    // Turning away → not aligned, seq unchanged.
    compass.controller.add(const CompassReading(heading: 100, accuracy: 15));
    await _settle();
    expect(cubit.state.isAligned, isFalse);
    expect(cubit.state.alignedSeq, 1);

    // Coming back → new crossing bumps the seq again (drives the haptic).
    compass.controller.add(const CompassReading(heading: 137, accuracy: 15));
    await _settle();
    expect(cubit.state.isAligned, isTrue);
    expect(cubit.state.alignedSeq, 2);

    // Medium accuracy → calibration hint.
    compass.controller.add(const CompassReading(heading: 137, accuracy: 30));
    await _settle();
    expect(cubit.state.lowAccuracy, isTrue);

    // Unreliable (null) accuracy → also low.
    compass.controller.add(const CompassReading(heading: 137, accuracy: null));
    await _settle();
    expect(cubit.state.lowAccuracy, isTrue);

    await cubit.close();
  });

  test('denied permission maps to permissionDenied (no cache)', () async {
    final cubit = QiblaCubit(
      locationService:
          _FakeLocation(error: const LocationException('Location permission denied')),
      compassService: _FakeCompass(),
      cacheManager: cache,
    );

    await cubit.init();

    expect(cubit.state.status, QiblaStatus.permissionDenied);
    await cubit.close();
  });

  test('disabled services map to serviceDisabled (no cache)', () async {
    final cubit = QiblaCubit(
      locationService: _FakeLocation(
          error: const LocationException('Location services are disabled')),
      compassService: _FakeCompass(),
      cacheManager: cache,
    );

    await cubit.init();

    expect(cubit.state.status, QiblaStatus.serviceDisabled);
    await cubit.close();
  });

  test('falls back to cached coordinates when a fresh fix fails', () async {
    await cache.write('qibla_last_location', {'lat': 30.0444, 'lng': 31.2357});

    final cubit = QiblaCubit(
      locationService: _FakeLocation(
          error: const LocationException('Location services are disabled')),
      compassService: _FakeCompass(),
      cacheManager: cache,
    );

    await cubit.init();

    // Offline, but still fully usable from the last known location.
    expect(cubit.state.status, QiblaStatus.ready);
    expect(cubit.state.usingCachedLocation, isTrue);
    expect(cubit.state.qiblaBearing, closeTo(136.14, 0.5));
    await cubit.close();
  });
}
