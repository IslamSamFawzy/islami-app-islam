import 'package:flutter_test/flutter_test.dart';
import 'package:islami/core/error/exceptions.dart';
import 'package:islami/core/error/failures.dart';
import 'package:islami/features/radio/data/datasources/radio_local_data_source.dart';
import 'package:islami/features/radio/data/datasources/radio_remote_data_source.dart';
import 'package:islami/features/radio/data/models/radio_station_model.dart';
import 'package:islami/features/radio/data/models/reciter_model.dart';
import 'package:islami/features/radio/data/repositories/radio_repository_impl.dart';

class _FakeRemote implements RadioRemoteDataSource {
  List<RadioStationModel> radios = const [];
  List<ReciterModel> reciters = const [];
  bool throwServer = false;
  int radioCalls = 0;

  @override
  Future<List<RadioStationModel>> getRadios() async {
    radioCalls++;
    if (throwServer) throw ServerException('down');
    return radios;
  }

  @override
  Future<List<ReciterModel>> getReciters() async {
    if (throwServer) throw ServerException('down');
    return reciters;
  }
}

class _FakeLocal implements RadioLocalDataSource {
  List<RadioStationModel>? cachedRadios;
  List<ReciterModel>? cachedReciters;

  @override
  Future<void> cacheRadios(List<RadioStationModel> radios) async {
    cachedRadios = radios;
  }

  @override
  List<RadioStationModel>? getCachedRadios() => cachedRadios;

  @override
  Future<void> cacheReciters(List<ReciterModel> reciters) async {
    cachedReciters = reciters;
  }

  @override
  List<ReciterModel>? getCachedReciters() => cachedReciters;
}

void main() {
  late _FakeRemote remote;
  late _FakeLocal local;
  late RadioRepositoryImpl repo;

  const cached = RadioStationModel(id: 1, name: 'Cached', url: 'u1');
  const fresh = RadioStationModel(id: 2, name: 'Fresh', url: 'u2');

  setUp(() {
    remote = _FakeRemote();
    local = _FakeLocal();
    repo = RadioRepositoryImpl(remoteDataSource: remote, localDataSource: local);
  });

  test('cache-first returns cached data without hitting the network', () async {
    local.cachedRadios = [cached];
    remote.radios = [fresh];

    final result = await repo.getRadios();

    result.fold((_) => fail('expected Right'), (r) {
      expect(r.fromCache, isTrue);
      expect(r.data, [cached]);
    });
    expect(remote.radioCalls, 0);
  });

  test('cache miss falls through to the network and caches the result', () async {
    remote.radios = [fresh];

    final result = await repo.getRadios();

    result.fold((_) => fail('expected Right'), (r) {
      expect(r.fromCache, isFalse);
      expect(r.data, [fresh]);
    });
    expect(local.cachedRadios, [fresh]);
  });

  test('forceRefresh overwrites the cache with fresh network data', () async {
    local.cachedRadios = [cached];
    remote.radios = [fresh];

    final result = await repo.getRadios(forceRefresh: true);

    result.fold((_) => fail('expected Right'), (r) {
      expect(r.fromCache, isFalse);
      expect(r.data, [fresh]);
    });
    expect(local.cachedRadios, [fresh]);
    expect(remote.radioCalls, 1);
  });

  test('network failure falls back to cache when one exists', () async {
    local.cachedRadios = [cached];
    remote.throwServer = true;

    final result = await repo.getRadios(forceRefresh: true);

    result.fold((_) => fail('expected Right'), (r) {
      expect(r.fromCache, isTrue);
      expect(r.data, [cached]);
    });
  });

  test('network failure with no cache surfaces a ServerFailure', () async {
    remote.throwServer = true;

    final result = await repo.getRadios(forceRefresh: true);

    expect(result.isLeft(), isTrue);
    result.fold(
      (f) => expect(f, isA<ServerFailure>()),
      (_) => fail('expected Left'),
    );
  });
}
