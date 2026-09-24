import 'package:dartz/dartz.dart';

import '../../../../core/error/failures.dart';
import '../../../../core/usecase/usecase.dart';
import '../entities/adhan_settings.dart';
import '../repositories/adhan_settings_repository.dart';
import '../services/notification_permission.dart';

/// Keeps the adhan setting honest about what the device will actually do.
///
/// With the adhan on but notifications refused, nothing would ever be heard,
/// so this asks for the permission and — if the answer is no — turns the adhan
/// off rather than leaving a switch that promises something it cannot deliver.
///
/// Returns the settings as they stand afterwards.
class EnsureAdhanPermitted implements UseCase<AdhanSettings, NoParams> {
  final AdhanSettingsRepository repository;
  final NotificationPermission notificationPermission;

  EnsureAdhanPermitted({
    required this.repository,
    required this.notificationPermission,
  });

  @override
  Future<Either<Failure, AdhanSettings>> call(NoParams params) async {
    final stored = await repository.getAdhanSettings();

    return stored.fold(Left.new, (settings) async {
      if (!settings.enabled) return Right(settings);
      if (await notificationPermission.isGranted()) return Right(settings);
      if (await notificationPermission.request()) return Right(settings);

      final off = settings.copyWith(enabled: false);
      await repository.saveAdhanSettings(off);
      return Right(off);
    });
  }
}
