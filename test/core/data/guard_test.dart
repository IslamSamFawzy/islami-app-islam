import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:islami/core/data/guard.dart';
import 'package:islami/core/error/exceptions.dart';
import 'package:islami/core/error/failures.dart';

void main() {
  test('passes the value through on success', () async {
    final result = await guardLocalData(() async => 42);

    expect(result, const Right<Failure, int>(42));
  });

  test('maps LocalDataException to LocalDataFailure, keeping the message',
      () async {
    final result = await guardLocalData<int>(
      () async => throw LocalDataException('assets/files/suras/1.txt missing'),
    );

    expect(
      result,
      const Left<Failure, int>(
        LocalDataFailure('assets/files/suras/1.txt missing'),
      ),
    );
  });

  test('lets other exceptions through', () async {
    expect(
      guardLocalData<int>(() async => throw CacheException()),
      throwsA(isA<CacheException>()),
    );
  });
}
