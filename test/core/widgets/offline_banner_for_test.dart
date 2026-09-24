import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:islami/core/presentation/connectivity_cubit.dart';
import 'package:islami/core/services/connectivity_service.dart';
import 'package:islami/core/theme/theme_manager.dart';
import 'package:islami/core/widgets/offline_banner.dart';

class _FakeConnectivity implements ConnectivityService {
  final controller = StreamController<bool>.broadcast();
  bool connected;

  _FakeConnectivity({this.connected = true});

  @override
  Future<bool> get isConnected async => connected;

  @override
  Stream<bool> get onConnectivityChanged => controller.stream;
}

/// Stands in for a feature bloc: does this screen have data to show?
class _DataCubit extends Cubit<bool> {
  _DataCubit(super.initialState);

  void setHasData(bool value) => emit(value);
}

void main() {
  Future<_FakeConnectivity> pump(
    WidgetTester tester, {
    required bool online,
    required _DataCubit data,
  }) async {
    final service = _FakeConnectivity(connected: online);
    await tester.pumpWidget(
      MaterialApp(
        theme: ThemeManager.darkTheme(),
        home: MultiBlocProvider(
          providers: [
            BlocProvider(
              create: (_) => ConnectivityCubit(connectivityService: service),
            ),
            BlocProvider.value(value: data),
          ],
          child: const Scaffold(
            body: OfflineBannerFor<_DataCubit, bool>(hasData: _identity),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    return service;
  }

  testWidgets('hidden while online, even with data', (tester) async {
    await pump(tester, online: true, data: _DataCubit(true));

    expect(find.byType(OfflineBanner), findsNothing);
  });

  testWidgets('hidden while offline with nothing saved', (tester) async {
    await pump(tester, online: false, data: _DataCubit(false));

    expect(find.byType(OfflineBanner), findsNothing);
  });

  testWidgets('shown offline once there is saved data', (tester) async {
    final data = _DataCubit(false);
    await pump(tester, online: false, data: data);
    expect(find.byType(OfflineBanner), findsNothing);

    data.setHasData(true);
    await tester.pumpAndSettle();

    expect(find.byType(OfflineBanner), findsOneWidget);
  });

  testWidgets('disappears again when the connection returns', (tester) async {
    final service = await pump(tester, online: false, data: _DataCubit(true));
    expect(find.byType(OfflineBanner), findsOneWidget);

    service.controller.add(true);
    await tester.pumpAndSettle();

    expect(find.byType(OfflineBanner), findsNothing);
    await service.controller.close();
  });
}

bool _identity(bool hasData) => hasData;
