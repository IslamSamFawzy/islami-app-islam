import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/usecase/usecase.dart';
import '../../domain/entities/prayer_guide.dart';
import '../../domain/usecases/get_prayer_guide.dart';

part 'prayer_guide_state.dart';

class PrayerGuideCubit extends Cubit<PrayerGuideState> {
  final GetPrayerGuide getPrayerGuide;

  PrayerGuideCubit({required this.getPrayerGuide})
    : super(const PrayerGuideState());

  Future<void> load() async {
    emit(state.copyWith(status: PrayerGuideStatus.loading));
    final result = await getPrayerGuide(const NoParams());
    result.fold(
      (failure) => emit(
        state.copyWith(
          status: PrayerGuideStatus.failure,
          errorMessage: failure.message,
        ),
      ),
      (guide) => emit(
        state.copyWith(
          status: PrayerGuideStatus.success,
          guide: guide,
          pageIndex: 0,
        ),
      ),
    );
  }

  /// Kept in sync with the PageView so the indicator and arrows react.
  void onPageChanged(int index) => emit(state.copyWith(pageIndex: index));
}
