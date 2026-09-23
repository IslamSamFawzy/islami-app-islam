import 'package:dartz/dartz.dart';

import '../../../../core/error/failures.dart';
import '../../../../core/usecase/usecase.dart';
import '../entities/download_entry.dart';
import '../repositories/downloads_repository.dart';

/// Reads the index as it stands, without touching the file system.
class GetDownloads implements UseCase<List<DownloadEntry>, NoParams> {
  final DownloadsRepository repository;

  GetDownloads(this.repository);

  @override
  Future<Either<Failure, List<DownloadEntry>>> call(NoParams params) {
    return repository.getDownloads();
  }
}
