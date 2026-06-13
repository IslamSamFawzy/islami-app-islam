import 'package:equatable/equatable.dart';

/// Domain entity representing a single Quran chapter (Sura).
class Sura extends Equatable {
  final String id;
  final String nameEn;
  final String nameAr;
  final String ayaCount;

  const Sura({
    required this.id,
    required this.nameEn,
    required this.nameAr,
    required this.ayaCount,
  });

  @override
  List<Object?> get props => [id, nameEn, nameAr, ayaCount];
}
