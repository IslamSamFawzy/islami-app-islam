import 'dart:async';

import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/presentation/playback_controller.dart';
import '../../../../core/presentation/ui_notice.dart';
import '../../../../core/services/audio_player_service.dart';
import '../../../../core/services/connectivity_service.dart';
import '../../../downloads/domain/entities/download_key.dart';
import '../../../downloads/domain/usecases/find_downloaded_file.dart';
import '../../domain/entities/reciter.dart';

part 'sura_playback_state.dart';

/// Plays a reciter's suras, preferring a downloaded file so a saved sura plays
/// even in airplane mode; otherwise it streams (when online). Scoped to the
/// reciter sura screen.
class SuraPlaybackCubit extends Cubit<SuraPlaybackState> {
  final Reciter reciter;
  final AudioPlayerService audioPlayerService;
  final FindDownloadedFile findDownloadedFile;
  final ConnectivityService connectivityService;

  late final PlaybackController _playback;
  StreamSubscription<PlaybackStatus>? _sub;

  SuraPlaybackCubit({
    required this.reciter,
    required this.audioPlayerService,
    required this.findDownloadedFile,
    required this.connectivityService,
  }) : super(const SuraPlaybackState()) {
    _playback = PlaybackController(
      audioPlayerService: audioPlayerService,
      // Per reciter: two reciters both have a sura 2.
      owner: 'reciter_${reciter.id}',
    );
    _sub = _playback.statusStream.listen((status) {
      if (!isClosed) {
        emit(
          state.copyWith(
            currentSuraId: status.currentId,
            isPlaying: status.isPlaying,
          ),
        );
      }
    });
  }

  Future<void> toggle(int sura) async {
    final suraId = sura.toString();

    // Tapping the current sura toggles pause/resume.
    if (_playback.isCurrent(suraId)) return _playback.togglePause();

    // Local first — a downloaded file plays without any connection.
    final downloaded = await findDownloadedFile(
      DownloadKey(reciterId: reciter.id.toString(), suraId: suraId),
    );
    final path = downloaded.getOrElse(() => null);
    if (path != null) {
      return _playback.toggleFile(id: suraId, path: path);
    }

    // Otherwise stream, but only if there is a connection.
    if (await connectivityService.isConnected) {
      return _playback.toggleUrl(
        id: suraId,
        url: reciter.audioUrlFor(sura),
      );
    }

    emit(
      state.copyWith(
        notice: state.notice.next(
          "You're offline. Download this sura to play it without a "
          'connection.',
        ),
      ),
    );
  }

  @override
  Future<void> close() {
    _sub?.cancel();
    // Stops only audio this screen started (the shared player may be busy
    // with a download or a radio stream).
    _playback.close();
    return super.close();
  }
}
