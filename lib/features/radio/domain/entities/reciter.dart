import 'package:equatable/equatable.dart';

/// A Quran reciter. [moshafServer] is the base audio server (normalised to end
/// with a '/'); [surahList] holds the sura numbers this reciter has recorded.
class Reciter extends Equatable {
  final int id;
  final String name;
  final String moshafServer;
  final List<int> surahList;

  const Reciter({
    required this.id,
    required this.name,
    required this.moshafServer,
    required this.surahList,
  });

  /// The audio URL for [sura] — `<server>/<sura number zero-padded to 3>.mp3`,
  /// e.g. `.../002.mp3`.
  String audioUrlFor(int sura) =>
      '$moshafServer${sura.toString().padLeft(3, '0')}.mp3';

  @override
  List<Object?> get props => [id, name, moshafServer, surahList];
}
