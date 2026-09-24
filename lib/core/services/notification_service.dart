import 'package:flutter_local_notifications/flutter_local_notifications.dart';

/// Sets notifications up at startup.
///
/// The adhan itself is scheduled and played natively (see AdhanScheduler and
/// the Kotlin AdhanService), not through this plugin, so nothing is scheduled
/// here. The permission is asked for when the user turns the adhan on, not on
/// launch — see NotificationPermission in the Time feature.
abstract class NotificationService {
  /// Prepares the plugin. Safe to call more than once.
  Future<void> init();
}

/// [NotificationService] implementation backed by flutter_local_notifications.
class LocalNotificationService implements NotificationService {
  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();

  bool _initialized = false;

  @override
  Future<void> init() async {
    if (_initialized) return;

    const androidInit = AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosInit = DarwinInitializationSettings(
      requestAlertPermission: false,
      requestBadgePermission: false,
      requestSoundPermission: false,
    );
    const initSettings = InitializationSettings(
      android: androidInit,
      iOS: iosInit,
    );

    await _plugin.initialize(initSettings);
    _initialized = true;
  }

}
