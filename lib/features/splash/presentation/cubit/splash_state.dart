part of 'splash_cubit.dart';

enum SplashStatus { initial, navigate }

class SplashState extends Equatable {
  final SplashStatus status;

  const SplashState({this.status = SplashStatus.initial});

  @override
  List<Object?> get props => [status];
}
