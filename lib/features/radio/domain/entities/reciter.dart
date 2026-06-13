import 'package:equatable/equatable.dart';

/// A Quran reciter. [playUrl] points at a sample recitation (Al-Fatiha)
/// built from the reciter's first moshaf server.
class Reciter extends Equatable {
  final int id;
  final String name;
  final String playUrl;

  const Reciter({
    required this.id,
    required this.name,
    required this.playUrl,
  });

  @override
  List<Object?> get props => [id, name, playUrl];
}
