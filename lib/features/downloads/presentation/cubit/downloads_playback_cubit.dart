import 'dart:async';

import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/presentation/playback_controller.dart';
import '../../../../core/services/audio_player_service.dart';
import '../../domain/entities/download_entry.dart';
import '../../domain/entities/download_key.dart';
import '../../domain/usecases/find_downloaded_file.dart';
import '../bloc/downloads_bloc.dart';

part 'downloads_playback_state.dart';

/// Plays already-downloaded suras straight from the Downloads screen.
///
/// Deliberately separate from `SuraPlaybackCubit`, which is scoped to one
/// reciter and builds stream URLs — here every entry is a local file from any
/// reciter, so it just plays a [DownloadEntry] by its path. Because
/// [AudioPlayerService] is a single app-wide player, starting playback here
/// stops whatever was playing elsewhere (and vice-versa).
class DownloadsPlaybackCubit extends Cubit<DownloadsPlaybackState> {
  final AudioPlayerService audioPlayerService;
  final FindDownloadedFile findDownloadedFile;

  /// Used only to drop a stale index entry via the existing reconcile path.
  final DownloadsBloc downloadsBloc;

  late final PlaybackController _playback;
  StreamSubscription<PlaybackStatus>? _sub;

  DownloadsPlaybackCubit({
    required this.audioPlayerService,
    required this.findDownloadedFile,
    required this.downloadsBloc,
  }) : super(const DownloadsPlaybackState()) {
    _playback = PlaybackController(audioPlayerService: audioPlayerService);
    _sub = _playback.statusStream.listen((status) {
      if (isClosed) return;
      final id = status.currentId;
      emit(
        state.copyWith(
          currentKey: id.isEmpty ? null : DownloadKey.parse(id),
          clearCurrentKey: id.isEmpty,
          isPlaying: status.isPlaying,
        ),
      );
    });
  }

  Future<void> toggle(DownloadEntry entry) async {
    final id = entry.key.toString();

    // Tapping the current entry toggles pause/resume.
    if (_playback.isCurrent(id)) return _playback.togglePause();

    // The file may have been deleted outside the app since the index was built.
    final downloaded = await findDownloadedFile(entry.key);
    final path = downloaded.getOrElse(() => null);
    if (path == null) {
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

    await _playback.play(id, () => audioPlayerService.playFile(path));
  }

  /// Stops playback if [entry] is the one playing — call before deleting it so
  /// the player never holds a deleted file.
  Future<void> stopIfCurrent(DownloadEntry entry) async {
    await _playback.stopWhere((id) => id == entry.key.toString());
  }

  /// Stops playback if the current entry belongs to [reciterId] (used before a
  /// "delete all for this reciter").
  Future<void> stopIfReciter(String reciterId) async {
    await _playback.stopWhere(
      (id) => DownloadKey.parse(id).reciterId == reciterId,
    );
  }

  @override
  Future<void> close() {
    _sub?.cancel();
    // Only stops if this screen actually owns the current audio, so merely
    // opening and leaving Downloads doesn't cut off playback started elsewhere.
    _playback.close();
    return super.close();
  }
}
