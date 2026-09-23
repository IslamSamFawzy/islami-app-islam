import '../../../../core/network/api_client.dart';
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
  final ApiClient apiClient;

  PrayerRemoteDataSourceImpl({required this.apiClient});

  /// Aladhan calculation method (5 = Egyptian General Authority of Survey).
  static const int _method = 5;
  static const Duration _timeout = Duration(seconds: 20);

  @override
  Future<List<PrayerTimesModel>> getMonthlyPrayerTimes({
    required double latitude,
    required double longitude,
    required int month,
    required int year,
  }) async {
    final body = await apiClient.getJson(
      'https://api.aladhan.com/v1/calendar'
      '?latitude=$latitude&longitude=$longitude&method=$_method'
      '&month=$month&year=$year',
      timeout: _timeout,
    );
    final data = (body['data'] as List?) ?? const [];
    return data
        .map((e) => PrayerTimesModel.fromApi((e as Map).cast<String, dynamic>()))
        .toList();
  }
}
