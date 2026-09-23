import 'dart:async';

import 'package:audioplayers/audioplayers.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

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

  StreamSubscription<PlayerState>? _sub;

  SuraPlaybackCubit({
    required this.reciter,
    required this.audioPlayerService,
    required this.findDownloadedFile,
    required this.connectivityService,
  }) : super(const SuraPlaybackState()) {
    _sub = audioPlayerService.onStateChanged.listen((s) {
      if (!isClosed) {
        emit(state.copyWith(isPlaying: s == PlayerState.playing));
      }
    });
  }

  Future<void> toggle(int sura) async {
    final suraId = sura.toString();

    // Tapping the current sura toggles pause/resume.
    if (state.currentSuraId == suraId) {
      if (state.isPlaying) {
        await audioPlayerService.pause();
      } else {
        await audioPlayerService.resume();
      }
      return;
    }

    // Local first — a downloaded file plays without any connection.
    final downloaded = await findDownloadedFile(
      DownloadKey(reciterId: reciter.id.toString(), suraId: suraId),
    );
    final path = downloaded.getOrElse(() => null);
    if (path != null) {
      emit(state.copyWith(currentSuraId: suraId));
      await audioPlayerService.playFile(path);
      return;
    }

    // Otherwise stream, but only if there is a connection.
    if (await connectivityService.isConnected) {
      emit(state.copyWith(currentSuraId: suraId));
      await audioPlayerService.playUrl(reciter.audioUrlFor(sura));
      return;
    }

    emit(
      state.copyWith(
        notice:
            "You're offline. Download this sura to play it without a "
            'connection.',
        noticeSeq: state.noticeSeq + 1,
      ),
    );
  }

  @override
  Future<void> close() {
    _sub?.cancel();
    audioPlayerService.stop();
    return super.close();
  }
}
