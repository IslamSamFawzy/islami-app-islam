import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shared_preferences/shared_preferences.dart';

part 'intro_state.dart';

/// SharedPreferences key recording that the user finished onboarding.
/// Written here on Finish, read by `SplashCubit` to pick the first screen.
const String onboardingSeenKey = 'onboarding_seen';

class IntroCubit extends Cubit<IntroState> {
  final SharedPreferences _prefs;

  IntroCubit(this._prefs) : super(const IntroState());

  /// Kept in sync with the [PageView] so the dots and Back/Finish button react.
  void onPageChanged(int page) => emit(state.copyWith(page: page));

  /// Persists the onboarding flag, then signals the view to move on to Home.
  Future<void> finish() async {
    await _prefs.setBool(onboardingSeenKey, true);
    emit(state.copyWith(status: IntroStatus.done));
  }
}
