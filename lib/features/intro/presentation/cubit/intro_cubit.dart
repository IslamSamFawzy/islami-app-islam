import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../onboarding/domain/repositories/onboarding_repository.dart';

part 'intro_state.dart';

class IntroCubit extends Cubit<IntroState> {
  final OnboardingRepository onboardingRepository;

  IntroCubit(this.onboardingRepository) : super(const IntroState());

  /// Kept in sync with the [PageView] so the dots and Back/Finish button react.
  void onPageChanged(int page) => emit(state.copyWith(page: page));

  /// Records that onboarding is done, then signals the view to move on to Home.
  Future<void> finish() async {
    await onboardingRepository.markOnboardingSeen();
    emit(state.copyWith(status: IntroStatus.done));
  }
}
