import 'package:dartz/dartz.dart';

import '../../../../core/error/failures.dart';
import '../../../../core/usecase/usecase.dart';
import '../entities/download_key.dart';
import '../repositories/downloads_repository.dart';

/// The local file to play a sura from, or `null` when there is none — what
/// lets a saved sura play with no connection.
class FindDownloadedFile implements UseCase<String?, DownloadKey> {
  final DownloadsRepository repository;

  FindDownloadedFile(this.repository);

  @override
  Future<Either<Failure, String?>> call(DownloadKey params) {
    return repository.findDownloadedFile(params);
  }
}
