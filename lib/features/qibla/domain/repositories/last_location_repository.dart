import '../entities/saved_location.dart';

/// Remembers the last place the Qibla was computed from.
abstract class LastLocationRepository {
  /// The saved location, or `null` when there is none (or it cannot be read).
  SavedLocation? read();

  /// Saves [location]. Best-effort: a failure only means the next cold start
  /// without a fix has nothing to fall back on.
  Future<void> save(SavedLocation location);
}
