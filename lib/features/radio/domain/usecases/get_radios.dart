import 'package:dartz/dartz.dart';

import '../../../../core/error/failures.dart';
import '../../../../core/usecase/usecase.dart';
import '../entities/radio_station.dart';
import '../repositories/radio_repository.dart';

class GetRadios implements UseCase<List<RadioStation>, NoParams> {
  final RadioRepository repository;

  GetRadios(this.repository);

  @override
  Future<Either<Failure, List<RadioStation>>> call(NoParams params) {
    return repository.getRadios();
  }
}
