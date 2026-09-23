import 'dart:convert';

import 'package:dio/dio.dart';

import '../error/exceptions.dart';

/// The app's one way of talking to a JSON API: GET, check the status, decode.
///
/// Remote data sources depend on this rather than on an HTTP package, so the
/// transport (currently Dio) stays inside `core/network`.
abstract class ApiClient {
  /// GETs [url] and returns the decoded JSON object.
  ///
  /// Throws [ServerException] on a non-200 status, a timeout, a transport
  /// failure, or a body that is not a JSON object.
  Future<Map<String, dynamic>> getJson(String url, {Duration? timeout});
}

class DioApiClient implements ApiClient {
  final Dio dio;

  DioApiClient({Dio? dio}) : dio = dio ?? Dio();

  /// Used when a caller does not ask for a specific timeout.
  static const Duration defaultTimeout = Duration(seconds: 20);

  @override
  Future<Map<String, dynamic>> getJson(String url, {Duration? timeout}) async {
    try {
      final response = await dio
          .get<String>(
            url,
            options: Options(
              responseType: ResponseType.plain,
              // Statuses are checked here so every caller gets the same
              // ServerException instead of a Dio-specific error.
              validateStatus: (_) => true,
            ),
          )
          .timeout(timeout ?? defaultTimeout);

      if (response.statusCode != 200) {
        throw ServerException(
          'Request failed (${response.statusCode}) for $url',
        );
      }
      final decoded = json.decode(response.data ?? '');
      if (decoded is! Map) {
        throw ServerException('Unexpected response from $url');
      }
      return decoded.cast<String, dynamic>();
    } on ServerException {
      rethrow;
    } catch (e) {
      throw ServerException('Failed to reach $url: $e');
    }
  }
}
