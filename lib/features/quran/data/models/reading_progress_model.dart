import '../../domain/entities/reading_progress.dart';

/// [ReadingProgress] as it is stored: one entry in a `suraId -> {…}` map, so
/// the sura number is the key and only the rest is in the value.
///
/// Up to 1.0.1 the entry held `ayahIndex`, the 0-based index of the ayah in
/// the old ayah list. Ayah numbers are the same in the Mushaf text, so such an
/// entry reads as ayah `ayahIndex + 1`; the next save writes `ayah`.
class ReadingProgressModel extends ReadingProgress {
  const ReadingProgressModel({
    required super.suraId,
    required super.ayah,
    required super.updatedAt,
  });

  factory ReadingProgressModel.fromEntry(int suraId, Map<String, dynamic> json) {
    return ReadingProgressModel(
      suraId: suraId,
      ayah: switch (json) {
        {'ayah': final num ayah} => ayah.toInt(),
        {'ayahIndex': final num index} => index.toInt() + 1,
        _ => 1,
      },
      updatedAt:
          DateTime.tryParse((json['updatedAt'] as String?) ?? '') ??
          DateTime.fromMillisecondsSinceEpoch(0),
    );
  }

  Map<String, dynamic> toJson() => {
    'ayah': ayah,
    'updatedAt': updatedAt.toIso8601String(),
  };
}
