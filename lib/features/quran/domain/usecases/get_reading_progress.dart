import 'package:dartz/dartz.dart';

import '../../../../core/error/failures.dart';
import '../../../../core/usecase/usecase.dart';
import '../entities/reading_progress.dart';
import '../repositories/quran_repository.dart';

/// Where the reader left off in a sura. The parameter is the sura number.
class GetReadingProgress implements UseCase<ReadingProgress?, int> {
  final QuranRepository repository;

  GetReadingProgress(this.repository);

  @override
  Future<Either<Failure, ReadingProgress?>> call(int params) {
    return repository.getProgress(params);
  }
}
