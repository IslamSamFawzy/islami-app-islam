import '../../domain/entities/download_entry.dart';

class DownloadEntryModel extends DownloadEntry {
  const DownloadEntryModel({
    required super.reciterId,
    required super.reciterName,
    required super.suraId,
    required super.path,
    required super.bytes,
    required super.downloadedAt,
  });

  factory DownloadEntryModel.fromEntry(DownloadEntry e) => DownloadEntryModel(
        reciterId: e.reciterId,
        reciterName: e.reciterName,
        suraId: e.suraId,
        path: e.path,
        bytes: e.bytes,
        downloadedAt: e.downloadedAt,
      );

  factory DownloadEntryModel.fromJson(Map<String, dynamic> json) {
    return DownloadEntryModel(
      reciterId: (json['reciterId'] as String?) ?? '',
      reciterName: (json['reciterName'] as String?) ?? '',
      suraId: (json['suraId'] as String?) ?? '',
      path: (json['path'] as String?) ?? '',
      bytes: (json['bytes'] as num?)?.toInt() ?? 0,
      downloadedAt:
          DateTime.tryParse((json['downloadedAt'] as String?) ?? '') ??
              DateTime.fromMillisecondsSinceEpoch(0),
    );
  }

  Map<String, dynamic> toJson() => {
        'reciterId': reciterId,
        'reciterName': reciterName,
        'suraId': suraId,
        'path': path,
        'bytes': bytes,
        'downloadedAt': downloadedAt.toIso8601String(),
      };
}
