import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:islami/core/cache/json_store.dart';
import 'package:islami/features/time/data/repositories/adhan_settings_repository_impl.dart';
import 'package:islami/features/time/domain/entities/adhan_settings.dart';
import 'package:islami/features/time/domain/entities/prayer_name.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late SharedPreferences prefs;
  late AdhanSettingsRepositoryImpl repository;

  Future<void> build([Map<String, Object> initial = const {}]) async {
    SharedPreferences.setMockInitialValues(initial);
    prefs = await SharedPreferences.getInstance();
    repository = AdhanSettingsRepositoryImpl(
      jsonStore: JsonStore(sharedPreferences: prefs),
    );
  }

  setUp(() => build());

  test('a fresh install gets every adhan', () async {
    final settings = await repository.getAdhanSettings();

    expect(settings.getOrElse(() => throw 'unreachable'), AdhanSettings.defaults);
  });

  test('round-trips what was saved', () async {
    final saved = AdhanSettings(
      enabled: true,
      prayers: {PrayerName.fajr, PrayerName.maghrib},
    );

    await repository.saveAdhanSettings(saved);

    expect(await repository.getAdhanSettings(), isNot(throwsException));
    expect(
      (await repository.getAdhanSettings()).getOrElse(() => throw 'unreachable'),
      saved,
    );
  });

  test('stores prayers by name, in the order of the day', () async {
    await repository.saveAdhanSettings(
      AdhanSettings(
        enabled: false,
        prayers: {PrayerName.isha, PrayerName.fajr},
      ),
    );

    final stored = json.decode(prefs.getString('adhan_settings')!) as Map;
    expect(stored['enabled'], isFalse);
    expect(stored['prayers'], ['Fajr', 'Isha']);
  });

  test('an unreadable entry falls back rather than losing the day', () async {
    await build({'adhan_settings': 'not json'});
    expect(
      (await repository.getAdhanSettings()).getOrElse(() => throw 'unreachable'),
      AdhanSettings.defaults,
    );

    // A half-written entry keeps whatever it does say.
    await build({
      'adhan_settings': json.encode({'enabled': false}),
    });
    final settings =
        (await repository.getAdhanSettings()).getOrElse(() => throw 'x');
    expect(settings.enabled, isFalse);
    expect(settings.prayers, PrayerName.values.toSet());
  });

  test('a name this version does not know is skipped', () async {
    await build({
      'adhan_settings': json.encode({
        'enabled': true,
        'prayers': ['Fajr', 'Tahajjud'],
      }),
    });

    final settings =
        (await repository.getAdhanSettings()).getOrElse(() => throw 'x');
    expect(settings.prayers, {PrayerName.fajr});
  });

  test('watch reports every save, which is what re-arms the alarms', () async {
    final seen = <AdhanSettings>[];
    repository.watch().listen(seen.add);

    final off = AdhanSettings(enabled: false, prayers: const {});
    await repository.saveAdhanSettings(off);
    await pumpEventQueue();

    expect(seen, [off]);
  });
}
