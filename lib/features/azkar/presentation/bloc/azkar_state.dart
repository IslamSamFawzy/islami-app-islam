part of 'azkar_bloc.dart';

enum AzkarStatus { initial, loading, success, failure }

class AzkarState extends Equatable {
  final AzkarStatus status;
  final AzkarCollection? collection;
  final String errorMessage;

  const AzkarState({
    this.status = AzkarStatus.initial,
    this.collection,
    this.errorMessage = '',
  });

  AzkarState copyWith({
    AzkarStatus? status,
    AzkarCollection? collection,
    String? errorMessage,
  }) {
    return AzkarState(
      status: status ?? this.status,
      collection: collection ?? this.collection,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }

  @override
  List<Object?> get props => [status, collection, errorMessage];
}
