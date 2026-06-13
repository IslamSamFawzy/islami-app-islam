import '../../domain/entities/azkar.dart';

class ZikrModel extends Zikr {
  const ZikrModel({
    required super.text,
    required super.count,
    super.note,
  });

  factory ZikrModel.fromJson(Map<String, dynamic> json) {
    return ZikrModel(
      text: json['text'] as String,
      count: (json['count'] as num?)?.toInt() ?? 1,
      note: (json['note'] as String?) ?? '',
    );
  }
}

class AzkarCollectionModel extends AzkarCollection {
  const AzkarCollectionModel({
    required super.title,
    required super.azkar,
  });

  factory AzkarCollectionModel.fromJson(Map<String, dynamic> json) {
    final list = (json['azkar'] as List)
        .map((e) => ZikrModel.fromJson((e as Map).cast<String, dynamic>()))
        .toList();
    return AzkarCollectionModel(
      title: (json['title'] as String?) ?? '',
      azkar: list,
    );
  }
}
