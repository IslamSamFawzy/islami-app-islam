import 'dart:async';

import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

part 'splash_state.dart';

class SplashCubit extends Cubit<SplashState> {
  Timer? _timer;

  SplashCubit() : super(const SplashState());

  /// Starts the splash delay, then signals navigation to the home layout.
  void startTimer({Duration duration = const Duration(seconds: 3)}) {
    _timer = Timer(duration, () {
      emit(const SplashState(status: SplashStatus.navigate));
    });
  }

  @override
  Future<void> close() {
    _timer?.cancel();
    return super.close();
  }
}
