import 'package:flutter/services.dart';

/// One prayer whose adhan should fire.
class AdhanTime {
  final String name;
  final DateTime time;
  final bool isFajr;

  const AdhanTime({
    required this.name,
    required this.time,
    required this.isFajr,
  });
}

/// Bridges to the native adhan scheduler (`AdhanScheduler.kt`), which sets exact
/// alarms that play the full adhan through a foreground service even when the
/// app is closed. Fajr uses the Fajr adhan; other prayers use the regular one.
///
/// No-ops on platforms without the channel (e.g. iOS) — the calls are guarded.
class AdhanScheduler {
  static const MethodChannel _channel = MethodChannel('islami/adhan');

  /// Arms an exact daily alarm for each prayer (replaces any previous set).
  Future<void> schedule(List<AdhanTime> adhans) async {
    try {
      await _channel.invokeMethod('schedule', {
        'adhans': [
          for (final a in adhans)
            {
              'name': a.name,
              'hour': a.time.hour,
              'minute': a.time.minute,
              'fajr': a.isFajr,
            },
        ],
      });
    } catch (_) {
      // Channel not available (non-Android) — nothing to schedule.
    }
  }

  /// Cancels every scheduled adhan (used when muted).
  Future<void> cancel() async {
    try {
      await _channel.invokeMethod('cancel');
    } catch (_) {}
  }

  /// Stops an adhan that is currently playing (used when muting mid-adhan).
  Future<void> stopNow() async {
    try {
      await _channel.invokeMethod('stopNow');
    } catch (_) {}
  }
}
