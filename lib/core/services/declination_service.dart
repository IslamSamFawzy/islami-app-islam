import 'dart:io' show Platform;

import 'package:flutter/services.dart';

/// Provides the magnetic declination (degrees, east positive) used to turn a
/// magnetic-north heading into a true-north one.
///
/// Backed by Android's [GeomagneticField](https://developer.android.com/reference/android/hardware/GeomagneticField)
/// over a [MethodChannel] — Google's own WMM, so no dependency and no data
/// table to trust. Returns `0` on any failure and on non-Android platforms
/// (iOS already reports `trueHeading`, so it must not be corrected again).
class DeclinationService {
  static const MethodChannel _channel = MethodChannel('islami/geomagnetic');

  Future<double> getDeclination({
    required double latitude,
    required double longitude,
    double altitude = 0,
  }) async {
    if (!Platform.isAndroid) return 0;
    try {
      final value = await _channel.invokeMethod<double>('getDeclination', {
        'lat': latitude,
        'lng': longitude,
        'altitude': altitude,
      });
      return value ?? 0;
    } catch (_) {
      // Never block the compass on a declination lookup — fall back to 0.
      return 0;
    }
  }
}
