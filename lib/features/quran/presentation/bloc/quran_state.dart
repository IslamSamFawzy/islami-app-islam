part of 'quran_bloc.dart';

enum QuranStatus { initial, loading, success, failure }

class QuranState extends Equatable {
  final QuranStatus status;
  final List<Sura> allSuras;
  final List<Sura> filteredSuras;
  final List<Sura> recentSuras;
  final String query;
  final String errorMessage;

  const QuranState({
    this.status = QuranStatus.initial,
    this.allSuras = const [],
    this.filteredSuras = const [],
    this.recentSuras = const [],
    this.query = '',
    this.errorMessage = '',
  });

  QuranState copyWith({
    QuranStatus? status,
    List<Sura>? allSuras,
    List<Sura>? filteredSuras,
    List<Sura>? recentSuras,
    String? query,
    String? errorMessage,
  }) {
    return QuranState(
      status: status ?? this.status,
      allSuras: allSuras ?? this.allSuras,
      filteredSuras: filteredSuras ?? this.filteredSuras,
      recentSuras: recentSuras ?? this.recentSuras,
      query: query ?? this.query,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }

  @override
  List<Object?> get props =>
      [status, allSuras, filteredSuras, recentSuras, query, errorMessage];
}
