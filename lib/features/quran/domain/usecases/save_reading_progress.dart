import 'package:dartz/dartz.dart';

import '../../../../core/error/failures.dart';
import '../../../../core/usecase/usecase.dart';
import '../entities/reading_progress.dart';
import '../repositories/quran_repository.dart';

/// Remembers where the reader is, so the sura opens there next time.
class SaveReadingProgress implements UseCase<Unit, ReadingProgress> {
  final QuranRepository repository;

  SaveReadingProgress(this.repository);

  @override
  Future<Either<Failure, Unit>> call(ReadingProgress params) {
    return repository.saveProgress(params);
  }
}
