part of 'adhan_settings_cubit.dart';

class AdhanSettingsState extends Equatable {
  final ViewStatus status;
  final AdhanSettings settings;

  /// The user asked for adhans but the device refused the notification
  /// permission, so the master switch shows off and the screen says why.
  final bool permissionDenied;

  /// Whether the device lets the app fire alarms to the minute. When it does
  /// not, the screen offers a way to allow it.
  final bool exactAlarmsAllowed;

  const AdhanSettingsState({
    this.status = ViewStatus.initial,
    required this.settings,
    this.permissionDenied = false,
    this.exactAlarmsAllowed = true,
  });

  AdhanSettingsState copyWith({
    ViewStatus? status,
    AdhanSettings? settings,
    bool? permissionDenied,
    bool? exactAlarmsAllowed,
  }) {
    return AdhanSettingsState(
      status: status ?? this.status,
      settings: settings ?? this.settings,
      permissionDenied: permissionDenied ?? this.permissionDenied,
      exactAlarmsAllowed: exactAlarmsAllowed ?? this.exactAlarmsAllowed,
    );
  }

  @override
  List<Object?> get props => [
    status,
    settings,
    permissionDenied,
    exactAlarmsAllowed,
  ];
}
