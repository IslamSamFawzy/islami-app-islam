import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../presentation/ui_notice.dart';

/// Shows every one-shot [UiNotice] that [B]'s state carries, exactly once, as
/// a SnackBar.
///
/// Three screens each wrote this same BlocListener; they now say which field
/// holds the notice and leave the rest to this.
class NoticeListener<B extends StateStreamable<S>, S> extends StatelessWidget {
  /// Picks the notice out of the state.
  final UiNotice Function(S state) noticeOf;

  final Widget child;

  const NoticeListener({
    super.key,
    required this.noticeOf,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return BlocListener<B, S>(
      listenWhen: (previous, current) =>
          noticeOf(previous).id != noticeOf(current).id,
      listener: (context, state) {
        final notice = noticeOf(state);
        if (notice.isEmpty) return;
        ScaffoldMessenger.of(context)
          ..hideCurrentSnackBar()
          ..showSnackBar(SnackBar(content: Text(notice.message)));
      },
      child: child,
    );
  }
}
