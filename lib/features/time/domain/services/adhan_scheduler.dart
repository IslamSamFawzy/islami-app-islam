import '../entities/adhan_time.dart';

/// Arms the device so the adhan plays at each prayer even when the app is
/// closed. The implementation is a platform detail; this is what the Time
/// feature depends on.
abstract class AdhanScheduler {
  /// Arms an exact daily alarm for each prayer, replacing any previous set.
  Future<void> schedule(List<AdhanTime> adhans);

  /// Cancels every scheduled adhan (used when muted).
  Future<void> cancel();

  /// Stops an adhan that is playing right now (used when muting mid-adhan).
  Future<void> stopNow();
}
