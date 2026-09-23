import 'package:dartz/dartz.dart';

import '../../../../core/error/failures.dart';
import '../../../../core/usecase/usecase.dart';
import '../entities/download_entry.dart';
import '../repositories/downloads_repository.dart';

/// Records a sura that finished downloading.
class SaveDownload implements UseCase<Unit, DownloadEntry> {
  final DownloadsRepository repository;

  SaveDownload(this.repository);

  @override
  Future<Either<Failure, Unit>> call(DownloadEntry params) {
    return repository.save(params);
  }
}
