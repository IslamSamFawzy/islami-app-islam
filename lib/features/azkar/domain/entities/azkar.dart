import 'package:equatable/equatable.dart';

/// Which azkar set to show.
enum AzkarType { morning, evening }

/// A single remembrance with its recommended repetition count.
class Zikr extends Equatable {
  final String text;
  final int count;
  final String note;

  const Zikr({
    required this.text,
    required this.count,
    this.note = '',
  });

  @override
  List<Object?> get props => [text, count, note];
}

/// A titled collection of azkar (morning or evening).
class AzkarCollection extends Equatable {
  final String title;
  final List<Zikr> azkar;

  const AzkarCollection({required this.title, required this.azkar});

  @override
  List<Object?> get props => [title, azkar];
}
