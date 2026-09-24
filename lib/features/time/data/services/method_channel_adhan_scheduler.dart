import 'package:flutter/services.dart';

import '../../domain/entities/adhan_schedule.dart';
import '../../domain/services/adhan_scheduler.dart';

/// Bridges to the native adhan scheduler (`AdhanScheduler.kt`), which sets
/// exact alarms that play the full adhan through a foreground service even
/// when the app is closed. Fajr uses the Fajr adhan; other prayers use the
/// regular one.
///
/// Each prayer is sent with every instant the app knows about, as epoch
/// milliseconds, so the device can move along them without the app being
/// opened. No-ops on platforms without the channel (e.g. iOS) — the calls are
/// guarded.
class MethodChannelAdhanScheduler implements AdhanScheduler {
  static const MethodChannel _channel = MethodChannel('islami/adhan');

  @override
  Future<void> schedule(List<AdhanSchedule> adhans) async {
    try {
      await _channel.invokeMethod('schedule', {
        'adhans': [
          for (final adhan in adhans)
            {
              'name': adhan.name,
              'fajr': adhan.isFajr,
              'times': [
                for (final time in adhan.times) time.millisecondsSinceEpoch,
              ],
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

  @override
  Future<bool> canScheduleExactAlarms() async {
    try {
      return await _channel.invokeMethod<bool>('canScheduleExact') ?? true;
    } catch (_) {
      // No channel (non-Android): nothing restricts alarms there.
      return true;
    }
  }

  @override
  Future<void> requestExactAlarms() async {
    try {
      await _channel.invokeMethod('requestExactAlarms');
    } catch (_) {}
  }
}
