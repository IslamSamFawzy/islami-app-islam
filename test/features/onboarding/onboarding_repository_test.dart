import 'package:flutter_test/flutter_test.dart';
import 'package:islami/features/onboarding/data/repositories/onboarding_repository_impl.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  Future<OnboardingRepositoryImpl> build([
    Map<String, Object> initial = const {},
  ]) async {
    SharedPreferences.setMockInitialValues(initial);
    return OnboardingRepositoryImpl(
      sharedPreferences: await SharedPreferences.getInstance(),
    );
  }

  test('a fresh install has not seen onboarding', () async {
    final repository = await build();

    expect(await repository.hasSeenOnboarding(), isFalse);
  });

  test('marking it sticks', () async {
    final repository = await build();

    await repository.markOnboardingSeen();

    expect(await repository.hasSeenOnboarding(), isTrue);
  });

  test('a flag written by an earlier version still counts', () async {
    // The key is part of the on-disk contract: change it and everyone sees
    // the intro again.
    final repository = await build({'onboarding_seen': true});

    expect(await repository.hasSeenOnboarding(), isTrue);
  });
}
