import '../../domain/entities/sura.dart';

/// Data-layer representation of [Sura]. The list is built from the bundled
/// SuraNames constants, so there is no JSON to (de)serialise.
class SuraModel extends Sura {
  const SuraModel({
    required super.id,
    required super.nameEn,
    required super.nameAr,
    required super.ayaCount,
  });
}
