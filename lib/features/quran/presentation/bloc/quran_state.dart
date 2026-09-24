part of 'quran_bloc.dart';

class QuranState extends Equatable {
  final ViewStatus status;
  final List<Sura> allSuras;
  final List<Sura> filteredSuras;
  final List<Sura> recentSuras;

  /// Where the reader stopped in each recent sura, by sura number.
  final Map<int, ReadingProgress> recentProgress;
  final String query;
  final String errorMessage;

  const QuranState({
    this.status = ViewStatus.initial,
    this.allSuras = const [],
    this.filteredSuras = const [],
    this.recentSuras = const [],
    this.recentProgress = const {},
    this.query = '',
    this.errorMessage = '',
  });

  QuranState copyWith({
    ViewStatus? status,
    List<Sura>? allSuras,
    List<Sura>? filteredSuras,
    List<Sura>? recentSuras,
    Map<int, ReadingProgress>? recentProgress,
    String? query,
    String? errorMessage,
  }) {
    return QuranState(
      status: status ?? this.status,
      allSuras: allSuras ?? this.allSuras,
      filteredSuras: filteredSuras ?? this.filteredSuras,
      recentSuras: recentSuras ?? this.recentSuras,
      recentProgress: recentProgress ?? this.recentProgress,
      query: query ?? this.query,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }

  @override
  List<Object?> get props => [
    status,
    allSuras,
    filteredSuras,
    recentSuras,
    recentProgress,
    query,
    errorMessage,
  ];
}
