import 'dart:async';

import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:islami/core/error/failures.dart';
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

class _FakePermission implements NotificationPermission {
  bool granted = true;

  @override
  Future<bool> isGranted() async => granted;

  @override
  Future<bool> request() async => granted;
}

/// Only the exact-alarm answers matter here; nothing else is called.
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
  late _FakePermission permission;
  late _FakeScheduler scheduler;

  AdhanSettingsCubit build() => AdhanSettingsCubit(
    getAdhanSettings: GetAdhanSettings(repository),
    saveAdhanSettings: SaveAdhanSettings(repository),
    ensureAdhanPermitted: EnsureAdhanPermitted(
      repository: repository,
      notificationPermission: permission,
    ),
    adhanScheduler: scheduler,
  );

  setUp(() {
    permission = _FakePermission();
    scheduler = _FakeScheduler();
    repository = _FakeSettingsRepository(AdhanSettings.defaults);
  });

  tearDown(() => repository.dispose());

  test('loads what was saved', () async {
    repository.settings = AdhanSettings(
      enabled: true,
      prayers: {PrayerName.asr},
    );
    final cubit = build();

    await cubit.load();

    expect(cubit.state.settings.prayers, {PrayerName.asr});
    await cubit.close();
  });

  test('switching one prayer off saves it', () async {
    final cubit = build();
    await cubit.load();

    await cubit.togglePrayer(PrayerName.dhuhr);

    expect(cubit.state.settings.prayers.contains(PrayerName.dhuhr), isFalse);
    expect(repository.settings.prayers.contains(PrayerName.dhuhr), isFalse);
    await cubit.close();
  });

  test('the master switch off is saved and clears any warning', () async {
    final cubit = build();
    await cubit.load();

    await cubit.setEnabled(false);

    expect(repository.settings.enabled, isFalse);
    expect(cubit.state.permissionDenied, isFalse);
    await cubit.close();
  });

  test('a refused permission leaves the switch off, with an explanation',
      () async {
    repository.settings = AdhanSettings(enabled: false, prayers: const {});
    permission.granted = false;
    final cubit = build();
    await cubit.load();

    await cubit.setEnabled(true);

    expect(cubit.state.settings.enabled, isFalse);
    expect(cubit.state.permissionDenied, isTrue);
    expect(repository.settings.enabled, isFalse, reason: 'not persisted as on');
    await cubit.close();
  });

  test('offers the exact-alarm row only when the device withholds it',
      () async {
    final allowed = build();
    await allowed.load();
    expect(allowed.state.exactAlarmsAllowed, isTrue);
    await allowed.close();

    scheduler.exactAllowed = false;
    final restricted = build();
    await restricted.load();
    expect(restricted.state.exactAlarmsAllowed, isFalse);

    await restricted.requestExactAlarms();
    expect(scheduler.exactRequests, 1);

    // Allowed in system settings, then back to the app.
    scheduler.exactAllowed = true;
    await restricted.refreshExactAlarms();
    expect(restricted.state.exactAlarmsAllowed, isTrue);
    await restricted.close();
  });

  test('granting the permission keeps the switch on', () async {
    repository.settings = AdhanSettings(enabled: false, prayers: const {});
    final cubit = build();
    await cubit.load();

    await cubit.setEnabled(true);

    expect(cubit.state.settings.enabled, isTrue);
    expect(cubit.state.permissionDenied, isFalse);
    expect(repository.settings.enabled, isTrue);
    await cubit.close();
  });
}
