import 'dart:async';

import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../intro/presentation/cubit/intro_cubit.dart' show onboardingSeenKey;

part 'splash_state.dart';

class SplashCubit extends Cubit<SplashState> {
  final SharedPreferences _prefs;
  Timer? _timer;

  SplashCubit(this._prefs) : super(const SplashState());

  /// Waits out the splash delay, then reports whether onboarding was already
  /// seen so the view can route to Intro (first launch) or Home.
  void startTimer({Duration duration = const Duration(seconds: 3)}) {
    _timer = Timer(duration, () {
      final seen = _prefs.getBool(onboardingSeenKey) ?? false;
      emit(SplashState(status: SplashStatus.navigate, onboardingSeen: seen));
    });
  }

  @override
  Future<void> close() {
    _timer?.cancel();
    return super.close();
  }
}
