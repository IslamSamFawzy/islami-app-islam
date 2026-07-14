part of 'sura_playback_cubit.dart';

class SuraPlaybackState extends Equatable {
  /// Sura number (as a string) currently loaded, or `''` when nothing plays.
  final String currentSuraId;
  final bool isPlaying;

  /// A one-shot user message (e.g. "download to play offline"). [noticeSeq]
  /// changes on every new notice so the UI can show it exactly once.
  final String notice;
  final int noticeSeq;

  const SuraPlaybackState({
    this.currentSuraId = '',
    this.isPlaying = false,
    this.notice = '',
    this.noticeSeq = 0,
  });

  bool isCurrent(int sura) => currentSuraId == sura.toString();

  SuraPlaybackState copyWith({
    String? currentSuraId,
    bool? isPlaying,
    String? notice,
    int? noticeSeq,
  }) {
    return SuraPlaybackState(
      currentSuraId: currentSuraId ?? this.currentSuraId,
      isPlaying: isPlaying ?? this.isPlaying,
      notice: notice ?? this.notice,
      noticeSeq: noticeSeq ?? this.noticeSeq,
    );
  }

  @override
  List<Object?> get props => [currentSuraId, isPlaying, notice, noticeSeq];
}
