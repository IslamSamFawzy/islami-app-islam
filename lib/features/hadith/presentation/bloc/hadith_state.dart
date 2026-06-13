part of 'hadith_bloc.dart';

enum HadithStatus { initial, loading, success, failure }

class HadithState extends Equatable {
  final HadithStatus status;
  final List<Hadith> hadiths;
  final String errorMessage;

  const HadithState({
    this.status = HadithStatus.initial,
    this.hadiths = const [],
    this.errorMessage = '',
  });

  HadithState copyWith({
    HadithStatus? status,
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
