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
  /// on the device, and [LocationPermissionDeniedException] when the user has
  /// refused the permission.
  Future<GeoPoint> getCurrentPosition();
}

/// [LocationService] implementation backed by the geolocator plugin.
class GeolocatorLocationService implements LocationService {
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

    final position = await geo.Geolocator.getCurrentPosition(
      locationSettings: const geo.LocationSettings(
        accuracy: geo.LocationAccuracy.low,
      ),
    );
    return GeoPoint(
      latitude: position.latitude,
      longitude: position.longitude,
      altitude: position.altitude,
    );
  }
}
