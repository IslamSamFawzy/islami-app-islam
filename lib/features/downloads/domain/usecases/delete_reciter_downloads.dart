import 'package:dartz/dartz.dart';

import '../../../../core/error/failures.dart';
import '../../../../core/usecase/usecase.dart';
import '../repositories/downloads_repository.dart';

/// Removes every download for one reciter. The parameter is the reciter id.
class DeleteReciterDownloads implements UseCase<Unit, String> {
  final DownloadsRepository repository;

  DeleteReciterDownloads(this.repository);

  @override
  Future<Either<Failure, Unit>> call(String params) {
    return repository.deleteReciter(params);
  }
}
