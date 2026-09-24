import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:geolocator/geolocator.dart';
// Prefixed: geolocator ships exception types with these very names.
import 'package:islami/core/error/exceptions.dart' as app;
import 'package:islami/core/services/location_service.dart';

/// Stands in for the platform plugin, so the service can be driven without a
/// device. Every geolocator call the service makes lands here.
class _FakeGeolocatorPlatform extends GeolocatorPlatform {
  _FakeGeolocatorPlatform({
    this.serviceEnabled = true,
    this.permission = LocationPermission.whileInUse,
    this.lastKnown,
    this.current,
    this.currentError,
  });

  final bool serviceEnabled;
  final LocationPermission permission;
  final Position? lastKnown;
  final Position? current;
  final Object? currentError;

  int currentCalls = 0;
  LocationSettings? lastSettings;

  @override
  Future<bool> isLocationServiceEnabled() async => serviceEnabled;

  @override
  Future<LocationPermission> checkPermission() async => permission;

  @override
  Future<LocationPermission> requestPermission() async => permission;

  @override
  Future<Position?> getLastKnownPosition({
    bool forceLocationManager = false,
  }) async =>
      lastKnown;

  @override
  Future<Position> getCurrentPosition({
    LocationSettings? locationSettings,
  }) async {
    currentCalls++;
    lastSettings = locationSettings;
    if (currentError != null) {
      throw currentError!;
    }
    return current!;
  }
}

Position _position(DateTime timestamp, {double lat = 30.0444, double lng = 31.2357}) {
  return Position(
    latitude: lat,
    longitude: lng,
    timestamp: timestamp,
    accuracy: 100,
    altitude: 22,
    altitudeAccuracy: 5,
    heading: 0,
    headingAccuracy: 0,
    speed: 0,
    speedAccuracy: 0,
  );
}

void main() {
  final service = GeolocatorLocationService();

  test('a recent last known fix is used without asking for a new one', () async {
    final fake = _FakeGeolocatorPlatform(
      lastKnown: _position(DateTime.now().subtract(const Duration(minutes: 1))),
    );
    GeolocatorPlatform.instance = fake;

    final point = await service.getCurrentPosition();

    expect(point.latitude, closeTo(30.0444, 1e-6));
    expect(point.longitude, closeTo(31.2357, 1e-6));
    expect(point.altitude, 22);
    expect(fake.currentCalls, 0, reason: 'a recent fix is enough');
  });

  test('a stale last known fix is ignored and a fresh one requested', () async {
    final fake = _FakeGeolocatorPlatform(
      lastKnown: _position(
        DateTime.now().subtract(const Duration(hours: 3)),
        lat: 1,
        lng: 2,
      ),
      current: _position(DateTime.now()),
    );
    GeolocatorPlatform.instance = fake;

    final point = await service.getCurrentPosition();

    expect(point.latitude, closeTo(30.0444, 1e-6));
    expect(fake.currentCalls, 1);
  });

  test('with no last known fix it asks the platform, under a time limit', () async {
    final fake = _FakeGeolocatorPlatform(current: _position(DateTime.now()));
    GeolocatorPlatform.instance = fake;

    await service.getCurrentPosition();

    expect(fake.currentCalls, 1);
    expect(
      fake.lastSettings?.timeLimit,
      GeolocatorLocationService.fixTimeout,
      reason: 'without a limit the platform call can hang forever',
    );
  });

  test('a fix that never arrives becomes a LocationTimeoutException', () async {
    GeolocatorPlatform.instance = _FakeGeolocatorPlatform(
      currentError: TimeoutException('no fix', const Duration(seconds: 15)),
    );

    await expectLater(
      service.getCurrentPosition(),
      throwsA(isA<app.LocationTimeoutException>()),
    );
    // Callers catch the base type, so the fallbacks keep working.
    await expectLater(
      service.getCurrentPosition(),
      throwsA(isA<app.LocationException>()),
    );
  });

  test('a failing last known lookup still falls through to a fresh fix', () async {
    GeolocatorPlatform.instance = _FakeThrowingLastKnown(
      current: _position(DateTime.now()),
    );

    final point = await service.getCurrentPosition();

    expect(point.latitude, closeTo(30.0444, 1e-6));
  });

  test('location switched off throws LocationServiceDisabledException', () async {
    GeolocatorPlatform.instance =
        _FakeGeolocatorPlatform(serviceEnabled: false);

    await expectLater(
      service.getCurrentPosition(),
      throwsA(isA<app.LocationServiceDisabledException>()),
    );
  });

  test('a refused permission throws LocationPermissionDeniedException', () async {
    GeolocatorPlatform.instance = _FakeGeolocatorPlatform(
      permission: LocationPermission.deniedForever,
    );

    await expectLater(
      service.getCurrentPosition(),
      throwsA(isA<app.LocationPermissionDeniedException>()),
    );
  });
}

/// The last-known lookup is only a shortcut: when the platform throws there,
/// the service must carry on rather than fail.
class _FakeThrowingLastKnown extends _FakeGeolocatorPlatform {
  _FakeThrowingLastKnown({super.current});

  @override
  Future<Position?> getLastKnownPosition({
    bool forceLocationManager = false,
  }) async =>
      throw Exception('platform refused');
}
