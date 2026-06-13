import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/entities/azkar.dart';
import '../../domain/usecases/get_azkar.dart';

part 'azkar_event.dart';
part 'azkar_state.dart';

class AzkarBloc extends Bloc<AzkarEvent, AzkarState> {
  final GetAzkar getAzkar;

  AzkarBloc({required this.getAzkar}) : super(const AzkarState()) {
    on<LoadAzkarEvent>(_onLoadAzkar);
  }

  Future<void> _onLoadAzkar(
    LoadAzkarEvent event,
    Emitter<AzkarState> emit,
  ) async {
    emit(state.copyWith(status: AzkarStatus.loading));
    final result = await getAzkar(event.type);
    result.fold(
      (failure) => emit(state.copyWith(
        status: AzkarStatus.failure,
        errorMessage: failure.message,
      )),
      (collection) => emit(state.copyWith(
        status: AzkarStatus.success,
        collection: collection,
      )),
    );
  }
}
