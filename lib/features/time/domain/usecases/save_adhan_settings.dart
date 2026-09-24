import 'package:dartz/dartz.dart';

import '../../../../core/error/failures.dart';
import '../../../../core/usecase/usecase.dart';
import '../entities/adhan_settings.dart';
import '../repositories/adhan_settings_repository.dart';

/// Records a change to the adhan settings. Everything watching them — the
/// prayer card's volume icon, the alarms — follows from the save.
class SaveAdhanSettings implements UseCase<Unit, AdhanSettings> {
  final AdhanSettingsRepository repository;

  SaveAdhanSettings(this.repository);

  @override
  Future<Either<Failure, Unit>> call(AdhanSettings params) {
    return repository.saveAdhanSettings(params);
  }
}
