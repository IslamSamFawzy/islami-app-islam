import '../../domain/entities/hadith.dart';

/// Data-layer representation of [Hadith]. The hadiths ship as numbered text
/// files, so there is no JSON to (de)serialise.
class HadithModel extends Hadith {
  const HadithModel({
    required super.title,
    required super.content,
  });
}
