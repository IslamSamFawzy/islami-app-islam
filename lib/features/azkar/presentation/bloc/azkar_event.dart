part of 'azkar_bloc.dart';

abstract class AzkarEvent extends Equatable {
  const AzkarEvent();

  @override
  List<Object?> get props => [];
}

class LoadAzkarEvent extends AzkarEvent {
  final AzkarType type;

  const LoadAzkarEvent(this.type);

  @override
  List<Object?> get props => [type];
}
