part of 'qibla_cubit.dart';

enum QiblaStatus {
  /// Resolving location.
  loading,

  /// Location known; Qibla computed; compass streaming.
  ready,

  /// Location permission denied.
  permissionDenied,

  /// Location services turned off on the device.
  serviceDisabled,

  /// Anything else went wrong resolving the location.
  error,
}

class QiblaState extends Equatable {
  final QiblaStatus status;

  final double? latitude;
  final double? longitude;

  /// Qibla direction, degrees clockwise from **true** north (`0..360`).
  final double qiblaBearing;

  /// Great-circle distance to the Kaaba, in km.
  final double distanceKm;

  /// Latest device heading in the **true-north** frame (`0..360`), or `null`
  /// before the first reading. See the declination note in [QiblaCubit].
  final double? heading;

  /// True once at least one real heading has arrived.
  final bool hasCompass;

  /// The compass reported medium/low/unreliable accuracy (calibration hint).
  final bool lowAccuracy;

  /// The device is currently pointing within the alignment threshold.
  final bool isAligned;

  /// Increments each time the device crosses *into* alignment — the view
  /// listens on this to fire a single haptic (never per frame).
  final int alignedSeq;

  /// The location came from the cache (offline), not a fresh fix.
  final bool usingCachedLocation;

  /// No heading arrived within the timeout — device likely has no compass.
  final bool sensorTimedOut;

  final String errorMessage;

  const QiblaState({
    this.status = QiblaStatus.loading,
    this.latitude,
    this.longitude,
    this.qiblaBearing = 0,
    this.distanceKm = 0,
    this.heading,
    this.hasCompass = false,
    this.lowAccuracy = false,
    this.isAligned = false,
    this.alignedSeq = 0,
    this.usingCachedLocation = false,
    this.sensorTimedOut = false,
    this.errorMessage = '',
  });

  /// Ready, but the device produced no heading — show a message, not a needle.
  bool get hasNoCompass =>
      status == QiblaStatus.ready && sensorTimedOut && !hasCompass;

  /// Bearing formatted for display, e.g. `136° SE`.
  String get bearingLabel =>
      '${qiblaBearing.round()}° ${QiblaCalculator.cardinal(qiblaBearing)}';

  QiblaState copyWith({
    QiblaStatus? status,
    double? latitude,
    double? longitude,
    double? qiblaBearing,
    double? distanceKm,
    double? heading,
    bool? hasCompass,
    bool? lowAccuracy,
    bool? isAligned,
    int? alignedSeq,
    bool? usingCachedLocation,
    bool? sensorTimedOut,
    String? errorMessage,
  }) {
    return QiblaState(
      status: status ?? this.status,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      qiblaBearing: qiblaBearing ?? this.qiblaBearing,
      distanceKm: distanceKm ?? this.distanceKm,
      heading: heading ?? this.heading,
      hasCompass: hasCompass ?? this.hasCompass,
      lowAccuracy: lowAccuracy ?? this.lowAccuracy,
      isAligned: isAligned ?? this.isAligned,
      alignedSeq: alignedSeq ?? this.alignedSeq,
      usingCachedLocation: usingCachedLocation ?? this.usingCachedLocation,
      sensorTimedOut: sensorTimedOut ?? this.sensorTimedOut,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }

  @override
  List<Object?> get props => [
        status,
        latitude,
        longitude,
        qiblaBearing,
        distanceKm,
        heading,
        hasCompass,
        lowAccuracy,
        isAligned,
        alignedSeq,
        usingCachedLocation,
        sensorTimedOut,
        errorMessage,
      ];
}
