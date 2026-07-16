import 'dart:async';

import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/cache/cache_manager.dart';
import '../../../../core/error/exceptions.dart';
import '../../../../core/services/compass_service.dart';
import '../../../../core/services/location_service.dart';
import '../../../../core/utils/qibla_calculator.dart';

part 'qibla_state.dart';

/// Drives the Qibla screen: resolves the user's location (once), computes the
/// Qibla bearing/distance, then streams the device heading from the compass.
///
/// No data source, repository or use case — Qibla is a sensor stream plus a
/// pure function, so it follows the plain-cubit precedent (TasbehCubit,
/// SplashCubit) rather than the full clean-architecture stack.
class QiblaCubit extends Cubit<QiblaState> {
  final LocationService locationService;
  final CompassService compassService;
  final CacheManager cacheManager;

  StreamSubscription<CompassReading>? _compassSub;
  Timer? _sensorTimeout;

  QiblaCubit({
    required this.locationService,
    required this.compassService,
    required this.cacheManager,
  }) : super(const QiblaState());

  /// Cache key for the last known coordinates (offline fallback).
  static const String _cacheKey = 'qibla_last_location';

  /// The needle counts as "on the Qibla" within this many degrees.
  static const double alignmentThresholdDeg = 5.0;

  /// Compass accuracy worse than this (degrees of deviation) triggers the
  /// figure-8 calibration hint. Matches flutter_compass's Android scale
  /// (HIGH = 15, MEDIUM = 30, LOW = 45, unreliable = null).
  static const double calibrationThresholdDeg = 20.0;

  // ---------------------------------------------------------------------------
  // Magnetic vs true north
  // ---------------------------------------------------------------------------
  // The Qibla bearing is relative to TRUE north; a phone compass is not.
  //
  //  • iOS   – flutter_compass already returns CoreLocation's `trueHeading`,
  //            so headings arrive in the true-north frame: no correction.
  //  • Android – the plugin returns the MAGNETIC azimuth and exposes no true
  //            value. Converting it needs the local magnetic declination,
  //            which comes from a geomagnetic model (WMM/IGRF).
  //
  // This build applies NO declination offset (see the report): embedding an
  // unverifiable coefficient table would risk pointing confidently in the
  // wrong direction — worse than a small, known error — and pulling in another
  // package was out of scope. On Android the needle can therefore read off by
  // the local declination (a few degrees around Egypt/KSA, 10°+ in some
  // regions). To fix properly, return the modeled declination here, gated to
  // Android only so iOS is not double-corrected.
  double get _magneticDeclination => 0.0;

  /// Resolves location, computes the Qibla, and starts the compass stream.
  Future<void> init() async {
    emit(const QiblaState(status: QiblaStatus.loading));

    double lat;
    double lng;
    var usingCache = false;

    try {
      final position = await locationService.getCurrentPosition();
      lat = position.latitude;
      lng = position.longitude;
      await _cacheLocation(lat, lng);
    } on LocationException catch (e) {
      // Offline / denied / disabled — Qibla needs no network, so fall back to
      // the last known coordinates if we have them.
      final saved = _readCachedLocation();
      if (saved != null) {
        lat = saved.$1;
        lng = saved.$2;
        usingCache = true;
      } else {
        emit(QiblaState(
          status: e.message.toLowerCase().contains('disabled')
              ? QiblaStatus.serviceDisabled
              : QiblaStatus.permissionDenied,
          errorMessage: e.message,
        ));
        return;
      }
    } catch (_) {
      emit(const QiblaState(
        status: QiblaStatus.error,
        errorMessage: 'Could not determine your location.',
      ));
      return;
    }

    emit(QiblaState(
      status: QiblaStatus.ready,
      latitude: lat,
      longitude: lng,
      qiblaBearing:
          QiblaCalculator.qiblaBearing(latitude: lat, longitude: lng),
      distanceKm:
          QiblaCalculator.distanceToKaabaKm(latitude: lat, longitude: lng),
      usingCachedLocation: usingCache,
    ));

    _listenToCompass();
  }

  /// Re-runs [init]; wired to the retry button on the error states.
  Future<void> retry() => init();

  void _listenToCompass() {
    _compassSub?.cancel();
    _compassSub = compassService.readings.listen(_onReading);

    // A device with no magnetometer keeps yielding null headings; if none
    // arrives, surface the "no compass" state instead of a stuck needle.
    _sensorTimeout?.cancel();
    _sensorTimeout = Timer(const Duration(seconds: 4), () {
      if (!isClosed && !state.hasCompass) {
        emit(state.copyWith(sensorTimedOut: true));
      }
    });
  }

  void _onReading(CompassReading reading) {
    if (isClosed || state.status != QiblaStatus.ready) return;

    final raw = reading.heading;
    // Store the heading already in the true-north frame (see declination note).
    final trueHeading =
        raw == null ? null : _normalise360(raw + _magneticDeclination);

    var aligned = state.isAligned;
    var seq = state.alignedSeq;
    if (trueHeading != null) {
      final diff = _normalise180(state.qiblaBearing - trueHeading).abs();
      aligned = diff <= alignmentThresholdDeg;
      // Fire the haptic once, on the frame we cross into alignment.
      if (aligned && !state.isAligned) seq += 1;
    }

    final lowAccuracy = raw == null
        ? state.lowAccuracy
        : reading.accuracy == null ||
            reading.accuracy! > calibrationThresholdDeg;

    emit(state.copyWith(
      // Keep the last good heading on a transient null so the needle is steady.
      heading: trueHeading ?? state.heading,
      hasCompass: state.hasCompass || trueHeading != null,
      lowAccuracy: lowAccuracy,
      isAligned: aligned,
      alignedSeq: seq,
    ));
  }

  Future<void> _cacheLocation(double lat, double lng) async {
    try {
      await cacheManager.write(_cacheKey, {'lat': lat, 'lng': lng});
    } catch (_) {
      // Best-effort — the screen still works this session without the cache.
    }
  }

  (double, double)? _readCachedLocation() {
    final data = cacheManager.read(_cacheKey)?['data'];
    if (data is Map) {
      final lat = data['lat'];
      final lng = data['lng'];
      if (lat is num && lng is num) return (lat.toDouble(), lng.toDouble());
    }
    return null;
  }

  /// Wraps [deg] into `[0, 360)`.
  static double _normalise360(double deg) => ((deg % 360) + 360) % 360;

  /// Wraps [deg] into `(-180, 180]` — the signed offset for alignment.
  static double _normalise180(double deg) {
    final d = _normalise360(deg);
    return d > 180 ? d - 360 : d;
  }

  @override
  Future<void> close() {
    _compassSub?.cancel();
    _sensorTimeout?.cancel();
    return super.close();
  }
}
