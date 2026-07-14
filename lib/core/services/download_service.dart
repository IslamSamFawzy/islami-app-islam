import 'dart:async';
import 'dart:io';

import 'package:dio/dio.dart';
import 'package:path_provider/path_provider.dart';

/// Downloads sura audio into an app-private directory
/// (`<app documents>/audio/<reciterId>/<suraId>.mp3`), so no storage
/// permission is needed on Android or iOS.
///
/// Each download lands in a `.part` file that is renamed to its final name only
/// on success, so an interrupted download never leaves a corrupt playable file.
class DownloadService {
  final Dio _dio;
  final StreamController<double> _progress =
      StreamController<double>.broadcast();
  CancelToken? _cancelToken;

  DownloadService({Dio? dio}) : _dio = dio ?? Dio();

  /// Progress of the in-flight download, from 0.0 to 1.0.
  Stream<double> get progress => _progress.stream;

  Future<String> _audioRoot() async {
    final base = await getApplicationDocumentsDirectory();
    return '${base.path}/audio';
  }

  Future<String> filePath(String reciterId, String suraId) async {
    return '${await _audioRoot()}/$reciterId/$suraId.mp3';
  }

  Future<int> fileSize(String reciterId, String suraId) async {
    final file = File(await filePath(reciterId, suraId));
    return await file.exists() ? file.length() : 0;
  }

  /// Downloads [url] for [reciterId]/[suraId] and returns the final file path.
  /// Throws on cancellation or network error, leaving no partial file behind.
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

  /// Cancels the in-flight download, if any.
  void cancel() => _cancelToken?.cancel('cancelled');

  /// Deletes a single downloaded sura file.
  Future<void> delete(String reciterId, String suraId) async {
    final file = File(await filePath(reciterId, suraId));
    if (await file.exists()) await file.delete();
  }

  /// Deletes every downloaded file for a reciter.
  Future<void> deleteReciter(String reciterId) async {
    final dir = Directory('${await _audioRoot()}/$reciterId');
    if (await dir.exists()) await dir.delete(recursive: true);
  }

  Future<void> dispose() async => _progress.close();
}
