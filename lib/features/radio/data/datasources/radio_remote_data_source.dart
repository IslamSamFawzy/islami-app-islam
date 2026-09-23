import '../../../../core/network/api_client.dart';
import '../models/radio_station_model.dart';
import '../models/reciter_model.dart';

abstract class RadioRemoteDataSource {
  Future<List<RadioStationModel>> getRadios();

  Future<List<ReciterModel>> getReciters();
}

class RadioRemoteDataSourceImpl implements RadioRemoteDataSource {
  final ApiClient apiClient;

  RadioRemoteDataSourceImpl({required this.apiClient});

  static const String _base = 'https://mp3quran.net/api/v3';
  static const Duration _timeout = Duration(seconds: 15);

  @override
  Future<List<RadioStationModel>> getRadios() async {
    final body = await apiClient.getJson(
      '$_base/radios?language=ar',
      timeout: _timeout,
    );
    final list = (body['radios'] as List?) ?? const [];
    return list
        .map((e) => RadioStationModel.fromJson((e as Map).cast<String, dynamic>()))
        .toList();
  }

  @override
  Future<List<ReciterModel>> getReciters() async {
    final body = await apiClient.getJson(
      '$_base/reciters?language=ar',
      timeout: _timeout,
    );
    final list = (body['reciters'] as List?) ?? const [];
    return list
        .map((e) => ReciterModel.fromApi((e as Map).cast<String, dynamic>()))
        .where((r) => r.moshafServer.isNotEmpty && r.surahList.isNotEmpty)
        .toList();
  }
}
