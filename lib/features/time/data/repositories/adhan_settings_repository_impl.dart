import 'dart:async';

import 'package:dartz/dartz.dart';

import '../../../../core/cache/json_store.dart';
import '../../../../core/error/failures.dart';
import '../../domain/entities/adhan_settings.dart';
import '../../domain/entities/prayer_name.dart';
import '../../domain/repositories/adhan_settings_repository.dart';

/// Keeps the settings in SharedPreferences, as
/// `{"enabled": true, "prayers": ["Fajr", …]}` — prayers by name rather than
/// by index, so reordering the enum could never silently change what sounds.
class AdhanSettingsRepositoryImpl implements AdhanSettingsRepository {
  final JsonStore jsonStore;

  AdhanSettingsRepositoryImpl({required this.jsonStore});

  static const String _key = 'adhan_settings';
  static const String _enabledField = 'enabled';
  static const String _prayersField = 'prayers';

  final _changes = StreamController<AdhanSettings>.broadcast();

  @override
  Future<Either<Failure, AdhanSettings>> getAdhanSettings() async {
    try {
      final stored = jsonStore.readMap(_key);
      if (stored.isEmpty) return Right(AdhanSettings.defaults);

      final enabled = stored[_enabledField];
      final prayers = stored[_prayersField];
      return Right(
        AdhanSettings(
          enabled: enabled is bool ? enabled : true,
          prayers: prayers is List
              ? prayers
                    .map((name) => PrayerName.of('$name'))
                    .whereType<PrayerName>()
                    .toSet()
              : PrayerName.values.toSet(),
        ),
      );
    } on Exception catch (e) {
      return Left(CacheFailure('Could not read the adhan settings: $e'));
    }
  }

  @override
  Future<Either<Failure, Unit>> saveAdhanSettings(
    AdhanSettings settings,
  ) async {
    try {
      await jsonStore.writeMap(_key, {
        _enabledField: settings.enabled,
        _prayersField: [
          // Written in the enum's order so the stored list reads like the day.
          for (final prayer in PrayerName.values)
            if (settings.prayers.contains(prayer)) prayer.label,
        ],
      });
      if (!_changes.isClosed) _changes.add(settings);
      return const Right(unit);
    } on Exception catch (e) {
      return Left(CacheFailure('Could not save the adhan settings: $e'));
    }
  }

  @override
  Stream<AdhanSettings> watch() => _changes.stream;
}
