import 'dart:async';
import 'dart:io';

import 'package:dio/dio.dart';
import 'package:path_provider/path_provider.dart';

/// Downloads and manages sura audio in an app-private directory
/// (`<app documents>/audio/<reciterId>/<suraId>.mp3`), so no storage
/// permission is needed on Android or iOS.
abstract class DownloadService {
  /// Progress of the in-flight download, from 0.0 to 1.0.
  Stream<double> get progress;

  /// The absolute path a downloaded sura would be stored at.
  Future<String> filePath(String reciterId, String suraId);

  /// Size in bytes of the stored file, or `0` if missing.
  Future<int> fileSize(String reciterId, String suraId);

  /// Whether a file exists at the path this service uses for [reciterId]/[suraId].
  Future<bool> fileExists(String reciterId, String suraId);

  /// Whether a file exists at the given absolute [path].
  Future<bool> pathExists(String path);

  /// Downloads [url] for [reciterId]/[suraId] and returns the final file path.
  /// Throws on cancellation or network error, leaving no partial file behind.
  Future<String> download({
    required String url,
    required String reciterId,
    required String suraId,
  });

  /// Cancels the in-flight download, if any.
  void cancel();

  /// Deletes a single downloaded sura file.
  Future<void> delete(String reciterId, String suraId);

  /// Deletes every downloaded file for a reciter.
  Future<void> deleteReciter(String reciterId);

  /// Closes any open stream controllers.
  Future<void> dispose();
}

/// [DownloadService] implementation backed by [Dio] and path_provider.
///
/// Each download lands in a `.part` file that is renamed to its final name only
/// on success, so an interrupted download never leaves a corrupt playable file.
class DownloadServiceImpl implements DownloadService {
  final Dio _dio;
  final StreamController<double> _progress =
      StreamController<double>.broadcast();
  CancelToken? _cancelToken;

  DownloadServiceImpl({Dio? dio}) : _dio = dio ?? Dio();

  @override
  Stream<double> get progress => _progress.stream;

  Future<String> _audioRoot() async {
    final base = await getApplicationDocumentsDirectory();
    return '${base.path}/audio';
  }

  @override
  Future<String> filePath(String reciterId, String suraId) async {
    return '${await _audioRoot()}/$reciterId/$suraId.mp3';
  }

  @override
  Future<int> fileSize(String reciterId, String suraId) async {
    final file = File(await filePath(reciterId, suraId));
    return await file.exists() ? file.length() : 0;
  }

  @override
  Future<bool> fileExists(String reciterId, String suraId) async {
    final file = File(await filePath(reciterId, suraId));
    return file.exists();
  }

  @override
  Future<bool> pathExists(String path) => File(path).exists();

  @override
  Future<String> download({
    required String url,
    required String reciterId,
    required String suraId,
  }) async {
    final dir = Directory('${await _audioRoot()}/$reciterId');
    if (!await dir.exists()) {
      await dir.create(recursive: true);
    }
    final finalPath = '${dir.path}/$suraId.mp3';
    final partPath = '$finalPath.part';
    _cancelToken = CancelToken();
    try {
      await _dio.download(
        url,
        partPath,
        cancelToken: _cancelToken,
        onReceiveProgress: (received, total) {
          if (total > 0 && !_progress.isClosed) {
            _progress.add(received / total);
          }
        },
      );
      await File(partPath).rename(finalPath);
      if (!_progress.isClosed) _progress.add(1.0);
      return finalPath;
    } catch (_) {
      final part = File(partPath);
      if (await part.exists()) await part.delete();
      rethrow;
    } finally {
      _cancelToken = null;
    }
  }

  @override
  void cancel() => _cancelToken?.cancel('cancelled');

  @override
  Future<void> delete(String reciterId, String suraId) async {
    final file = File(await filePath(reciterId, suraId));
    if (await file.exists()) await file.delete();
  }

  @override
  Future<void> deleteReciter(String reciterId) async {
    final dir = Directory('${await _audioRoot()}/$reciterId');
    if (await dir.exists()) await dir.delete(recursive: true);
  }

  @override
  Future<void> dispose() async => _progress.close();
}
