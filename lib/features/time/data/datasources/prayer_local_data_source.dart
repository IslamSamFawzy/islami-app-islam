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
    return cacheManager.writeList(key, month, (d) => d.toJson());
  }

  @override
  List<PrayerTimesModel>? getCachedMonth(String key) {
    // No TTL: a month's times never change, and the key already carries the
    // month, so a stale entry is simply one for a month that has passed.
    return cacheManager.readList(key, PrayerTimesModel.fromJson);
  }
}
