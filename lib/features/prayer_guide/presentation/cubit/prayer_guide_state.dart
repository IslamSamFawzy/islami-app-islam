part of 'prayer_guide_cubit.dart';

class PrayerGuideState extends Equatable {
  final ViewStatus status;
  final PrayerGuide? guide;

  /// 0 = the overview page; 1..n = the steps.
  final int pageIndex;
  final String errorMessage;

  const PrayerGuideState({
    this.status = ViewStatus.initial,
    this.guide,
    this.pageIndex = 0,
    this.errorMessage = '',
  });

  /// The overview page plus one page per step.
  int get pageCount => guide == null ? 0 : guide!.steps.length + 1;

  bool get isFirstPage => pageIndex == 0;

  bool get isLastPage => pageIndex >= pageCount - 1;

  PrayerGuideState copyWith({
    ViewStatus? status,
    PrayerGuide? guide,
    int? pageIndex,
    String? errorMessage,
  }) {
    return PrayerGuideState(
      status: status ?? this.status,
      guide: guide ?? this.guide,
      pageIndex: pageIndex ?? this.pageIndex,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }

  @override
  List<Object?> get props => [status, guide, pageIndex, errorMessage];
}
