import '../../../../core/utils/arabic_search.dart';
import '../entities/sura.dart';

/// Searches a list of [Sura] entities by a user-supplied query.
abstract class SuraSearchFilter {
  /// Returns a subset of [suras] that match [query].
  /// An empty [query] returns the input list unchanged.
  List<Sura> filter(List<Sura> suras, String query);
}

/// Default [SuraSearchFilter] used by [QuranBloc]: matches on the sura number,
/// the English name or the Arabic one, insensitive to hamza, tashkeel and a
/// leading "al-" — the same rules the reciter's sura list uses, so the two
/// search fields behave alike.
class DefaultSuraSearchFilter implements SuraSearchFilter {
  @override
  List<Sura> filter(List<Sura> suras, String query) {
    final raw = query.trim();
    if (raw.isEmpty) return suras;

    return suras
        .where(
          (sura) => ArabicSearch.suraMatches(
            query: raw,
            number: sura.id,
            nameEn: sura.nameEn,
            nameAr: sura.nameAr,
          ),
        )
        .toList();
  }
}
