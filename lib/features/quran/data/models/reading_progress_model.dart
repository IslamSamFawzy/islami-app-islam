import '../../domain/entities/reading_progress.dart';

/// [ReadingProgress] as it is stored: one entry in a `suraId -> {…}` map, so
/// the sura number is the key and only the rest is in the value.
class ReadingProgressModel extends ReadingProgress {
  const ReadingProgressModel({
    required super.suraId,
    required super.ayahIndex,
    required super.updatedAt,
  });

  factory ReadingProgressModel.fromEntry(int suraId, Map<String, dynamic> json) {
    return ReadingProgressModel(
      suraId: suraId,
      ayahIndex: (json['ayahIndex'] as num?)?.toInt() ?? 0,
      updatedAt:
          DateTime.tryParse((json['updatedAt'] as String?) ?? '') ??
          DateTime.fromMillisecondsSinceEpoch(0),
    );
  }

  Map<String, dynamic> toJson() => {
    'ayahIndex': ayahIndex,
    'updatedAt': updatedAt.toIso8601String(),
  };
}
