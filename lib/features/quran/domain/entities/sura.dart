import 'package:equatable/equatable.dart';

/// Domain entity representing a single Quran chapter (Sura).
class Sura extends Equatable {
  /// Sura number, 1..114 — the same number the rest of the app uses to look a
  /// sura up (SuraNames, the reciter lists, the downloads index).
  final int id;

  final String nameEn;
  final String nameAr;
  final int ayaCount;

  const Sura({
    required this.id,
    required this.nameEn,
    required this.nameAr,
    required this.ayaCount,
  });

  /// Whether the basmala is shown above the first ayah. Al-Fatiha (1) is
  /// left out because the basmala is its first ayah, and At-Tawba (9)
  /// because it has none.
  bool get opensWithBasmala => id != 1 && id != 9;

  @override
  List<Object?> get props => [id, nameEn, nameAr, ayaCount];
}
