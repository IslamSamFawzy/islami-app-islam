import 'dart:async';

import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/error/exceptions.dart';
import '../../../../core/services/compass_service.dart';
import '../../../../core/services/declination_service.dart';
import '../../../../core/services/location_service.dart';
import '../../../../core/utils/qibla_calculator.dart';
import '../../domain/entities/saved_location.dart';
import '../../domain/repositories/last_location_repository.dart';

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
  final DeclinationService declinationService;
  final LastLocationRepository lastLocationRepository;

  StreamSubscription<CompassReading>? _compassSub;
  Timer? _sensorTimeout;

  QiblaCubit({
    required this.locationService,
    required this.compassService,
    required this.declinationService,
    required this.lastLocationRepository,
  }) : super(const QiblaState());

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
  //            so no correction is applied (DeclinationService returns 0 off
  //            Android, which prevents a double correction here).
  //  • Android – the plugin returns the MAGNETIC azimuth; we add the local
  //            magnetic declination from android.hardware.GeomagneticField
  //            (Google's WMM, via DeclinationService) to reach true north.
  //
  // Resolved once from the same coordinates the Qibla uses, cached alongside
  // them (declination changes very slowly), and left at 0 if the lookup fails
  // rather than blocking the compass.
  double _declination = 0;

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
      _declination = await _resolveDeclination(lat, lng, position.altitude);
      await lastLocationRepository.save(
        SavedLocation(
          latitude: lat,
          longitude: lng,
          declination: _declination,
        ),
      );
    } on LocationException catch (e) {
      // Offline / denied / disabled — Qibla needs no network, so fall back to
      // the last known coordinates (and their declination) if we have them.
      final saved = lastLocationRepository.read();
      if (saved != null) {
        lat = saved.latitude;
        lng = saved.longitude;
        _declination = saved.declination;
        usingCache = true;
      } else {
        emit(QiblaState(
          status: e is LocationServiceDisabledException
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
        raw == null ? null : _normalise360(raw + _declination);

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

  /// Never lets a declination lookup throw into [init] — the service already
  /// returns 0 on failure, this is belt-and-braces so the compass never stalls.
  Future<double> _resolveDeclination(
      double lat, double lng, double altitude) async {
    try {
      return await declinationService.getDeclination(
        latitude: lat,
        longitude: lng,
        altitude: altitude,
      );
    } catch (_) {
      return 0;
    }
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
