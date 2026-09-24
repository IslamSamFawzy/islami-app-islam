import 'package:flutter/services.dart';

import '../../domain/entities/adhan_time.dart';
import '../../domain/services/adhan_scheduler.dart';

/// Bridges to the native adhan scheduler (`AdhanScheduler.kt`), which sets
/// exact alarms that play the full adhan through a foreground service even
/// when the app is closed. Fajr uses the Fajr adhan; other prayers use the
/// regular one.
///
/// No-ops on platforms without the channel (e.g. iOS) — the calls are guarded.
class MethodChannelAdhanScheduler implements AdhanScheduler {
  static const MethodChannel _channel = MethodChannel('islami/adhan');

  @override
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

  @override
  Future<void> cancel() async {
    try {
      await _channel.invokeMethod('cancel');
    } catch (_) {}
  }

  @override
  Future<void> stopNow() async {
    try {
      await _channel.invokeMethod('stopNow');
    } catch (_) {}
  }
}
