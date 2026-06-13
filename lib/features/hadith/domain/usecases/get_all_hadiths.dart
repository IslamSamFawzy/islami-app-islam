import 'package:dartz/dartz.dart';

import '../../../../core/error/failures.dart';
import '../../../../core/usecase/usecase.dart';
import '../entities/hadith.dart';
import '../repositories/hadith_repository.dart';

class GetAllHadiths implements UseCase<List<Hadith>, NoParams> {
  final HadithRepository repository;

  GetAllHadiths(this.repository);

  @override
  Future<Either<Failure, List<Hadith>>> call(NoParams params) {
    return repository.getAllHadiths();
  }
}
