import 'package:equatable/equatable.dart';

/// How far through a sura the reader got.
class ReadingProgress extends Equatable {
  final int suraId;

  /// The ayah the reader was on, as a reader counts it (from 1).
  final int ayah;

  final DateTime updatedAt;

  const ReadingProgress({
    required this.suraId,
    required this.ayah,
    required this.updatedAt,
  });

  @override
  List<Object?> get props => [suraId, ayah, updatedAt];
}
