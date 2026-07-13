part of 'intro_cubit.dart';

enum IntroStatus { browsing, done }

class IntroState extends Equatable {
  final int page;
  final IntroStatus status;

  const IntroState({this.page = 0, this.status = IntroStatus.browsing});

  IntroState copyWith({int? page, IntroStatus? status}) => IntroState(
    page: page ?? this.page,
    status: status ?? this.status,
  );

  @override
  List<Object?> get props => [page, status];
}
