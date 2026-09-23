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
    return cacheManager.writeList(_radiosKey, radios, (r) => r.toJson());
  }

  @override
  List<RadioStationModel>? getCachedRadios() {
    return cacheManager.readList(
      _radiosKey,
      RadioStationModel.fromJson,
      ttl: _ttl,
    );
  }

  @override
  Future<void> cacheReciters(List<ReciterModel> reciters) {
    return cacheManager.writeList(_recitersKey, reciters, (r) => r.toJson());
  }

  @override
  List<ReciterModel>? getCachedReciters() {
    return cacheManager.readList(
      _recitersKey,
      ReciterModel.fromJson,
      ttl: _ttl,
    );
  }
}
