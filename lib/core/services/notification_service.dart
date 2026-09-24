import 'package:flutter_local_notifications/flutter_local_notifications.dart';

/// Sets up notifications and asks for the permission the adhan's foreground
/// notification needs.
///
/// The adhan itself is scheduled and played natively (see AdhanScheduler and
/// the Kotlin AdhanService), not through this plugin, so nothing is scheduled
/// here.
abstract class NotificationService {
  /// Prepares the plugin. Safe to call more than once.
  Future<void> init();

  /// Asks the platform for permission to post notifications.
  Future<void> requestPermissions();
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

  @override
  Future<void> requestPermissions() async {
    await _plugin
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >()
        ?.requestNotificationsPermission();
    await _plugin
        .resolvePlatformSpecificImplementation<
          IOSFlutterLocalNotificationsPlugin
        >()
        ?.requestPermissions(alert: true, badge: true, sound: true);
  }
}
