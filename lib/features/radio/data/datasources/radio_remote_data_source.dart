import 'dart:convert';

import 'package:http/http.dart' as http;

import '../../../../core/error/exceptions.dart';
import '../models/radio_station_model.dart';
import '../models/reciter_model.dart';

abstract class RadioRemoteDataSource {
  Future<List<RadioStationModel>> getRadios();

  Future<List<ReciterModel>> getReciters();
}

class RadioRemoteDataSourceImpl implements RadioRemoteDataSource {
  final http.Client client;

  RadioRemoteDataSourceImpl({required this.client});

  static const String _base = 'https://mp3quran.net/api/v3';

  @override
  Future<List<RadioStationModel>> getRadios() async {
    final body = await _getJson('$_base/radios?language=ar');
    final list = (body['radios'] as List?) ?? const [];
    return list
        .map((e) => RadioStationModel.fromJson((e as Map).cast<String, dynamic>()))
        .toList();
  }

  @override
  Future<List<ReciterModel>> getReciters() async {
    final body = await _getJson('$_base/reciters?language=ar');
    final list = (body['reciters'] as List?) ?? const [];
    return list
        .map((e) => ReciterModel.fromJson((e as Map).cast<String, dynamic>()))
        .where((r) => r.playUrl.isNotEmpty)
        .toList();
  }

  Future<Map<String, dynamic>> _getJson(String url) async {
    try {
      final response = await client
          .get(Uri.parse(url))
          .timeout(const Duration(seconds: 15));
      if (response.statusCode != 200) {
        throw ServerException('Radio API error (${response.statusCode})');
      }
      return json.decode(response.body) as Map<String, dynamic>;
    } on ServerException {
      rethrow;
    } catch (e) {
      throw ServerException('Failed to load radio data: $e');
    }
  }
}
