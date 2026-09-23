import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/presentation/view_status.dart';
import '../../../../core/usecase/usecase.dart';
import '../../domain/entities/hadith.dart';
import '../../domain/usecases/get_all_hadiths.dart';

part 'hadith_event.dart';
part 'hadith_state.dart';

class HadithBloc extends Bloc<HadithEvent, HadithState> {
  final GetAllHadiths getAllHadiths;

  HadithBloc({required this.getAllHadiths}) : super(const HadithState()) {
    on<LoadHadithsEvent>(_onLoadHadiths);
  }

  Future<void> _onLoadHadiths(
    LoadHadithsEvent event,
    Emitter<HadithState> emit,
  ) async {
    emit(state.copyWith(status: ViewStatus.loading));
    final result = await getAllHadiths(const NoParams());
    result.fold(
      (failure) => emit(state.copyWith(
        status: ViewStatus.failure,
        errorMessage: failure.message,
      )),
      (hadiths) => emit(state.copyWith(
        status: ViewStatus.success,
        hadiths: hadiths,
      )),
    );
  }
}
