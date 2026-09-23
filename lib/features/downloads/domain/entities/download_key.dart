import 'package:equatable/equatable.dart';

/// Identifies one downloaded sura: which reciter, which sura.
///
/// Its string form, `<reciterId>/<suraId>`, is the key of the on-disk index,
/// so building and parsing it lives here rather than in the handful of
/// `'$a/$b'` and `split('/')` expressions it used to be spread across.
class DownloadKey extends Equatable {
  final String reciterId;
  final String suraId;

  const DownloadKey({required this.reciterId, required this.suraId});

  /// Reads the stored form. Everything after the first `/` is the sura id; a
  /// string without one yields an empty [suraId] rather than throwing.
  factory DownloadKey.parse(String raw) {
    final separator = raw.indexOf('/');
    if (separator < 0) return DownloadKey(reciterId: raw, suraId: '');
    return DownloadKey(
      reciterId: raw.substring(0, separator),
      suraId: raw.substring(separator + 1),
    );
  }

  @override
  String toString() => '$reciterId/$suraId';

  @override
  List<Object?> get props => [reciterId, suraId];
}
