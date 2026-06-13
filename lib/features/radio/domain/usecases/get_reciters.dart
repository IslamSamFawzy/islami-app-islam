import 'package:dartz/dartz.dart';

import '../../../../core/error/failures.dart';
import '../../../../core/usecase/usecase.dart';
import '../entities/reciter.dart';
import '../repositories/radio_repository.dart';

class GetReciters implements UseCase<List<Reciter>, NoParams> {
  final RadioRepository repository;

  GetReciters(this.repository);

  @override
  Future<Either<Failure, List<Reciter>>> call(NoParams params) {
    return repository.getReciters();
  }
}
