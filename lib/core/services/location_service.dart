import 'dart:async';

import 'package:equatable/equatable.dart';
// Prefixed: the plugin has its own exception types with these very names, and
// the app's own (from core/error) are the ones this service throws.
import 'package:geolocator/geolocator.dart' as geo;

import '../error/exceptions.dart';

/// A point on the globe, in the app's own terms — callers never see the
/// location plugin's `Position`.
class GeoPoint extends Equatable {
  final double latitude;
  final double longitude;

  /// Metres above sea level; 0 when the fix carries none.
  final double altitude;

  const GeoPoint({
    required this.latitude,
    required this.longitude,
    this.altitude = 0,
  });

  @override
  List<Object?> get props => [latitude, longitude, altitude];
}

/// Contract for resolving the device's current position.
abstract class LocationService {
  /// Throws [LocationServiceDisabledException] when location is switched off
  /// on the device, [LocationPermissionDeniedException] when the user has
  /// refused the permission, and [LocationTimeoutException] when no fix
  /// arrives in reasonable time. All three are [LocationException]s, so a
  /// caller that only wants "no location" can catch the base type.
  Future<GeoPoint> getCurrentPosition();
}

/// [LocationService] implementation backed by the geolocator plugin.
class GeolocatorLocationService implements LocationService {
  /// A fix the platform already holds counts as current while it is this
  /// young. Prayer times and the Qibla only need the city, so a fix from the
  /// last few minutes is as good as a fresh one — and it returns at once.
  static const Duration lastFixMaxAge = Duration(minutes: 5);

  /// How long to wait for a fresh fix. Without a limit the platform call can
  /// hang indefinitely (indoors, no GPS signal), which leaves the caller on a
  /// spinner with no way out.
  static const Duration fixTimeout = Duration(seconds: 15);

  @override
  Future<GeoPoint> getCurrentPosition() async {
    final serviceEnabled = await geo.Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      throw const LocationServiceDisabledException();
    }

    var permission = await geo.Geolocator.checkPermission();
    if (permission == geo.LocationPermission.denied) {
      permission = await geo.Geolocator.requestPermission();
    }

    if (permission == geo.LocationPermission.denied ||
        permission == geo.LocationPermission.deniedForever) {
      throw const LocationPermissionDeniedException();
    }

    final recent = await _lastKnownIfRecent();
    if (recent != null) {
      return recent;
    }

    try {
      final position = await geo.Geolocator.getCurrentPosition(
        locationSettings: const geo.LocationSettings(
          accuracy: geo.LocationAccuracy.low,
          timeLimit: fixTimeout,
        ),
      );
      return _toGeoPoint(position);
    } on TimeoutException {
      throw const LocationTimeoutException();
    }
  }

  /// The platform's last fix, when it is young enough to use. This is only a
  /// shortcut, so any failure here falls through to a fresh fix.
  Future<GeoPoint?> _lastKnownIfRecent() async {
    try {
      final last = await geo.Geolocator.getLastKnownPosition();
      if (last == null) {
        return null;
      }
      final age = DateTime.now().difference(last.timestamp);
      if (age > lastFixMaxAge) {
        return null;
      }
      return _toGeoPoint(last);
    } catch (_) {
      return null;
    }
  }

  GeoPoint _toGeoPoint(geo.Position position) => GeoPoint(
        latitude: position.latitude,
        longitude: position.longitude,
        altitude: position.altitude,
      );
}
