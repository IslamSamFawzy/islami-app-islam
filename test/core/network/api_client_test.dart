import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:islami/core/error/exceptions.dart';
import 'package:islami/core/network/api_client.dart';

/// Answers every request with a canned status/body, so the client can be
/// exercised without a network.
class _CannedAdapter implements HttpClientAdapter {
  final int statusCode;
  final String body;

  _CannedAdapter(this.statusCode, this.body);

  @override
  void close({bool force = false}) {}

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    return ResponseBody.fromString(
      body,
      statusCode,
      headers: {
        Headers.contentTypeHeader: [Headers.jsonContentType],
      },
    );
  }
}

void main() {
  DioApiClient clientFor(int status, String body) {
    final dio = Dio()..httpClientAdapter = _CannedAdapter(status, body);
    return DioApiClient(dio: dio);
  }

  test('decodes a JSON object body', () async {
    final client = clientFor(200, '{"radios":[{"id":1}]}');

    final body = await client.getJson('https://example.test/radios');

    expect(body['radios'], [
      {'id': 1},
    ]);
  });

  test('throws ServerException carrying the status code', () async {
    final client = clientFor(503, 'unavailable');

    expect(
      () => client.getJson('https://example.test/radios'),
      throwsA(
        isA<ServerException>().having(
          (e) => e.message,
          'message',
          contains('503'),
        ),
      ),
    );
  });

  test('throws ServerException when the body is not a JSON object', () async {
    final client = clientFor(200, '[1, 2, 3]');

    expect(
      () => client.getJson('https://example.test/radios'),
      throwsA(isA<ServerException>()),
    );
  });
}
