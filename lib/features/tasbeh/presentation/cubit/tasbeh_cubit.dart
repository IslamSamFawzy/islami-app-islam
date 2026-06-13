import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

part 'tasbeh_state.dart';

class TasbehCubit extends Cubit<TasbehState> {
  TasbehCubit() : super(const TasbehState());

  /// Increments the counter. After [TasbehState.target] presses the count
  /// resets and the dhikr advances to the next one in the cycle.
  void increment() {
    var nextCount = state.count + 1;
    var nextIndex = state.dhikrIndex;

    if (nextCount > TasbehState.target) {
      nextCount = 1;
      nextIndex = (state.dhikrIndex + 1) % TasbehState.dhikrList.length;
    }

    emit(state.copyWith(
      count: nextCount,
      totalCount: state.totalCount + 1,
      dhikrIndex: nextIndex,
    ));
  }

  void reset() => emit(const TasbehState());
}
