part of 'tasbeh_cubit.dart';

class TasbehState extends Equatable {
  /// Count within the current dhikr cycle (1..[target]).
  final int count;

  /// Total presses since reset (monotonic — drives the bead rotation).
  final int totalCount;

  /// Index into [dhikrList] of the current dhikr.
  final int dhikrIndex;

  const TasbehState({
    this.count = 0,
    this.totalCount = 0,
    this.dhikrIndex = 0,
  });

  /// Presses per dhikr before advancing to the next.
  static const int target = 30;

  /// The dhikr cycle, in order.
  static const List<String> dhikrList = [
    'سبحان الله',
    'الحمد لله',
    'الله أكبر',
  ];

  String get currentDhikr => dhikrList[dhikrIndex];

  TasbehState copyWith({
    int? count,
    int? totalCount,
    int? dhikrIndex,
  }) {
    return TasbehState(
      count: count ?? this.count,
      totalCount: totalCount ?? this.totalCount,
      dhikrIndex: dhikrIndex ?? this.dhikrIndex,
    );
  }

  @override
  List<Object?> get props => [count, totalCount, dhikrIndex];
}
