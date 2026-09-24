import 'dart:async';

import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../onboarding/domain/repositories/onboarding_repository.dart';

part 'splash_state.dart';

class SplashCubit extends Cubit<SplashState> {
  final OnboardingRepository onboardingRepository;

  Timer? _timer;

  SplashCubit(this.onboardingRepository) : super(const SplashState());

  /// Waits out the splash delay, then reports whether onboarding was already
  /// seen so the view can route to Intro (first launch) or Home.
  void startTimer({Duration duration = const Duration(seconds: 3)}) {
    _timer = Timer(duration, () async {
      final seen = await onboardingRepository.hasSeenOnboarding();
      if (isClosed) return;
      emit(SplashState(status: SplashStatus.navigate, onboardingSeen: seen));
    });
  }

  @override
  Future<void> close() {
    _timer?.cancel();
    return super.close();
  }
}
