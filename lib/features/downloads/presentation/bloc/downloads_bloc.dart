import 'dart:async';
import 'dart:io';

import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/services/download_service.dart';
import '../../data/datasources/downloads_local_data_source.dart';
import '../../data/models/download_entry_model.dart';
import '../../domain/entities/download_entry.dart';

part 'downloads_event.dart';
part 'downloads_state.dart';

/// Owns the download queue (one download at a time), per-item progress, and the
/// on-disk index. Registered app-wide so downloads survive screen changes.
class DownloadsBloc extends Bloc<DownloadsEvent, DownloadsState> {
  final DownloadService downloadService;
  final DownloadsLocalDataSource localDataSource;

  StreamSubscription<double>? _progressSub;

  /// URLs for queued/active keys, needed to (re)start a download.
  final Map<String, String> _urls = {};

  /// Display names by reciter id, so completed entries can be labelled.
  final Map<String, String> _reciterNames = {};

  DownloadsBloc({
    required this.downloadService,
    required this.localDataSource,
  }) : super(const DownloadsState()) {
    on<LoadDownloadsEvent>(_onLoad);
    on<EnqueueDownloadEvent>(_onEnqueue);
    on<CancelDownloadEvent>(_onCancel);
    on<DeleteDownloadEvent>(_onDelete);
    on<DeleteReciterDownloadsEvent>(_onDeleteReciter);
    on<_DownloadProgressEvent>(_onProgress);
    on<_DownloadCompletedEvent>(_onCompleted);
    on<_DownloadFailedEvent>(_onFailed);

    _progressSub = downloadService.progress.listen((p) {
      if (!isClosed) add(_DownloadProgressEvent(p));
    });
  }

  Future<void> _onLoad(
    LoadDownloadsEvent event,
    Emitter<DownloadsState> emit,
  ) async {
    final valid = <String, DownloadEntry>{};
    for (final e in localDataSource.getAll()) {
      if (await File(e.path).exists()) {
        valid[e.key] = e;
      } else {
        await localDataSource.remove(e.reciterId, e.suraId);
      }
    }
    emit(state.copyWith(entries: valid));
  }

  Future<void> _onEnqueue(
    EnqueueDownloadEvent event,
    Emitter<DownloadsState> emit,
  ) async {
    final key = DownloadsState.keyOf(event.reciterId, event.suraId);
    if (state.entries.containsKey(key) ||
        state.activeKey == key ||
        state.queue.contains(key)) {
      return; // already downloaded, active, or queued
    }
    _urls[key] = event.url;
    _reciterNames[event.reciterId] = event.reciterName;
    emit(state.copyWith(queue: [...state.queue, key]));
    _maybeStartNext(emit);
  }

  void _maybeStartNext(Emitter<DownloadsState> emit) {
    if (state.activeKey.isNotEmpty || state.queue.isEmpty) return;
    final key = state.queue.first;
    final url = _urls[key];
    final rest = state.queue.sublist(1);
    if (url == null) {
      emit(state.copyWith(queue: rest));
      return;
    }
    emit(state.copyWith(queue: rest, activeKey: key, activeProgress: 0));
    _beginDownload(key, url);
  }

  void _beginDownload(String key, String url) {
    final parts = key.split('/');
    final reciterId = parts[0];
    final suraId = parts.length > 1 ? parts[1] : '';
    downloadService
        .download(url: url, reciterId: reciterId, suraId: suraId)
        .then((path) async {
      final bytes = await downloadService.fileSize(reciterId, suraId);
      if (!isClosed) {
        add(_DownloadCompletedEvent(DownloadEntry(
          reciterId: reciterId,
          reciterName: _reciterNames[reciterId] ?? '',
          suraId: suraId,
          path: path,
          bytes: bytes,
          downloadedAt: DateTime.now(),
        )));
      }
    }).catchError((_) {
      if (!isClosed) add(_DownloadFailedEvent(key));
    });
  }

  void _onProgress(_DownloadProgressEvent event, Emitter<DownloadsState> emit) {
    if (state.activeKey.isEmpty) return;
    emit(state.copyWith(activeProgress: event.progress));
  }

  Future<void> _onCompleted(
    _DownloadCompletedEvent event,
    Emitter<DownloadsState> emit,
  ) async {
    final entry = event.entry;
    await localDataSource.put(DownloadEntryModel.fromEntry(entry));
    _urls.remove(entry.key);
    final entries = Map<String, DownloadEntry>.from(state.entries)
      ..[entry.key] = entry;
    emit(state.copyWith(entries: entries, activeKey: '', activeProgress: 0));
    _maybeStartNext(emit);
  }

  void _onFailed(_DownloadFailedEvent event, Emitter<DownloadsState> emit) {
    _urls.remove(event.key);
    // A late failure for a no-longer-active key (e.g. cancelled) just advances.
    if (state.activeKey == event.key) {
      emit(state.copyWith(activeKey: '', activeProgress: 0));
    }
    _maybeStartNext(emit);
  }

  Future<void> _onCancel(
    CancelDownloadEvent event,
    Emitter<DownloadsState> emit,
  ) async {
    final key = DownloadsState.keyOf(event.reciterId, event.suraId);
    _urls.remove(key);
    if (state.activeKey == key) {
      // Clear active first so the resulting failure is a no-op, then cancel.
      emit(state.copyWith(activeKey: '', activeProgress: 0));
      downloadService.cancel();
      _maybeStartNext(emit);
    } else if (state.queue.contains(key)) {
      emit(state.copyWith(
        queue: state.queue.where((k) => k != key).toList(),
      ));
    }
  }

  Future<void> _onDelete(
    DeleteDownloadEvent event,
    Emitter<DownloadsState> emit,
  ) async {
    await downloadService.delete(event.reciterId, event.suraId);
    await localDataSource.remove(event.reciterId, event.suraId);
    final entries = Map<String, DownloadEntry>.from(state.entries)
      ..remove(DownloadsState.keyOf(event.reciterId, event.suraId));
    emit(state.copyWith(entries: entries));
  }

  Future<void> _onDeleteReciter(
    DeleteReciterDownloadsEvent event,
    Emitter<DownloadsState> emit,
  ) async {
    await downloadService.deleteReciter(event.reciterId);
    await localDataSource.removeReciter(event.reciterId);
    final entries = Map<String, DownloadEntry>.from(state.entries)
      ..removeWhere((_, e) => e.reciterId == event.reciterId);
    emit(state.copyWith(entries: entries));
  }

  @override
  Future<void> close() {
    _progressSub?.cancel();
    return super.close();
  }
}
