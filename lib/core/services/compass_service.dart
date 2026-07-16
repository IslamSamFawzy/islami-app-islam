import 'package:flutter_compass/flutter_compass.dart';

/// One sample from the device compass.
///
/// [heading] is `null` when the platform has no usable magnetometer (or has
/// not produced a fix yet); the UI treats a persistent `null` as "no compass".
class CompassReading {
  /// Degrees clockwise from north, `0..360`. `null` when unavailable.
  ///
  /// On iOS this is already **true** north (CoreLocation `trueHeading`); on
  /// Android it is **magnetic** north (see the declination note in
  /// `QiblaCubit`).
  final double? heading;

  /// Deviation error `±` degrees around [heading]; `null` when the sensor
  /// reports itself as unreliable. Larger means less trustworthy.
  final double? accuracy;

  const CompassReading({this.heading, this.accuracy});
}

/// Thin wrapper around [FlutterCompass] — mirrors [LocationService] in style so
/// the presentation layer depends on our own type, not the plugin.
class CompassService {
  /// Stream of compass readings. Yields an empty stream on platforms without a
  /// compass channel (e.g. web/desktop) so listeners simply never fire.
  Stream<CompassReading> get readings =>
      FlutterCompass.events?.map(
        (e) => CompassReading(heading: e.heading, accuracy: e.accuracy),
      ) ??
      const Stream<CompassReading>.empty();
}
