part of 'splash_cubit.dart';

enum SplashStatus { initial, navigate }

class SplashState extends Equatable {
  final SplashStatus status;
  final bool onboardingSeen;

  const SplashState({
    this.status = SplashStatus.initial,
    this.onboardingSeen = false,
  });

  @override
  List<Object?> get props => [status, onboardingSeen];
}
