/// Whether the app may post notifications.
///
/// The adhan plays through a foreground service, which posts one — so without
/// this permission the adhan cannot be delivered.
abstract class NotificationPermission {
  Future<bool> isGranted();

  /// Asks the user, and reports whether it is granted afterwards. Platforms
  /// with no such permission answer true.
  Future<bool> request();
}
