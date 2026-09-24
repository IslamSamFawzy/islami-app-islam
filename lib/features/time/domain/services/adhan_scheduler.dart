import '../entities/adhan_schedule.dart';

/// Arms the device so the adhan sounds at each prayer even when the app is
/// closed. The implementation is a platform detail; this is what the Time
/// feature depends on.
abstract class AdhanScheduler {
  /// Arms each prayer at its next instant, replacing any previous set. The
  /// device keeps the remaining instants and moves along them as they fire, so
  /// the adhan stays accurate for as long as the app is not opened.
  Future<void> schedule(List<AdhanSchedule> adhans);

  /// Cancels every scheduled adhan (used when the adhan is switched off).
  Future<void> cancel();

  /// Stops an adhan that is playing right now.
  Future<void> stopNow();

  /// Whether the device lets the app set alarms that fire to the minute.
  /// Android 12 introduced the permission and Android 14 stopped granting it
  /// to new installs; without it the adhan still plays, just not exactly on
  /// time.
  Future<bool> canScheduleExactAlarms();

  /// Opens the system screen where the user can allow exact alarms.
  Future<void> requestExactAlarms();
}
