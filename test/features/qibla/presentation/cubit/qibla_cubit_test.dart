import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:islami/core/cache/cache_manager.dart';
import 'package:islami/core/error/exceptions.dart';
import 'package:islami/core/services/compass_service.dart';
import 'package:islami/core/services/declination_service.dart';
import 'package:islami/core/services/location_service.dart';
import 'package:islami/features/qibla/presentation/cubit/qibla_cubit.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _FakeLocation implements LocationService {
  final GeoPoint? position;
  final LocationException? error;

  _FakeLocation({this.position, this.error});

  @override
  Future<GeoPoint> getCurrentPosition() async {
    if (error != null) throw error!;
    return position!;
  }
}

class _FakeCompass implements CompassService {
  final controller = StreamController<CompassReading>.broadcast();

  @override
  Stream<CompassReading> get readings => controller.stream;
}

class _FakeDeclination implements DeclinationService {
  final double value;
  int calls = 0;

  _FakeDeclination([this.value = 0]);

  @override
  Future<double> getDeclination({
    required double latitude,
    required double longitude,
    double altitude = 0,
  }) async {
    calls++;
    return value;
  }
}

GeoPoint _pos(double lat, double lng) =>
    GeoPoint(latitude: lat, longitude: lng);

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

  QiblaCubit build({
    _FakeLocation? location,
    _FakeCompass? compass,
    _FakeDeclination? declination,
  }) =>
      QiblaCubit(
        locationService: location ?? _FakeLocation(position: _pos(30.0444, 31.2357)),
        compassService: compass ?? _FakeCompass(),
        declinationService: declination ?? _FakeDeclination(),
        cacheManager: cache,
      );

  test('resolves location, computes the Qibla, and caches the coordinates',
      () async {
    final cubit = build(
      location: _FakeLocation(position: _pos(30.0444, 31.2357)), // Cairo
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
    final cubit = build(compass: compass);
    await cubit.init(); // qiblaBearing ≈ 136.14, declination 0

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

  test('applies the magnetic declination to the heading and caches it',
      () async {
    final compass = _FakeCompass();
    final cubit = build(
      compass: compass,
      declination: _FakeDeclination(5), // +5° east
    );
    await cubit.init(); // qiblaBearing ≈ 136.14

    // A magnetic heading of 131° + 5° declination = 136° true → aligned.
    compass.controller.add(const CompassReading(heading: 131, accuracy: 15));
    await _settle();
    expect(cubit.state.isAligned, isTrue);
    // Stored heading is already in the true-north frame.
    expect(cubit.state.heading, closeTo(136, 0.001));

    // The declination is cached alongside the coordinates.
    final data = cache.read('qibla_last_location')?['data'] as Map;
    expect(data['declination'], closeTo(5, 0.001));

    await cubit.close();
  });

  test('reuses the cached declination when offline (no fresh lookup)',
      () async {
    // Seed the cache as if a previous online session had stored everything.
    await cache.write('qibla_last_location',
        {'lat': 30.0444, 'lng': 31.2357, 'declination': 5.0});

    final compass = _FakeCompass();
    final declination = _FakeDeclination(999); // must NOT be used offline
    final cubit = build(
      location: _FakeLocation(
          error: const LocationServiceDisabledException()),
      compass: compass,
      declination: declination,
    );

    await cubit.init();

    expect(cubit.state.status, QiblaStatus.ready);
    expect(cubit.state.usingCachedLocation, isTrue);
    expect(declination.calls, 0); // offline → no channel call

    // The cached +5° is applied: 131° magnetic → 136° true → aligned.
    compass.controller.add(const CompassReading(heading: 131, accuracy: 15));
    await _settle();
    expect(cubit.state.isAligned, isTrue);

    await cubit.close();
  });

  test('denied permission maps to permissionDenied (no cache)', () async {
    final cubit = build(
      location:
          _FakeLocation(error: const LocationPermissionDeniedException()),
    );

    await cubit.init();

    expect(cubit.state.status, QiblaStatus.permissionDenied);
    await cubit.close();
  });

  test('disabled services map to serviceDisabled (no cache)', () async {
    final cubit = build(
      location: _FakeLocation(
          error: const LocationServiceDisabledException()),
    );

    await cubit.init();

    expect(cubit.state.status, QiblaStatus.serviceDisabled);
    await cubit.close();
  });

  test('the exception type decides the status, not its wording', () async {
    // The message used to be searched for the word "disabled"; a differently
    // worded (or localised) message must still land on serviceDisabled.
    final cubit = build(
      location: _FakeLocation(
        error: const LocationServiceDisabledException('Ortung ist aus'),
      ),
    );

    await cubit.init();

    expect(cubit.state.status, QiblaStatus.serviceDisabled);
    expect(cubit.state.errorMessage, 'Ortung ist aus');
    await cubit.close();
  });
}
