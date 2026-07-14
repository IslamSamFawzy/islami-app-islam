import 'package:equatable/equatable.dart';

/// A record in the downloads index: one sura audio file saved on disk.
class DownloadEntry extends Equatable {
  final String reciterId;
  final String suraId;
  final String path;
  final int bytes;
  final DateTime downloadedAt;

  const DownloadEntry({
    required this.reciterId,
    required this.suraId,
    required this.path,
    required this.bytes,
    required this.downloadedAt,
  });

  /// Composite index key, `<reciterId>/<suraId>`.
  String get key => '$reciterId/$suraId';

  @override
  List<Object?> get props => [reciterId, suraId, path, bytes, downloadedAt];
}
