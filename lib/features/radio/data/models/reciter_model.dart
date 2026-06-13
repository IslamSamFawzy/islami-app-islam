import '../../domain/entities/reciter.dart';

class ReciterModel extends Reciter {
  const ReciterModel({
    required super.id,
    required super.name,
    required super.playUrl,
  });

  factory ReciterModel.fromJson(Map<String, dynamic> json) {
    final moshafList = (json['moshaf'] as List?) ?? const [];
    String playUrl = '';
    if (moshafList.isNotEmpty) {
      final first = (moshafList.first as Map).cast<String, dynamic>();
      var server = (first['server'] as String?) ?? '';
      if (server.isNotEmpty && !server.endsWith('/')) {
        server = '$server/';
      }
      // Al-Fatiha (surah 001) as a representative sample.
      if (server.isNotEmpty) {
        playUrl = '${server}001.mp3';
      }
    }
    return ReciterModel(
      id: (json['id'] as num?)?.toInt() ?? 0,
      name: (json['name'] as String?) ?? '',
      playUrl: playUrl,
    );
  }
}
