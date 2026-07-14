import 'dart:convert';

import 'package:http/http.dart' as http;

import '../../../../core/error/exceptions.dart';
import '../models/prayer_times_model.dart';

abstract class PrayerRemoteDataSource {
  /// Fetches a whole month of prayer times (one entry per day) so a single
  /// online session covers the rest of the month offline.
  Future<List<PrayerTimesModel>> getMonthlyPrayerTimes({
    required double latitude,
    required double longitude,
    required int month,
    required int year,
  });
}

class PrayerRemoteDataSourceImpl implements PrayerRemoteDataSource {
  final http.Client client;

  PrayerRemoteDataSourceImpl({required this.client});

  /// Aladhan calculation method (5 = Egyptian General Authority of Survey).
  static const int _method = 5;

  @override
  Future<List<PrayerTimesModel>> getMonthlyPrayerTimes({
    required double latitude,
    required double longitude,
    required int month,
    required int year,
  }) async {
    final uri = Uri.parse(
      'https://api.aladhan.com/v1/calendar'
      '?latitude=$latitude&longitude=$longitude&method=$_method'
      '&month=$month&year=$year',
    );

    try {
      final response = await client.get(uri).timeout(
            const Duration(seconds: 20),
          );
      if (response.statusCode != 200) {
        throw ServerException('Prayer API error (${response.statusCode})');
      }
      final body = json.decode(response.body) as Map<String, dynamic>;
      final data = (body['data'] as List?) ?? const [];
      return data
          .map((e) =>
              PrayerTimesModel.fromApi((e as Map).cast<String, dynamic>()))
          .toList();
    } on ServerException {
      rethrow;
    } catch (e) {
      throw ServerException('Failed to load prayer times: $e');
    }
  }
}
