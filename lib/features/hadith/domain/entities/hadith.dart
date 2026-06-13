import 'package:equatable/equatable.dart';

/// Domain entity representing a single Hadith.
class Hadith extends Equatable {
  final String title;
  final String content;

  const Hadith({
    required this.title,
    required this.content,
  });

  @override
  List<Object?> get props => [title, content];
}
