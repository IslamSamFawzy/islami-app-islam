import 'package:dartz/dartz.dart';

import '../../../../core/error/failures.dart';
import '../entities/download_entry.dart';
import '../entities/download_key.dart';

/// The saved-suras library: the index of what has been downloaded, and the
/// files behind it.
abstract class DownloadsRepository {
  /// Every entry in the index, as stored.
  Future<Either<Failure, List<DownloadEntry>>> getDownloads();

  /// Drops entries whose file is no longer on disk (deleted by the OS or by
  /// the user) and returns the ones that survived.
  Future<Either<Failure, List<DownloadEntry>>> reconcile();

  /// Records a finished download.
  Future<Either<Failure, Unit>> save(DownloadEntry entry);

  /// Deletes one sura: its file and its index entry.
  Future<Either<Failure, Unit>> delete(DownloadKey key);

  /// Deletes every file and index entry belonging to [reciterId].
  Future<Either<Failure, Unit>> deleteReciter(String reciterId);

  /// The path to play [key] from, or `null` when it was never downloaded or
  /// the file has since gone.
  Future<Either<Failure, String?>> findDownloadedFile(DownloadKey key);
}
