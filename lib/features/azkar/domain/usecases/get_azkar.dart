import 'package:dartz/dartz.dart';

import '../../../../core/error/failures.dart';
import '../../../../core/usecase/usecase.dart';
import '../entities/azkar.dart';
import '../repositories/azkar_repository.dart';

class GetAzkar implements UseCase<AzkarCollection, AzkarType> {
  final AzkarRepository repository;

  GetAzkar(this.repository);

  @override
  Future<Either<Failure, AzkarCollection>> call(AzkarType params) {
    return repository.getAzkar(params);
  }
}
