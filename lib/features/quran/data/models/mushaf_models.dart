import '../../domain/entities/ayah.dart';
import '../../domain/entities/mushaf_page.dart';
import '../../domain/entities/sura_info.dart';

/// `assets/quran/meta.json`, built by tool/build_mushaf_assets.py.
class MushafMetaModel {
  final List<String> basmala;
  final List<SuraInfo> suras;

  /// `ayahs[sura - 1][ayah - 1]`.
  final List<List<Ayah>> ayahs;

  /// First ayah of each juz, `[sura, ayah]`.
  final List<List<int>> juzStarts;

  const MushafMetaModel({
    required this.basmala,
    required this.suras,
    required this.ayahs,
    required this.juzStarts,
  });

  factory MushafMetaModel.fromJson(Map<String, dynamic> json) {
    final basmala = (json['basmala'] as List).cast<String>();
    final suras = [
      for (final s in json['suras'] as List)
        SuraInfo(
          number: s['n'] as int,
          ayahCount: s['ayahs'] as int,
          firstPage: s['page'] as int,
          revelation: s['type'] == 'makki'
              ? Revelation.makki
              : Revelation.madani,
        ),
    ];
    final rows = json['ayahs'] as List;
    final ayahs = [
      for (var s = 0; s < rows.length; s++)
        [
          for (var a = 0; a < (rows[s] as List).length; a++)
            _ayah(s + 1, a + 1, (rows[s] as List)[a] as List),
        ],
    ];
    return MushafMetaModel(
      basmala: basmala,
      suras: suras,
      ayahs: ayahs,
      juzStarts: [for (final j in json['juz'] as List) (j as List).cast<int>()],
    );
  }

  /// A row is `[page, juz, quarter, sajdah]`; sajdah is 0 none, 1
  /// recommended, 2 obligatory.
  static Ayah _ayah(int sura, int number, List row) {
    final quarter = row[2] as int;
    return Ayah(
      sura: sura,
      number: number,
      page: row[0] as int,
      juz: row[1] as int,
      hizb: (quarter - 1) ~/ 4 + 1,
      quarter: quarter,
      sajdah: Sajdah.values[row[3] as int],
    );
  }
}

/// The lines of `assets/quran/pages/NNN.json`.
///
/// An ayah line holds segments `[sura, ayah, firstIndex, [tokens], seps]`:
/// token `i` is followed by `seps[i]`, and the ayah's last token (its marker)
/// by nothing.
List<MushafLine> parsePageLines(
  Map<String, dynamic> json,
  List<String> basmala,
) {
  return [
    for (final line in json['lines'] as List)
      switch (line['t']) {
        's' => SuraHeaderLine(line['sura'] as int),
        'b' => BasmalaLine(basmala),
        _ => AyahLine([
          for (final seg in line['segs'] as List) ..._segment(seg as List),
        ], centered: line['c'] == 1),
      },
  ];
}

Iterable<MushafWord> _segment(List seg) sync* {
  final sura = seg[0] as int;
  final ayah = seg[1] as int;
  final start = seg[2] as int;
  final tokens = (seg[3] as List).cast<String>();
  final seps = seg[4] as String;
  for (var i = 0; i < tokens.length; i++) {
    yield MushafWord(
      sura: sura,
      ayah: ayah,
      index: start + i,
      text: tokens[i],
      separator: i < seps.length ? seps[i] : '',
      kind: _kind(tokens[i]),
    );
  }
}

MushafWordKind _kind(String token) {
  if (token.isEmpty) return MushafWordKind.empty;
  if (token == '\u06DE') return MushafWordKind.rub;
  final code = token.codeUnitAt(0);
  // The text writes each ayah's number as one codepoint, U+FC00 + (n - 1).
  if (token.length == 1 && code >= 0xFC00 && code <= 0xFD1D) {
    return MushafWordKind.ayahEnd;
  }
  return MushafWordKind.word;
}
