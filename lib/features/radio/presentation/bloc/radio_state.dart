part of 'radio_bloc.dart';

enum RadioTab { radio, reciters }

class RadioState extends Equatable {
  final ViewStatus status;
  final List<RadioStation> radios;
  final List<Reciter> reciters;
  final RadioTab tab;

  /// Search query filtering the active tab's list (cleared on tab switch).
  final String query;

  final String currentId;
  final bool isPlaying;
  final String errorMessage;

  /// Whether the currently displayed lists came from the cache rather than a
  /// fresh network fetch.
  final bool isFromCache;

  /// A one-shot user message (e.g. tapping a live stream while offline).
  final UiNotice notice;

  const RadioState({
    this.status = ViewStatus.initial,
    this.radios = const [],
    this.reciters = const [],
    this.tab = RadioTab.radio,
    this.query = '',
    this.currentId = '',
    this.isPlaying = false,
    this.errorMessage = '',
    this.isFromCache = false,
    this.notice = const UiNotice.none(),
  });

  /// Radios matching [query] (all of them when the query is empty).
  List<RadioStation> get filteredRadios => query.isEmpty
      ? radios
      : radios.where((s) => ArabicSearch.matches(query, s.name)).toList();

  /// Reciters matching [query] (all of them when the query is empty).
  List<Reciter> get filteredReciters => query.isEmpty
      ? reciters
      : reciters.where((r) => ArabicSearch.matches(query, r.name)).toList();

  /// Whether there is saved content on screen — what the offline strip is
  /// about (data shown while offline is saved data either way).
  bool get hasSavedData => radios.isNotEmpty || reciters.isNotEmpty;

  RadioState copyWith({
    ViewStatus? status,
    List<RadioStation>? radios,
    List<Reciter>? reciters,
    RadioTab? tab,
    String? query,
    String? currentId,
    bool? isPlaying,
    String? errorMessage,
    bool? isFromCache,
    UiNotice? notice,
  }) {
    return RadioState(
      status: status ?? this.status,
      radios: radios ?? this.radios,
      reciters: reciters ?? this.reciters,
      tab: tab ?? this.tab,
      query: query ?? this.query,
      currentId: currentId ?? this.currentId,
      isPlaying: isPlaying ?? this.isPlaying,
      errorMessage: errorMessage ?? this.errorMessage,
      isFromCache: isFromCache ?? this.isFromCache,
      notice: notice ?? this.notice,
    );
  }

  @override
  List<Object?> get props => [
        status,
        radios,
        reciters,
        tab,
        query,
        currentId,
        isPlaying,
        errorMessage,
        isFromCache,
        notice,
      ];
}
