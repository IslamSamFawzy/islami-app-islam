import 'package:dartz/dartz.dart';

import '../../../../core/error/failures.dart';
import '../../../../core/usecase/usecase.dart';
import '../entities/adhan_settings.dart';
import '../repositories/adhan_settings_repository.dart';

/// The adhans the user has asked for.
class GetAdhanSettings implements UseCase<AdhanSettings, NoParams> {
  final AdhanSettingsRepository repository;

  GetAdhanSettings(this.repository);

  @override
  Future<Either<Failure, AdhanSettings>> call(NoParams params) {
    return repository.getAdhanSettings();
  }
}
