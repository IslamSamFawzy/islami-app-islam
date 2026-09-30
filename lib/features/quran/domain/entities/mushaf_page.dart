import 'package:equatable/equatable.dart';

/// What a [MushafWord] is on the page.
enum MushafWordKind {
  /// A word of the ayah (it may carry a pause or sajdah sign).
  word,

  /// The ayah-end marker; the Hafs font draws it with the ayah's number.
  ayahEnd,

  /// The rubʿ al-hizb sign ۞ that opens a quarter.
  rub,

  /// Nothing to draw: the text has a separator where there is no word (2:6
  /// opens with a space). It is kept so the ayah text stays exact.
  empty,
}

/// One piece of the Mushaf text, exactly as the source has it.
class MushafWord extends Equatable {
  final int sura;
  final int ayah;

  /// Position within the ayah's text, counting from 0.
  final int index;

  final String text;

  /// What follows [text] in the ayah: a space, a no-break space, or nothing
  /// after the ayah's last piece. [text] + [separator] over an ayah's words
  /// gives back its text exactly.
  final String separator;

  final MushafWordKind kind;

  const MushafWord({
    required this.sura,
    required this.ayah,
    required this.index,
    required this.text,
    required this.separator,
    required this.kind,
  });

  @override
  List<Object?> get props => [sura, ayah, index, text, separator, kind];
}

/// One of the 15 lines of a page.
sealed class MushafLine extends Equatable {
  const MushafLine();
}

/// The framed name of the sura that begins here.
class SuraHeaderLine extends MushafLine {
  final int sura;

  const SuraHeaderLine(this.sura);

  @override
  List<Object?> get props => [sura];
}

/// The basmala above the first ayah of every sura but Al-Fatiha and At-Tawba.
class BasmalaLine extends MushafLine {
  /// The basmala as the text of 1:1 has it, without its ayah marker.
  final List<String> words;

  const BasmalaLine(this.words);

  @override
  List<Object?> get props => [words];
}

/// A line of ayah text, justified to the full width unless [centered].
class AyahLine extends MushafLine {
  final List<MushafWord> words;

  /// Short lines the Mushaf centres instead of justifying (pages 1-2, and the
  /// last line of a few suras).
  final bool centered;

  const AyahLine(this.words, {this.centered = false});

  @override
  List<Object?> get props => [words, centered];
}

/// One of the 604 pages.
class MushafPage extends Equatable {
  final int number;
  final List<MushafLine> lines;

  /// Juz, hizb (1-60) and quarter (1-240) of the page's first ayah, for the
  /// margin.
  final int juz;
  final int hizb;
  final int quarter;

  const MushafPage({
    required this.number,
    required this.lines,
    required this.juz,
    required this.hizb,
    required this.quarter,
  });

  /// Every word on the page, in reading order.
  Iterable<MushafWord> get words =>
      lines.whereType<AyahLine>().expand((line) => line.words);

  @override
  List<Object?> get props => [number, lines, juz, hizb, quarter];
}
