import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';

import '../error/failures.dart';

/// Contract every use case implements.
/// [T] is the success value, [Params] the input (use [NoParams] when none).
abstract class UseCase<T, Params> {
  Future<Either<Failure, T>> call(Params params);
}

/// Contract for a use case that yields a stream of values rather than one
/// result — watching settings, say.
abstract class StreamUseCase<T, Params> {
  Stream<T> call(Params params);
}

/// Placeholder for use cases that take no arguments.
class NoParams extends Equatable {
  const NoParams();

  @override
  List<Object?> get props => [];
}
