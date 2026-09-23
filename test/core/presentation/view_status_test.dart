import 'package:flutter_test/flutter_test.dart';
import 'package:islami/core/presentation/view_status.dart';

void main() {
  test('each value reports only its own flag', () {
    expect(ViewStatus.initial.isInitial, isTrue);
    expect(ViewStatus.loading.isLoading, isTrue);
    expect(ViewStatus.success.isSuccess, isTrue);
    expect(ViewStatus.failure.isFailure, isTrue);

    expect(ViewStatus.success.isLoading, isFalse);
    expect(ViewStatus.success.isFailure, isFalse);
  });

  test('isBusy covers initial and loading only', () {
    expect(ViewStatus.initial.isBusy, isTrue);
    expect(ViewStatus.loading.isBusy, isTrue);
    expect(ViewStatus.success.isBusy, isFalse);
    expect(ViewStatus.failure.isBusy, isFalse);
  });
}
