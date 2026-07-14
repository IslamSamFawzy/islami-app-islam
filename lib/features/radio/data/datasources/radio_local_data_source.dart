import '../../../../core/cache/cache_manager.dart';
import '../models/radio_station_model.dart';
import '../models/reciter_model.dart';

/// Caches the radio/reciter lists so the Radio tab works offline.
abstract class RadioLocalDataSource {
  Future<void> cacheRadios(List<RadioStationModel> radios);

  /// Cached radios, or `null` if absent, corrupt, or older than the TTL.
  List<RadioStationModel>? getCachedRadios();

  Future<void> cacheReciters(List<ReciterModel> reciters);

  /// Cached reciters, or `null` if absent, corrupt, or older than the TTL.
  List<ReciterModel>? getCachedReciters();
}

class RadioLocalDataSourceImpl implements RadioLocalDataSource {
  final CacheManager cacheManager;

  RadioLocalDataSourceImpl({required this.cacheManager});

  static const String _radiosKey = 'radio_stations';
  static const String _recitersKey = 'radio_reciters';
  static const Duration _ttl = Duration(days: 7);

  @override
  Future<void> cacheRadios(List<RadioStationModel> radios) {
    return cacheManager.write(
      _radiosKey,
      radios.map((r) => r.toJson()).toList(),
    );
  }

  @override
  List<RadioStationModel>? getCachedRadios() {
    return _readList(_radiosKey, RadioStationModel.fromJson);
  }

  @override
  Future<void> cacheReciters(List<ReciterModel> reciters) {
    return cacheManager.write(
      _recitersKey,
      reciters.map((r) => r.toJson()).toList(),
    );
  }

  @override
  List<ReciterModel>? getCachedReciters() {
    return _readList(_recitersKey, ReciterModel.fromJson);
  }

  /// Reads a cached list under [key], returning `null` if the entry is missing,
  /// stale (older than [_ttl]), or cannot be parsed.
  List<T>? _readList<T>(
    String key,
    T Function(Map<String, dynamic>) fromJson,
  ) {
    if (cacheManager.isStale(key, _ttl)) return null;
    final data = cacheManager.read(key)?['data'];
    if (data is! List) return null;
    try {
      return data
          .map((e) => fromJson((e as Map).cast<String, dynamic>()))
          .toList();
    } catch (_) {
      // A corrupt entry is treated as a cache miss rather than crashing.
      return null;
    }
  }
}
