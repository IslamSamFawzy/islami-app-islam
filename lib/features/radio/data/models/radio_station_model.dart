import '../../../../core/network/secure_url.dart';
import '../../domain/entities/radio_station.dart';

class RadioStationModel extends RadioStation {
  const RadioStationModel({
    required super.id,
    required super.name,
    required super.url,
  });

  /// The mp3quran radios API and the cache share the same shape, so this
  /// factory doubles as both the network and cache parser.
  factory RadioStationModel.fromJson(Map<String, dynamic> json) {
    return RadioStationModel(
      id: (json['id'] as num?)?.toInt() ?? 0,
      name: (json['name'] as String?) ?? '',
      // Covers both paths: a cleartext stream URL from the API, and one a
      // previous build cached before this.
      url: secureUrl((json['url'] as String?) ?? ''),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'url': url,
      };
}
