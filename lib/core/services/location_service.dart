import 'package:geolocator/geolocator.dart';

import '../error/exceptions.dart';

/// Contract for resolving the device's current position.
abstract class LocationService {
  Future<Position> getCurrentPosition();
}

/// [LocationService] implementation backed by the geolocator plugin.
class GeolocatorLocationService implements LocationService {
  @override
  Future<Position> getCurrentPosition() async {
    final serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      throw const LocationException('Location services are disabled');
    }

    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }

    if (permission == LocationPermission.denied ||
        permission == LocationPermission.deniedForever) {
      throw const LocationException('Location permission denied');
    }

    return Geolocator.getCurrentPosition(
      locationSettings: const LocationSettings(accuracy: LocationAccuracy.low),
    );
  }
}
