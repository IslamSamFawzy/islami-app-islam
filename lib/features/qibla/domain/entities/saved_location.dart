import 'package:equatable/equatable.dart';

/// Where the Qibla was last worked out from, kept so the screen still works
/// with no connection and no fresh fix.
class SavedLocation extends Equatable {
  final double latitude;
  final double longitude;

  /// Magnetic declination there, in degrees. Saved alongside the coordinates
  /// because it is looked up from them and changes very slowly.
  final double declination;

  const SavedLocation({
    required this.latitude,
    required this.longitude,
    this.declination = 0,
  });

  @override
  List<Object?> get props => [latitude, longitude, declination];
}
