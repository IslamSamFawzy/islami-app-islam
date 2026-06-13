import 'package:dartz/dartz.dart';

import '../../../../core/error/failures.dart';
import '../../../../core/usecase/usecase.dart';
import '../entities/sura.dart';
import '../repositories/quran_repository.dart';

class GetAllSuras implements UseCase<List<Sura>, NoParams> {
  final QuranRepository repository;

  GetAllSuras(this.repository);

  @override
  Future<Either<Failure, List<Sura>>> call(NoParams params) {
    return repository.getAllSuras();
  }
}
