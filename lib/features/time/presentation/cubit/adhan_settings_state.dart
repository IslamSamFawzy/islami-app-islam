part of 'adhan_settings_cubit.dart';

class AdhanSettingsState extends Equatable {
  final ViewStatus status;
  final AdhanSettings settings;

  /// The user asked for adhans but the device refused the notification
  /// permission, so the master switch shows off and the screen says why.
  final bool permissionDenied;

  const AdhanSettingsState({
    this.status = ViewStatus.initial,
    required this.settings,
    this.permissionDenied = false,
  });

  AdhanSettingsState copyWith({
    ViewStatus? status,
    AdhanSettings? settings,
    bool? permissionDenied,
  }) {
    return AdhanSettingsState(
      status: status ?? this.status,
      settings: settings ?? this.settings,
      permissionDenied: permissionDenied ?? this.permissionDenied,
    );
  }

  @override
  List<Object?> get props => [status, settings, permissionDenied];
}
