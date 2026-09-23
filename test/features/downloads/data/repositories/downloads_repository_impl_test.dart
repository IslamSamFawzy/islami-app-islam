import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:islami/core/error/failures.dart';
import 'package:islami/core/services/download_service.dart';
import 'package:islami/features/downloads/data/datasources/downloads_local_data_source.dart';
import 'package:islami/features/downloads/data/models/download_entry_model.dart';
import 'package:islami/features/downloads/data/repositories/downloads_repository_impl.dart';
import 'package:islami/features/downloads/domain/entities/download_key.dart';

class _FakeLocal implements DownloadsLocalDataSource {
  final Map<String, DownloadEntryModel> store = {};
  bool throwOnRead = false;

  @override
  List<DownloadEntryModel> getAll() {
    if (throwOnRead) throw const FormatException('corrupt index');
    return store.values.toList();
  }

  @override
  DownloadEntryModel? get(DownloadKey key) => store['$key'];

  @override
  Future<void> put(DownloadEntryModel entry) async =>
      store['${entry.key}'] = entry;

  @override
  Future<void> remove(DownloadKey key) async => store.remove('$key');

  @override
  Future<void> removeReciter(String reciterId) async =>
      store.removeWhere((k, _) => k.startsWith('$reciterId/'));
}

class _FakeDownloadService implements DownloadService {
  final Set<String> files = {};
  final List<String> deleted = [];

  @override
  Stream<double> get progress => const Stream.empty();
  @override
  Future<String> download({
    required String url,
    required String reciterId,
    required String suraId,
  }) async => '';
  @override
  void cancel() {}
  @override
  Future<void> delete(String reciterId, String suraId) async {
    deleted.add('$reciterId/$suraId');
    files.remove('/audio/$reciterId/$suraId.mp3');
  }

  @override
  Future<void> deleteReciter(String reciterId) async =>
      files.removeWhere((p) => p.startsWith('/audio/$reciterId/'));
  @override
  Future<int> fileSize(String reciterId, String suraId) async => 0;
  @override
  Future<bool> fileExists(String reciterId, String suraId) async =>
      files.contains('/audio/$reciterId/$suraId.mp3');
  @override
  Future<bool> pathExists(String path) async => files.contains(path);
  @override
  Future<String> filePath(String reciterId, String suraId) async =>
      '/audio/$reciterId/$suraId.mp3';
  @override
  Future<void> dispose() async {}
}

void main() {
  late _FakeLocal local;
  late _FakeDownloadService service;
  late DownloadsRepositoryImpl repository;

  DownloadEntryModel entry(String reciterId, String suraId) =>
      DownloadEntryModel(
        reciterId: reciterId,
        reciterName: 'R$reciterId',
        suraId: suraId,
        path: '/audio/$reciterId/$suraId.mp3',
        bytes: 10,
        downloadedAt: DateTime(2026),
      );

  /// Seeds the index and puts the matching file "on disk".
  Future<void> seed(String reciterId, String suraId, {bool onDisk = true}) async {
    final e = entry(reciterId, suraId);
    await local.put(e);
    if (onDisk) service.files.add(e.path);
  }

  setUp(() {
    local = _FakeLocal();
    service = _FakeDownloadService();
    repository = DownloadsRepositoryImpl(
      localDataSource: local,
      downloadService: service,
    );
  });

  test('getDownloads returns the index without touching the disk', () async {
    await seed('1', '2', onDisk: false);

    final result = await repository.getDownloads();

    expect(result.getOrElse(() => []), [entry('1', '2')]);
  });

  test('reconcile drops entries whose file is gone', () async {
    await seed('1', '2');
    await seed('1', '3', onDisk: false);

    final result = await repository.reconcile();

    expect(result.getOrElse(() => []), [entry('1', '2')]);
    expect(local.store.keys, ['1/2']);
  });

  test('save records an entry under its key', () async {
    final result = await repository.save(entry('1', '2'));

    expect(result, const Right<Failure, Unit>(unit));
    expect(local.store['1/2'], entry('1', '2'));
  });

  test('delete removes the file and the index entry', () async {
    await seed('1', '2');

    await repository.delete(const DownloadKey(reciterId: '1', suraId: '2'));

    expect(service.deleted, ['1/2']);
    expect(local.store, isEmpty);
  });

  test('deleteReciter removes every file and entry for that reciter', () async {
    await seed('1', '2');
    await seed('1', '3');
    await seed('9', '2');

    await repository.deleteReciter('1');

    expect(local.store.keys, ['9/2']);
    expect(service.files, {'/audio/9/2.mp3'});
  });

  group('findDownloadedFile', () {
    test('returns the path when the file is really there', () async {
      await seed('1', '2');

      final result = await repository.findDownloadedFile(
        const DownloadKey(reciterId: '1', suraId: '2'),
      );

      expect(result.getOrElse(() => null), '/audio/1/2.mp3');
    });

    test('returns null when the entry is indexed but the file is gone',
        () async {
      await seed('1', '2', onDisk: false);

      final result = await repository.findDownloadedFile(
        const DownloadKey(reciterId: '1', suraId: '2'),
      );

      expect(result.getOrElse(() => 'unexpected'), isNull);
    });

    test('returns null when nothing was ever downloaded', () async {
      final result = await repository.findDownloadedFile(
        const DownloadKey(reciterId: '1', suraId: '2'),
      );

      expect(result.getOrElse(() => 'unexpected'), isNull);
    });
  });

  test('a throwing index surfaces as a CacheFailure', () async {
    local.throwOnRead = true;

    final result = await repository.getDownloads();

    expect(result.isLeft(), isTrue);
    result.fold((failure) => expect(failure, isA<CacheFailure>()), (_) {});
  });
}
