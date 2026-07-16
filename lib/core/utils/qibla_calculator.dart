import 'dart:math' as math;

/// Pure, dependency-free Qibla maths. No Flutter imports so it stays unit
/// testable on the Dart VM.
///
/// Everything here is relative to **true north** (geographic north). The gap
/// between true north and the magnetic north a phone's compass reports
/// (magnetic declination) is handled outside this file — see the note in
/// `QiblaCubit`.
abstract class QiblaCalculator {
  /// Kaaba (Mecca) coordinates, in degrees.
  static const double kaabaLat = 21.4225;
  static const double kaabaLng = 39.8262;

  /// Mean Earth radius in km (matches the value used for the haversine below).
  static const double _earthRadiusKm = 6371.0;

  static double _deg2rad(double deg) => deg * math.pi / 180.0;
  static double _rad2deg(double rad) => rad * 180.0 / math.pi;

  /// Great-circle **initial bearing** from ([latitude], [longitude]) to the
  /// Kaaba, in degrees clockwise from true north, normalised to `[0, 360)`.
  ///
  /// At the Kaaba itself the direction is undefined; this returns `0`.
  static double qiblaBearing({
    required double latitude,
    required double longitude,
  }) {
    final phi1 = _deg2rad(latitude);
    final phi2 = _deg2rad(kaabaLat);
    final deltaLambda = _deg2rad(kaabaLng - longitude);

    final y = math.sin(deltaLambda) * math.cos(phi2);
    final x = math.cos(phi1) * math.sin(phi2) -
        math.sin(phi1) * math.cos(phi2) * math.cos(deltaLambda);

    final theta = math.atan2(y, x);
    return (_rad2deg(theta) + 360.0) % 360.0;
  }

  /// Great-circle (haversine) distance from ([latitude], [longitude]) to the
  /// Kaaba, in kilometres.
  static double distanceToKaabaKm({
    required double latitude,
    required double longitude,
  }) {
    final phi1 = _deg2rad(latitude);
    final phi2 = _deg2rad(kaabaLat);
    final dPhi = _deg2rad(kaabaLat - latitude);
    final dLambda = _deg2rad(kaabaLng - longitude);

    final a = math.sin(dPhi / 2) * math.sin(dPhi / 2) +
        math.cos(phi1) * math.cos(phi2) * math.sin(dLambda / 2) *
            math.sin(dLambda / 2);
    final c = 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a));
    return _earthRadiusKm * c;
  }

  /// 8-point compass label (N, NE, E, …) for a [bearing] in degrees.
  static String cardinal(double bearing) {
    const points = ['N', 'NE', 'E', 'SE', 'S', 'SW', 'W', 'NW'];
    final normalised = ((bearing % 360) + 360) % 360;
    final index = ((normalised + 22.5) ~/ 45) % 8;
    return points[index];
  }
}
