import 'dart:async';

import 'package:dartz/dartz.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:islami/core/di/service_locator.dart';
import 'package:islami/core/error/failures.dart';
import 'package:islami/core/theme/theme_manager.dart';
import 'package:islami/features/time/domain/entities/adhan_settings.dart';
import 'package:islami/features/time/domain/entities/prayer_name.dart';
import 'package:islami/features/time/domain/repositories/adhan_settings_repository.dart';
import 'package:islami/features/time/domain/entities/adhan_schedule.dart';
import 'package:islami/features/time/domain/services/adhan_scheduler.dart';
import 'package:islami/features/time/domain/services/notification_permission.dart';
import 'package:islami/features/time/domain/usecases/ensure_adhan_permitted.dart';
import 'package:islami/features/time/domain/usecases/get_adhan_settings.dart';
import 'package:islami/features/time/domain/usecases/save_adhan_settings.dart';
import 'package:islami/features/time/presentation/cubit/adhan_settings_cubit.dart';
import 'package:islami/features/time/presentation/pages/adhan_settings_view.dart';

class _FakeSettingsRepository implements AdhanSettingsRepository {
  AdhanSettings settings;
  final _changes = StreamController<AdhanSettings>.broadcast();

  _FakeSettingsRepository(this.settings);

  @override
  Future<Either<Failure, AdhanSettings>> getAdhanSettings() async =>
      Right(settings);

  @override
  Future<Either<Failure, Unit>> saveAdhanSettings(AdhanSettings s) async {
    settings = s;
    _changes.add(s);
    return const Right(unit);
  }

  @override
  Stream<AdhanSettings> watch() => _changes.stream;

  Future<void> dispose() => _changes.close();
}

class _GrantedPermission implements NotificationPermission {
  @override
  Future<bool> isGranted() async => true;
  @override
  Future<bool> request() async => true;
}

class _FakeScheduler implements AdhanScheduler {
  bool exactAllowed = true;
  int exactRequests = 0;

  @override
  Future<void> schedule(List<AdhanSchedule> adhans) async {}
  @override
  Future<void> cancel() async {}
  @override
  Future<void> stopNow() async {}
  @override
  Future<bool> canScheduleExactAlarms() async => exactAllowed;
  @override
  Future<void> requestExactAlarms() async => exactRequests++;
}

void main() {
  late _FakeSettingsRepository repository;

  late _FakeScheduler scheduler;

  Future<void> pumpScreen(
    WidgetTester tester,
    AdhanSettings settings, {
    bool exactAlarmsAllowed = true,
  }) async {
    // A test may pump the screen twice (before and after a change), so clear
    // the previous registration first.
    if (sl.isRegistered<AdhanSettingsCubit>()) {
      await sl.reset();
      await repository.dispose();
    }
    repository = _FakeSettingsRepository(settings);
    scheduler = _FakeScheduler()..exactAllowed = exactAlarmsAllowed;
    sl.registerFactory(
      () => AdhanSettingsCubit(
        getAdhanSettings: GetAdhanSettings(repository),
        saveAdhanSettings: SaveAdhanSettings(repository),
        ensureAdhanPermitted: EnsureAdhanPermitted(
          repository: repository,
          notificationPermission: _GrantedPermission(),
        ),
        adhanScheduler: scheduler,
      ),
    );
    await tester.pumpWidget(
      MaterialApp(
        // A fresh key, so pumping the screen a second time in one test builds
        // it again rather than reusing the first cubit.
        key: UniqueKey(),
        theme: ThemeManager.darkTheme(),
        home: const AdhanSettingsView(),
      ),
    );
    await tester.pumpAndSettle();
  }

  tearDown(() async {
    await sl.reset();
    await repository.dispose();
  });

  testWidgets('lists the master switch and one per prayer', (tester) async {
    await pumpScreen(tester, AdhanSettings.defaults);

    expect(find.text('Adhan notifications'), findsOneWidget);
    for (final prayer in PrayerName.values) {
      expect(find.text(prayer.label), findsOneWidget);
    }
    expect(find.byType(SwitchListTile), findsNWidgets(6));
  });

  testWidgets('the prayer switches follow the master switch', (tester) async {
    await pumpScreen(tester, AdhanSettings.defaults);

    final prayerSwitches = tester
        .widgetList<SwitchListTile>(find.byType(SwitchListTile))
        .skip(1);
    expect(prayerSwitches.every((s) => s.onChanged != null), isTrue);

    await tester.tap(find.byType(SwitchListTile).first);
    await tester.pumpAndSettle();

    final afterOff = tester
        .widgetList<SwitchListTile>(find.byType(SwitchListTile))
        .skip(1);
    expect(afterOff.every((s) => s.onChanged == null), isTrue);
    expect(repository.settings.enabled, isFalse);
  });

  testWidgets('shows the exact-alarm row only when it is withheld',
      (tester) async {
    const row = 'Allow exact alarms for on-time adhan';

    await pumpScreen(tester, AdhanSettings.defaults);
    expect(find.text(row), findsNothing);

    await pumpScreen(
      tester,
      AdhanSettings.defaults,
      exactAlarmsAllowed: false,
    );
    expect(find.text(row), findsOneWidget);

    await tester.tap(find.text(row));
    await tester.pumpAndSettle();
    expect(scheduler.exactRequests, 1);
  });

  testWidgets('switching one prayer off saves it', (tester) async {
    await pumpScreen(tester, AdhanSettings.defaults);

    await tester.tap(find.text(PrayerName.asr.label));
    await tester.pumpAndSettle();

    expect(repository.settings.prayers.contains(PrayerName.asr), isFalse);
    expect(repository.settings.prayers.contains(PrayerName.fajr), isTrue);
  });
}
