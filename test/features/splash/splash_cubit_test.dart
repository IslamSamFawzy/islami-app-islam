import 'package:flutter_test/flutter_test.dart';
import 'package:islami/features/onboarding/domain/repositories/onboarding_repository.dart';
import 'package:islami/features/splash/presentation/cubit/splash_cubit.dart';

class _FakeOnboarding implements OnboardingRepository {
  bool seen;

  _FakeOnboarding(this.seen);

  @override
  Future<bool> hasSeenOnboarding() async => seen;

  @override
  Future<void> markOnboardingSeen() async => seen = true;
}

void main() {
  test('reports onboarding as seen so the view routes to Home', () async {
    final cubit = SplashCubit(_FakeOnboarding(true))
      ..startTimer(duration: Duration.zero);

    final state = await cubit.stream.first;

    expect(state.status, SplashStatus.navigate);
    expect(state.onboardingSeen, isTrue);
    await cubit.close();
  });

  test('a first launch routes to the intro instead', () async {
    final cubit = SplashCubit(_FakeOnboarding(false))
      ..startTimer(duration: Duration.zero);

    final state = await cubit.stream.first;

    expect(state.onboardingSeen, isFalse);
    await cubit.close();
  });
}
