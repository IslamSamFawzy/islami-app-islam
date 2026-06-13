import 'package:equatable/equatable.dart';

/// Base type returned on the left side of [Either] across the domain layer.
abstract class Failure extends Equatable {
  final String message;

  const Failure(this.message);

  @override
  List<Object?> get props => [message];
}

class ServerFailure extends Failure {
  const ServerFailure(super.message);
}

class CacheFailure extends Failure {
  const CacheFailure(super.message);
}

class LocalDataFailure extends Failure {
  const LocalDataFailure(super.message);
}
