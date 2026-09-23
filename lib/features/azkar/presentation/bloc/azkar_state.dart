part of 'azkar_bloc.dart';

class AzkarState extends Equatable {
  final ViewStatus status;
  final AzkarCollection? collection;
  final String errorMessage;

  const AzkarState({
    this.status = ViewStatus.initial,
    this.collection,
    this.errorMessage = '',
  });

  AzkarState copyWith({
    ViewStatus? status,
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
