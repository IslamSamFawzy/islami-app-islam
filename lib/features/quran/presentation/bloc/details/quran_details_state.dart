part of 'quran_details_bloc.dart';

enum DetailsStatus { initial, loading, success, failure }

class QuranDetailsState extends Equatable {
  final DetailsStatus status;
  final List<String> verses;
  final String errorMessage;

  const QuranDetailsState({
    this.status = DetailsStatus.initial,
    this.verses = const [],
    this.errorMessage = '',
  });

  QuranDetailsState copyWith({
    DetailsStatus? status,
    List<String>? verses,
    String? errorMessage,
  }) {
    return QuranDetailsState(
      status: status ?? this.status,
      verses: verses ?? this.verses,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }

  @override
  List<Object?> get props => [status, verses, errorMessage];
}
