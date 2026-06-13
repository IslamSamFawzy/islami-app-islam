import 'dart:convert';

import 'package:http/http.dart' as http;

import '../../../../core/error/exceptions.dart';
import '../models/prayer_times_model.dart';

abstract class PrayerRemoteDataSource {
  Future<PrayerTimesModel> getPrayerTimes({
    required double latitude,
    required double longitude,
  });
}

class PrayerRemoteDataSourceImpl implements PrayerRemoteDataSource {
  final http.Client client;

  PrayerRemoteDataSourceImpl({required this.client});

  /// Aladhan calculation method (5 = Egyptian General Authority of Survey).
  static const int _method = 5;

  @override
  Future<PrayerTimesModel> getPrayerTimes({
    required double latitude,
    required double longitude,
  }) async {
    final uri = Uri.parse(
      'https://api.aladhan.com/v1/timings'
      '?latitude=$latitude&longitude=$longitude&method=$_method',
    );

    try {
      final response = await client.get(uri).timeout(
            const Duration(seconds: 15),
          );
      if (response.statusCode != 200) {
        throw ServerException('Prayer API error (${response.statusCode})');
      }
      final body = json.decode(response.body) as Map<String, dynamic>;
      final data = (body['data'] as Map).cast<String, dynamic>();
      return PrayerTimesModel.fromJson(data);
    } on ServerException {
      rethrow;
    } catch (e) {
      throw ServerException('Failed to load prayer times: $e');
    }
  }
}
