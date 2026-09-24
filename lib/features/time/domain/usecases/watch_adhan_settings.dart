import '../../../../core/usecase/usecase.dart';
import '../entities/adhan_settings.dart';
import '../repositories/adhan_settings_repository.dart';

/// The adhan settings as they change.
class WatchAdhanSettings implements StreamUseCase<AdhanSettings, NoParams> {
  final AdhanSettingsRepository repository;

  WatchAdhanSettings(this.repository);

  @override
  Stream<AdhanSettings> call(NoParams params) => repository.watch();
}
