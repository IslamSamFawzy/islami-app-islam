import 'package:dartz/dartz.dart';

import '../../../../core/error/failures.dart';
import '../entities/adhan_settings.dart';

/// Stores which adhans the user wants, and reports changes to them.
abstract class AdhanSettingsRepository {
  /// The saved settings, or the defaults when nothing has been saved.
  Future<Either<Failure, AdhanSettings>> getAdhanSettings();

  Future<Either<Failure, Unit>> saveAdhanSettings(AdhanSettings settings);

  /// Emits the settings each time they are saved, so the prayer card and the
  /// alarms follow a change made on the settings screen straight away.
  Stream<AdhanSettings> watch();
}
