/// Diacritic/hamza-insensitive search helpers, shared by the Radio and reciter
/// search fields. Pure Dart — no Flutter imports — so it is easy to unit test
/// (this normalisation is the part most likely to be quietly wrong).
///
/// Every Arabic codepoint below is written as a \u escape (not a literal glyph)
/// so the source stays ASCII and free of bidirectional-text surprises.
abstract class ArabicSearch {
  // Combining marks + tatweel only. The listed ranges skip the letter block
  // (U+0621-U+064A) and the Arabic-Indic digits (U+0660+), so only marks are
  // removed (e.g. a shadda), never letters or numbers.
  //   U+0610-U+061A signs · U+0640 tatweel · U+064B-U+065F tashkeel
  //   · U+0670 superscript alef · U+06D6-U+06ED Quranic annotation marks
  static final RegExp _diacritics = RegExp(
    '[ؐ-ؚـً-ٰٟۖ-ۭ]',
  );

  static const String _alef = 'ا'; // ARABIC LETTER ALEF
  static const String _lam = 'ل'; // ARABIC LETTER LAM

  /// Folds an Arabic (or Latin) string to a comparable form: lower-cased,
  /// tashkeel/tatweel stripped, alef variants (U+0623/0625/0622/0671) -> alef,
  /// the hamza dropped wherever it is written (the letter U+0621, or the marks
  /// U+0654/U+0655 stripped above) and its seats folded (U+0624 -> waw,
  /// U+0626 -> yeh), teh marbuta (U+0629) -> heh, alef maksura (U+0649) ->
  /// yeh, and a leading definite article "al-" (alef+lam) removed. Latin text
  /// is only lower-cased.
  ///
  /// The hamza has to go entirely: the KFGQPC Mushaf text and Tanzil's write
  /// some hamzas differently (2:72 has the letter in one and the combining
  /// mark in the other), and a search must not care which it was given.
  static String normalize(String input) {
    // A no-break space (the Mushaf text has one before each ayah number and
    // after each rub sign) is a space like any other.
    var s = input.replaceAll('\u00A0', ' ').toLowerCase().trim();
    s = s.replaceAll(_diacritics, '');
    s = s
        .replaceAll('أ', _alef) // hamza-on-alef -> alef
        .replaceAll('إ', _alef) // hamza-under-alef -> alef
        .replaceAll('آ', _alef) // alef-madda -> alef
        .replaceAll('ٱ', _alef) // alef-wasla -> alef
        .replaceAll('\u0621', '') // hamza letter -> gone
        .replaceAll('\u0624', '\u0648') // hamza on waw -> waw
        .replaceAll('\u0626', '\u064A') // hamza on yeh -> yeh
        .replaceAll('ة', 'ه') // teh marbuta -> heh
        .replaceAll('ى', 'ي'); // alef maksura -> yeh
    // Drop a leading "al-" so "al-baqarah" and "baqarah" (Arabic) compare equal.
    if (s.startsWith('$_alef$_lam')) {
      s = s.substring(2).trim();
    }
    return s.trim();
  }

  /// Whether [target] contains [query] after normalising both. An empty query
  /// matches everything.
  static bool matches(String query, String target) {
    final q = normalize(query);
    if (q.isEmpty) return true;
    return normalize(target).contains(q);
  }

  /// Whether a sura matches [query] by its number, English name or Arabic name.
  static bool suraMatches({
    required String query,
    required int number,
    required String nameEn,
    required String nameAr,
  }) {
    final q = normalize(query);
    if (q.isEmpty) return true;
    return number.toString().contains(q) ||
        normalize(nameEn).contains(q) ||
        normalize(nameAr).contains(q);
  }
}
