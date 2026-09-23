import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:islami/core/presentation/ui_notice.dart';
import 'package:islami/core/widgets/notice_listener.dart';

class _TestState extends Equatable {
  final UiNotice notice;
  final int tick;

  const _TestState({this.notice = const UiNotice.none(), this.tick = 0});

  @override
  List<Object?> get props => [notice, tick];
}

class _TestCubit extends Cubit<_TestState> {
  _TestCubit() : super(const _TestState());

  void say(String message) =>
      emit(_TestState(notice: state.notice.next(message), tick: state.tick));

  /// Any other state change, carrying the same notice.
  void bump() => emit(_TestState(notice: state.notice, tick: state.tick + 1));
}

void main() {
  final messengerKey = GlobalKey<ScaffoldMessengerState>();

  Future<_TestCubit> pump(WidgetTester tester) async {
    final cubit = _TestCubit();
    await tester.pumpWidget(
      MaterialApp(
        scaffoldMessengerKey: messengerKey,
        home: Scaffold(
          body: BlocProvider.value(
            value: cubit,
            child: NoticeListener<_TestCubit, _TestState>(
              noticeOf: (state) => state.notice,
              child: const SizedBox.shrink(),
            ),
          ),
        ),
      ),
    );
    return cubit;
  }

  testWidgets('shows a new notice as a SnackBar', (tester) async {
    final cubit = await pump(tester);
    expect(find.byType(SnackBar), findsNothing);

    cubit.say('Live radio needs an internet connection.');
    await tester.pump();

    expect(
      find.text('Live radio needs an internet connection.'),
      findsOneWidget,
    );
    messengerKey.currentState!.hideCurrentSnackBar();
    await tester.pumpAndSettle();
  });

  testWidgets('does not re-show it when other state changes', (tester) async {
    final cubit = await pump(tester);
    cubit.say('Offline');
    await tester.pump();
    // Dismiss it, the way tapping away or waiting would.
    messengerKey.currentState!.hideCurrentSnackBar();
    await tester.pumpAndSettle();
    expect(find.byType(SnackBar), findsNothing);

    cubit.bump();
    await tester.pump();

    expect(find.byType(SnackBar), findsNothing);
  });
}
