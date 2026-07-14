part of 'radio_bloc.dart';

enum RadioStatus { initial, loading, success, failure }

enum RadioTab { radio, reciters }

class RadioState extends Equatable {
  final RadioStatus status;
  final List<RadioStation> radios;
  final List<Reciter> reciters;
  final RadioTab tab;
  final String currentId;
  final bool isPlaying;
  final String errorMessage;

  /// Whether the currently displayed lists came from the cache rather than a
  /// fresh network fetch.
  final bool isFromCache;

  const RadioState({
    this.status = RadioStatus.initial,
    this.radios = const [],
    this.reciters = const [],
    this.tab = RadioTab.radio,
    this.currentId = '',
    this.isPlaying = false,
    this.errorMessage = '',
    this.isFromCache = false,
  });

  RadioState copyWith({
    RadioStatus? status,
    List<RadioStation>? radios,
    List<Reciter>? reciters,
    RadioTab? tab,
    String? currentId,
    bool? isPlaying,
    String? errorMessage,
    bool? isFromCache,
  }) {
    return RadioState(
      status: status ?? this.status,
      radios: radios ?? this.radios,
      reciters: reciters ?? this.reciters,
      tab: tab ?? this.tab,
      currentId: currentId ?? this.currentId,
      isPlaying: isPlaying ?? this.isPlaying,
      errorMessage: errorMessage ?? this.errorMessage,
      isFromCache: isFromCache ?? this.isFromCache,
    );
  }

  @override
  List<Object?> get props => [
        status,
        radios,
        reciters,
        tab,
        currentId,
        isPlaying,
        errorMessage,
        isFromCache,
      ];
}
