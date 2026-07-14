import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:islami/core/services/download_service.dart';
import 'package:islami/features/downloads/data/datasources/downloads_local_data_source.dart';
import 'package:islami/features/downloads/data/models/download_entry_model.dart';
import 'package:islami/features/downloads/presentation/bloc/downloads_bloc.dart';

class _FakeDownloadService implements DownloadService {
  final _controller = StreamController<double>.broadcast();
  final List<String> downloaded = [];

  @override
  Stream<double> get progress => _controller.stream;

  @override
  Future<String> download({
    required String url,
    required String reciterId,
    required String suraId,
  }) async {
    _controller.add(0.5);
    _controller.add(1.0);
    downloaded.add('$reciterId/$suraId');
    return '/fake/$reciterId/$suraId.mp3';
  }

  @override
  void cancel() {}

  @override
  Future<void> delete(String reciterId, String suraId) async {}

  @override
  Future<void> deleteReciter(String reciterId) async {}

  @override
  Future<int> fileSize(String reciterId, String suraId) async => 2048;

  @override
  Future<String> filePath(String reciterId, String suraId) async =>
      '/fake/$reciterId/$suraId.mp3';

  @override
  Future<void> dispose() async => _controller.close();
}

class _FakeLocal implements DownloadsLocalDataSource {
  final Map<String, DownloadEntryModel> store = {};

  @override
  List<DownloadEntryModel> getAll() => store.values.toList();

  @override
  DownloadEntryModel? get(String reciterId, String suraId) =>
      store['$reciterId/$suraId'];

  @override
  Future<void> put(DownloadEntryModel entry) async => store[entry.key] = entry;

  @override
  Future<void> remove(String reciterId, String suraId) async =>
      store.remove('$reciterId/$suraId');

  @override
  Future<void> removeReciter(String reciterId) async =>
      store.removeWhere((k, _) => k.startsWith('$reciterId/'));
}

void main() {
  late _FakeDownloadService service;
  late _FakeLocal local;
  late DownloadsBloc bloc;

  setUp(() {
    service = _FakeDownloadService();
    local = _FakeLocal();
    bloc = DownloadsBloc(downloadService: service, localDataSource: local);
  });

  tearDown(() => bloc.close());

  test('enqueue downloads a sura and records it in the index', () async {
    bloc.add(const EnqueueDownloadEvent(reciterId: '1', suraId: '2', url: 'u'));

    await expectLater(
      bloc.stream,
      emitsThrough(predicate<DownloadsState>((s) =>
          s.isDownloaded('1', '2') && s.activeKey.isEmpty && s.queue.isEmpty)),
    );
    expect(local.get('1', '2'), isNotNull);
  });

  test('a queued second download runs after the first drains', () async {
    bloc.add(const EnqueueDownloadEvent(reciterId: '1', suraId: '2', url: 'u1'));
    bloc.add(const EnqueueDownloadEvent(reciterId: '1', suraId: '3', url: 'u2'));

    await expectLater(
      bloc.stream,
      emitsThrough(predicate<DownloadsState>((s) =>
          s.isDownloaded('1', '2') &&
          s.isDownloaded('1', '3') &&
          s.activeKey.isEmpty &&
          s.queue.isEmpty)),
    );
    expect(service.downloaded, ['1/2', '1/3']);
  });

  test('delete removes a sura from the index', () async {
    bloc.add(const EnqueueDownloadEvent(reciterId: '1', suraId: '2', url: 'u'));
    await expectLater(
      bloc.stream,
      emitsThrough(
          predicate<DownloadsState>((s) => s.isDownloaded('1', '2'))),
    );

    bloc.add(const DeleteDownloadEvent(reciterId: '1', suraId: '2'));
    await expectLater(
      bloc.stream,
      emitsThrough(
          predicate<DownloadsState>((s) => !s.isDownloaded('1', '2'))),
    );
    expect(local.get('1', '2'), isNull);
  });
}
