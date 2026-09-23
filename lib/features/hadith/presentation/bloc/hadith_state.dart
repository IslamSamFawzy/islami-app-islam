part of 'hadith_bloc.dart';

class HadithState extends Equatable {
  final ViewStatus status;
  final List<Hadith> hadiths;
  final String errorMessage;

  const HadithState({
    this.status = ViewStatus.initial,
    this.hadiths = const [],
    this.errorMessage = '',
  });

  HadithState copyWith({
    ViewStatus? status,
    List<Hadith>? hadiths,
    String? errorMessage,
  }) {
    return HadithState(
      status: status ?? this.status,
      hadiths: hadiths ?? this.hadiths,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }

  @override
  List<Object?> get props => [status, hadiths, errorMessage];
}
