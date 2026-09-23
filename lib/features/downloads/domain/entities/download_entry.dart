import 'package:equatable/equatable.dart';

import 'download_key.dart';

/// A record in the downloads index: one sura audio file saved on disk.
class DownloadEntry extends Equatable {
  final String reciterId;
  final String reciterName;
  final String suraId;
  final String path;
  final int bytes;
  final DateTime downloadedAt;

  const DownloadEntry({
    required this.reciterId,
    required this.reciterName,
    required this.suraId,
    required this.path,
    required this.bytes,
    required this.downloadedAt,
  });

  /// Where this entry sits in the index.
  DownloadKey get key => DownloadKey(reciterId: reciterId, suraId: suraId);

  @override
  List<Object?> get props =>
      [reciterId, reciterName, suraId, path, bytes, downloadedAt];
}
