import 'package:flutter_test/flutter_test.dart';
import 'package:islami/core/presentation/ui_notice.dart';

void main() {
  test('starts empty', () {
    const notice = UiNotice.none();

    expect(notice.isEmpty, isTrue);
    expect(notice.message, isEmpty);
    expect(notice.id, 0);
  });

  test('next carries the message and a fresh id', () {
    final first = const UiNotice.none().next('Offline');

    expect(first.message, 'Offline');
    expect(first.id, 1);
    expect(first.isEmpty, isFalse);
  });

  test('the same message twice is still two notices', () {
    final first = const UiNotice.none().next('Offline');
    final second = first.next('Offline');

    expect(second.message, first.message);
    expect(second.id, 2);
    expect(second, isNot(first));
  });
}
