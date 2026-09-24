import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';

import '../services/connectivity_service.dart';

/// Whether the device is online, app-wide.
///
/// Provided above the MaterialApp, so a screen that only wants to say "this is
/// saved data" does not need its own subscription — which is how Radio and
/// Time each ended up tracking connectivity in their own state.
class ConnectivityCubit extends Cubit<bool> {
  final ConnectivityService connectivityService;

  StreamSubscription<bool>? _sub;

  ConnectivityCubit({required this.connectivityService}) : super(true) {
    _sub = connectivityService.onConnectivityChanged.listen((online) {
      if (!isClosed) emit(online);
    });
    // The stream only fires on changes, so ask once for the current state.
    unawaited(_seed());
  }

  /// True while there is no connection.
  bool get isOffline => !state;

  Future<void> _seed() async {
    final online = await connectivityService.isConnected;
    if (!isClosed) emit(online);
  }

  @override
  Future<void> close() {
    _sub?.cancel();
    return super.close();
  }
}
