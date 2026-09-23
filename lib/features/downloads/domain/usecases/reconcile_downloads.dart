import 'package:dartz/dartz.dart';

import '../../../../core/error/failures.dart';
import '../../../../core/usecase/usecase.dart';
import '../entities/download_entry.dart';
import '../repositories/downloads_repository.dart';

/// Checks the index against the file system and returns what is really there.
class ReconcileDownloads implements UseCase<List<DownloadEntry>, NoParams> {
  final DownloadsRepository repository;

  ReconcileDownloads(this.repository);

  @override
  Future<Either<Failure, List<DownloadEntry>>> call(NoParams params) {
    return repository.reconcile();
  }
}
