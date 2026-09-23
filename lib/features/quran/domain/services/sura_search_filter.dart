import '../entities/sura.dart';

/// Searches a list of [Sura] entities by a user-supplied query.
///
/// The default implementation matches on the English name (case-insensitive)
/// and on the Arabic name exactly as typed.
abstract class SuraSearchFilter {
  /// Returns a subset of [suras] that match [query].
  /// An empty [query] returns the input list unchanged.
  List<Sura> filter(List<Sura> suras, String query);
}

/// Default [SuraSearchFilter] used by [QuranBloc].
class DefaultSuraSearchFilter implements SuraSearchFilter {
  @override
  List<Sura> filter(List<Sura> suras, String query) {
    final raw = query.trim();
    if (raw.isEmpty) return suras;

    final lower = raw.toLowerCase();
    return suras
        .where(
          (sura) =>
              sura.nameEn.toLowerCase().contains(lower) ||
              sura.nameAr.contains(raw),
        )
        .toList();
  }
}
