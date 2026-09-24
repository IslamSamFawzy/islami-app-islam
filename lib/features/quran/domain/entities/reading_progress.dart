import 'package:equatable/equatable.dart';

/// How far through a sura the reader got.
class ReadingProgress extends Equatable {
  final int suraId;

  /// Index of the first ayah that was fully on screen, counting from 0.
  final int ayahIndex;

  final DateTime updatedAt;

  const ReadingProgress({
    required this.suraId,
    required this.ayahIndex,
    required this.updatedAt,
  });

  /// The ayah number a reader would recognise (1-based).
  int get ayahNumber => ayahIndex + 1;

  @override
  List<Object?> get props => [suraId, ayahIndex, updatedAt];
}
