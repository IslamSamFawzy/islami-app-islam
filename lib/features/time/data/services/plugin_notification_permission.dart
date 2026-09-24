import 'package:flutter_local_notifications/flutter_local_notifications.dart';

import '../../domain/services/notification_permission.dart';

/// [NotificationPermission] backed by flutter_local_notifications.
///
/// The plugin object is a singleton, so this shares the one the app
/// initialises at startup.
class PluginNotificationPermission implements NotificationPermission {
  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();

  @override
  Future<bool> isGranted() async {
    final android = _plugin
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >();
    if (android != null) return await android.areNotificationsEnabled() ?? false;
    // Nothing to ask on this platform (or no way to ask without prompting).
    return true;
  }

  @override
  Future<bool> request() async {
    final android = _plugin
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >();
    if (android != null) {
      return await android.requestNotificationsPermission() ?? false;
    }

    final ios = _plugin
        .resolvePlatformSpecificImplementation<
          IOSFlutterLocalNotificationsPlugin
        >();
    if (ios != null) {
      return await ios.requestPermissions(
            alert: true,
            badge: true,
            sound: true,
          ) ??
          false;
    }
    return true;
  }
}
