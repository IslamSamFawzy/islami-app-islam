import '../../../../core/cache/cache_manager.dart';
import '../../domain/entities/saved_location.dart';
import '../../domain/repositories/last_location_repository.dart';

/// Stores the last location in the app cache.
class LastLocationRepositoryImpl implements LastLocationRepository {
  final CacheManager cacheManager;

  LastLocationRepositoryImpl({required this.cacheManager});

  /// Unchanged since the first release, so an existing cache still reads.
  static const String _key = 'qibla_last_location';

  @override
  SavedLocation? read() {
    final data = cacheManager.read(_key)?['data'];
    if (data is! Map) return null;

    final latitude = data['lat'];
    final longitude = data['lng'];
    if (latitude is! num || longitude is! num) return null;

    final declination = data['declination'];
    return SavedLocation(
      latitude: latitude.toDouble(),
      longitude: longitude.toDouble(),
      declination: declination is num ? declination.toDouble() : 0,
    );
  }

  @override
  Future<void> save(SavedLocation location) async {
    try {
      await cacheManager.write(_key, {
        'lat': location.latitude,
        'lng': location.longitude,
        'declination': location.declination,
      });
    } catch (_) {
      // The screen still works this session without the cache.
    }
  }
}
