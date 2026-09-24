import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/presentation/view_status.dart';
import '../../../../core/usecase/usecase.dart';
import '../../domain/entities/adhan_settings.dart';
import '../../domain/entities/prayer_name.dart';
import '../../domain/usecases/ensure_adhan_permitted.dart';
import '../../domain/usecases/get_adhan_settings.dart';
import '../../domain/usecases/save_adhan_settings.dart';

part 'adhan_settings_state.dart';

/// Drives the settings screen. Saving is all it does to change anything else:
/// TimeBloc watches the same settings and re-arms the alarms itself.
class AdhanSettingsCubit extends Cubit<AdhanSettingsState> {
  final GetAdhanSettings getAdhanSettings;
  final SaveAdhanSettings saveAdhanSettings;
  final EnsureAdhanPermitted ensureAdhanPermitted;

  AdhanSettingsCubit({
    required this.getAdhanSettings,
    required this.saveAdhanSettings,
    required this.ensureAdhanPermitted,
  }) : super(AdhanSettingsState(settings: AdhanSettings.defaults));

  Future<void> load() async {
    emit(state.copyWith(status: ViewStatus.loading));
    final result = await getAdhanSettings(const NoParams());
    emit(
      result.fold(
        (_) => state.copyWith(status: ViewStatus.failure),
        (settings) =>
            state.copyWith(status: ViewStatus.success, settings: settings),
      ),
    );
  }

  /// The master switch. Turning it on asks for the notification permission;
  /// if that is refused the adhan stays off and the screen explains why.
  Future<void> setEnabled(bool enabled) async {
    await _save(state.settings.copyWith(enabled: enabled));
    if (!enabled) {
      emit(state.copyWith(permissionDenied: false));
      return;
    }

    final permitted = await ensureAdhanPermitted(const NoParams());
    permitted.fold((_) {}, (settings) {
      emit(
        state.copyWith(
          settings: settings,
          permissionDenied: !settings.enabled,
        ),
      );
    });
  }

  /// One prayer's switch.
  Future<void> togglePrayer(PrayerName prayer) {
    return _save(state.settings.toggling(prayer));
  }

  Future<void> _save(AdhanSettings settings) async {
    emit(state.copyWith(settings: settings, status: ViewStatus.success));
    await saveAdhanSettings(settings);
  }
}
