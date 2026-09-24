import 'package:shared_preferences/shared_preferences.dart';

import '../../domain/repositories/onboarding_repository.dart';

class OnboardingRepositoryImpl implements OnboardingRepository {
  final SharedPreferences sharedPreferences;

  OnboardingRepositoryImpl({required this.sharedPreferences});

  /// Unchanged since the first release: renaming it would send everyone back
  /// through the intro.
  static const String _key = 'onboarding_seen';

  @override
  Future<bool> hasSeenOnboarding() async =>
      sharedPreferences.getBool(_key) ?? false;

  @override
  Future<void> markOnboardingSeen() => sharedPreferences.setBool(_key, true);
}
