import 'package:equatable/equatable.dart';

/// The sajdah an ayah calls for, as Tanzil's metadata classes them.
enum Sajdah { none, recommended, obligatory }

/// Where an ayah sits in the Mushaf.
class Ayah extends Equatable {
  final int sura;
  final int number;

  /// The page it starts on (1-604).
  final int page;

  final int juz;

  /// Hizb 1-60 and quarter 1-240 (rubʿ al-hizb).
  final int hizb;
  final int quarter;

  final Sajdah sajdah;

  const Ayah({
    required this.sura,
    required this.number,
    required this.page,
    required this.juz,
    required this.hizb,
    required this.quarter,
    required this.sajdah,
  });

  @override
  List<Object?> get props => [sura, number, page, juz, hizb, quarter, sajdah];
}
