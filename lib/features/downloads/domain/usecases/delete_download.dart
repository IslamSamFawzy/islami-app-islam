import 'package:dartz/dartz.dart';

import '../../../../core/error/failures.dart';
import '../../../../core/usecase/usecase.dart';
import '../entities/download_key.dart';
import '../repositories/downloads_repository.dart';

/// Removes one downloaded sura: the file and its index entry.
class DeleteDownload implements UseCase<Unit, DownloadKey> {
  final DownloadsRepository repository;

  DeleteDownload(this.repository);

  @override
  Future<Either<Failure, Unit>> call(DownloadKey params) {
    return repository.delete(params);
  }
}
