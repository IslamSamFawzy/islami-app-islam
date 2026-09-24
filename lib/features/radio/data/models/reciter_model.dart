import '../../../../core/network/secure_url.dart';
import '../../domain/entities/reciter.dart';

class ReciterModel extends Reciter {
  const ReciterModel({
    required super.id,
    required super.name,
    required super.moshafServer,
    required super.surahList,
  });

  /// Builds from an mp3quran API reciter object, taking the server and the
  /// recorded sura list from the reciter's first moshaf.
  factory ReciterModel.fromApi(Map<String, dynamic> json) {
    final moshafList = (json['moshaf'] as List?) ?? const [];
    var server = '';
    var suras = const <int>[];
    if (moshafList.isNotEmpty) {
      final first = (moshafList.first as Map).cast<String, dynamic>();
      server = secureUrl((first['server'] as String?) ?? '');
      if (server.isNotEmpty && !server.endsWith('/')) {
        server = '$server/';
      }
      // The API returns surah_list as a comma-separated string of numbers.
      suras = _parseSurahList(first['surah_list']);
    }
    return ReciterModel(
      id: (json['id'] as num?)?.toInt() ?? 0,
      name: (json['name'] as String?) ?? '',
      moshafServer: server,
      surahList: suras,
    );
  }

  /// Builds from a cached JSON object produced by [toJson].
  factory ReciterModel.fromJson(Map<String, dynamic> json) {
    return ReciterModel(
      id: (json['id'] as num?)?.toInt() ?? 0,
      name: (json['name'] as String?) ?? '',
      // Normalised again: a cache written before the app started doing this
      // can still hold a cleartext server.
      moshafServer: secureUrl((json['moshafServer'] as String?) ?? ''),
      surahList: _parseSurahList(json['surahList']),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'moshafServer': moshafServer,
        'surahList': surahList,
      };

  /// Parses sura numbers from either the API's comma-separated string or a
  /// cached `List`.
  static List<int> _parseSurahList(Object? raw) {
    Iterable<String> parts;
    if (raw is List) {
      parts = raw.map((e) => '$e');
    } else if (raw is String) {
      parts = raw.split(',');
    } else {
      return const [];
    }
    return parts
        .map((s) => int.tryParse(s.trim()) ?? 0)
        .where((n) => n > 0)
        .toList();
  }
}
