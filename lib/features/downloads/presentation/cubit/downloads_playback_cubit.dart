import 'dart:async';

import 'package:audioplayers/audioplayers.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/services/audio_player_service.dart';
import '../../../../core/services/download_service.dart';
import '../../domain/entities/download_entry.dart';
import '../../domain/entities/download_key.dart';
import '../bloc/downloads_bloc.dart';

part 'downloads_playback_state.dart';

/// Plays already-downloaded suras straight from the Downloads screen.
///
/// Deliberately separate from [SuraPlaybackCubit], which is scoped to one
/// reciter and builds stream URLs — here every entry is a local file from any
/// reciter, so it just plays a [DownloadEntry] by its path. Because
/// [AudioPlayerService] is a single app-wide player, starting playback here
/// stops whatever was playing elsewhere (and vice-versa).
class DownloadsPlaybackCubit extends Cubit<DownloadsPlaybackState> {
  final AudioPlayerService audioPlayerService;
  final DownloadService downloadService;

  /// Used only to drop a stale index entry via the existing reconcile path.
  final DownloadsBloc downloadsBloc;

  StreamSubscription<PlayerState>? _sub;

  DownloadsPlaybackCubit({
    required this.audioPlayerService,
    required this.downloadService,
    required this.downloadsBloc,
  }) : super(const DownloadsPlaybackState()) {
    _sub = audioPlayerService.onStateChanged.listen((s) {
      if (!isClosed) {
        emit(state.copyWith(isPlaying: s == PlayerState.playing));
      }
    });
  }

  Future<void> toggle(DownloadEntry entry) async {
    // Tapping the current entry toggles pause/resume.
    if (state.currentKey == entry.key) {
      if (state.isPlaying) {
        await audioPlayerService.pause();
      } else {
        await audioPlayerService.resume();
      }
      return;
    }

    // The file may have been deleted outside the app since the index was built.
    if (!await downloadService.pathExists(entry.path)) {
      emit(
        state.copyWith(
          notice: 'This download is missing and was removed.',
          noticeSeq: state.noticeSeq + 1,
        ),
      );
      // Reuse the startup reconciliation to drop the stale entry — don't
      // duplicate the file-check/remove logic that DownloadsBloc already owns.
      downloadsBloc.add(const LoadDownloadsEvent());
      return;
    }

    emit(state.copyWith(currentKey: entry.key));
    await audioPlayerService.playFile(entry.path);
  }

  /// Stops playback if [entry] is the one playing — call before deleting it so
  /// the player never holds a deleted file.
  Future<void> stopIfCurrent(DownloadEntry entry) async {
    if (state.currentKey == entry.key) await _stop();
  }

  /// Stops playback if the current entry belongs to [reciterId] (used before a
  /// "delete all for this reciter").
  Future<void> stopIfReciter(String reciterId) async {
    if (state.currentKey?.reciterId == reciterId) await _stop();
  }

  Future<void> _stop() async {
    await audioPlayerService.stop();
    emit(state.copyWith(clearCurrentKey: true, isPlaying: false));
  }

  @override
  Future<void> close() {
    _sub?.cancel();
    // Only stop if this screen actually owns the current audio, so merely
    // opening and leaving Downloads doesn't cut off playback started elsewhere.
    if (state.currentKey != null) audioPlayerService.stop();
    return super.close();
  }
}
