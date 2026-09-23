import 'package:connectivity_plus/connectivity_plus.dart';

/// Thin wrapper over connectivity that reduces the platform's list of
/// active transports to a single "is there any connection?" boolean.
abstract class ConnectivityService {
  /// Whether the device currently has any network transport.
  Future<bool> get isConnected;

  /// Emits `true` when a connection becomes available and `false` when it is
  /// lost. Duplicate values are suppressed.
  Stream<bool> get onConnectivityChanged;
}

/// [ConnectivityService] implementation backed by the connectivity_plus plugin.
class ConnectivityPlusService implements ConnectivityService {
  final Connectivity _connectivity;

  ConnectivityPlusService({Connectivity? connectivity})
    : _connectivity = connectivity ?? Connectivity();

  @override
  Future<bool> get isConnected async {
    return _hasConnection(await _connectivity.checkConnectivity());
  }

  @override
  Stream<bool> get onConnectivityChanged =>
      _connectivity.onConnectivityChanged.map(_hasConnection).distinct();

  bool _hasConnection(List<ConnectivityResult> results) =>
      results.any((r) => r != ConnectivityResult.none);
}
