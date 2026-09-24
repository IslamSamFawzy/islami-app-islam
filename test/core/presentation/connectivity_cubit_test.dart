import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:islami/core/presentation/connectivity_cubit.dart';
import 'package:islami/core/services/connectivity_service.dart';

class _FakeConnectivity implements ConnectivityService {
  final controller = StreamController<bool>.broadcast();
  bool connected;

  _FakeConnectivity({this.connected = true});

  @override
  Future<bool> get isConnected async => connected;

  @override
  Stream<bool> get onConnectivityChanged => controller.stream;
}

void main() {
  test('seeds from the current connection, which the stream never reports',
      () async {
    final cubit = ConnectivityCubit(
      connectivityService: _FakeConnectivity(connected: false),
    );

    await expectLater(cubit.stream, emits(false));
    expect(cubit.isOffline, isTrue);

    await cubit.close();
  });

  test('follows the connection as it changes', () async {
    final service = _FakeConnectivity();
    final cubit = ConnectivityCubit(connectivityService: service);
    await pumpEventQueue();

    service.controller.add(false);
    await expectLater(cubit.stream, emits(false));

    service.controller.add(true);
    await expectLater(cubit.stream, emits(true));
    expect(cubit.isOffline, isFalse);

    await cubit.close();
    await service.controller.close();
  });
}
