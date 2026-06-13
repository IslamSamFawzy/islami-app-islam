import '../../domain/entities/hadith.dart';

class HadithModel extends Hadith {
  const HadithModel({
    required super.title,
    required super.content,
  });

  factory HadithModel.fromJson(Map<String, dynamic> json) {
    return HadithModel(
      title: json['title'] as String,
      content: json['content'] as String,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'title': title,
      'content': content,
    };
  }
}
