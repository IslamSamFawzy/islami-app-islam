import '../../domain/entities/sura.dart';

/// Data-layer representation of [Sura] with (de)serialization helpers.
class SuraModel extends Sura {
  const SuraModel({
    required super.id,
    required super.nameEn,
    required super.nameAr,
    required super.ayaCount,
  });

  factory SuraModel.fromJson(Map<String, dynamic> json) {
    return SuraModel(
      id: json['id'] as String,
      nameEn: json['nameEn'] as String,
      nameAr: json['nameAr'] as String,
      ayaCount: json['ayaCount'] as String,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'nameEn': nameEn,
      'nameAr': nameAr,
      'ayaCount': ayaCount,
    };
  }
}
