import '../../../../core/cache/cache_manager.dart';
import '../models/prayer_times_model.dart';

/// Caches a whole month of prayer times so today's schedule is a pure lookup
/// with zero network calls for the rest of the month.
abstract class PrayerLocalDataSource {
  Future<void> cacheMonth(String key, List<PrayerTimesModel> month);

  /// The cached month for [key], or `null` if absent or corrupt.
  List<PrayerTimesModel>? getCachedMonth(String key);
}

class PrayerLocalDataSourceImpl implements PrayerLocalDataSource {
  final CacheManager cacheManager;

  PrayerLocalDataSourceImpl({required this.cacheManager});

  @override
  Future<void> cacheMonth(String key, List<PrayerTimesModel> month) {
    return cacheManager.write(key, month.map((d) => d.toJson()).toList());
  }

  @override
  List<PrayerTimesModel>? getCachedMonth(String key) {
    final data = cacheManager.read(key)?['data'];
    if (data is! List) return null;
    try {
      return data
          .map((e) =>
              PrayerTimesModel.fromJson((e as Map).cast<String, dynamic>()))
          .toList();
    } catch (_) {
      // A corrupt entry is treated as a cache miss rather than crashing.
      return null;
    }
  }
}
