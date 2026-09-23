import 'package:equatable/equatable.dart';

/// A message meant to be shown once — a SnackBar, not something that stays on
/// screen.
///
/// [id] changes with every new notice, so a listener can tell "here is another
/// one" from "the same state rebuilt", even when the text is identical.
class UiNotice extends Equatable {
  final String message;
  final int id;

  /// Nothing to show — every state starts here.
  const UiNotice.none() : message = '', id = 0;

  const UiNotice._(this.message, this.id);

  /// The notice that follows this one.
  UiNotice next(String message) => UiNotice._(message, id + 1);

  bool get isEmpty => message.isEmpty;

  @override
  List<Object?> get props => [message, id];
}
