import 'package:equatable/equatable.dart';

/// Where a sura was revealed.
enum Revelation { makki, madani }

/// A sura's place in the Mushaf. Its names live on `Sura`.
class SuraInfo extends Equatable {
  final int number;
  final int ayahCount;

  /// The page its first ayah is on. The header can be at the foot of the page
  /// before (Al-Nisa's header ends page 76; 4:1 opens page 77).
  final int firstPage;

  final Revelation revelation;

  const SuraInfo({
    required this.number,
    required this.ayahCount,
    required this.firstPage,
    required this.revelation,
  });

  @override
  List<Object?> get props => [number, ayahCount, firstPage, revelation];
}
