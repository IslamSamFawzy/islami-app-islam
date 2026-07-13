part of 'quran_details_bloc.dart';

enum DetailsStatus { initial, loading, success, failure }

class QuranDetailsState extends Equatable {
  final DetailsStatus status;
  final List<String> verses;

  /// Index of the ayah rendered filled-gold ("currently read"); -1 = none.
  final int selectedIndex;
  final String errorMessage;

  const QuranDetailsState({
    this.status = DetailsStatus.initial,
    this.verses = const [],
    this.selectedIndex = -1,
    this.errorMessage = '',
  });

  QuranDetailsState copyWith({
    DetailsStatus? status,
    List<String>? verses,
    int? selectedIndex,
    String? errorMessage,
  }) {
    return QuranDetailsState(
      status: status ?? this.status,
      verses: verses ?? this.verses,
      selectedIndex: selectedIndex ?? this.selectedIndex,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }

  @override
  List<Object?> get props => [status, verses, selectedIndex, errorMessage];
}
