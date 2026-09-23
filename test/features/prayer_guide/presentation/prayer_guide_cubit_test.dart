import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:islami/core/error/failures.dart';
import 'package:islami/features/prayer_guide/domain/entities/prayer_guide.dart';
import 'package:islami/features/prayer_guide/domain/entities/prayer_posture.dart';
import 'package:islami/features/prayer_guide/domain/repositories/prayer_guide_repository.dart';
import 'package:islami/features/prayer_guide/domain/usecases/get_prayer_guide.dart';
import 'package:islami/features/prayer_guide/presentation/cubit/prayer_guide_cubit.dart';

class _FakeRepository implements PrayerGuideRepository {
  final Either<Failure, PrayerGuide> result;

  _FakeRepository(this.result);

  @override
  Future<Either<Failure, PrayerGuide>> getPrayerGuide() async => result;
}

const _guide = PrayerGuide(
  title: 't',
  introHadith: HadithEvidence(text: 'h', source: 's'),
  introText: 'i',
  overviewPostures: [PrayerPosture.standing],
  rakaat: [],
  note: '',
  steps: [
    PrayerStep(
      title: 'a',
      description: 'd',
      recitation: '',
      postures: [PrayerPosture.standing],
      evidence: [],
    ),
    PrayerStep(
      title: 'b',
      description: 'd',
      recitation: '',
      postures: [PrayerPosture.ruku],
      evidence: [],
    ),
  ],
);

void main() {
  test('load emits success with the guide; overview + one page per step', () async {
    final cubit = PrayerGuideCubit(
      getPrayerGuide: GetPrayerGuide(_FakeRepository(const Right(_guide))),
    );
    await cubit.load();
    expect(cubit.state.status, PrayerGuideStatus.success);
    expect(cubit.state.pageCount, 3);
    expect(cubit.state.isFirstPage, isTrue);

    cubit.onPageChanged(2);
    expect(cubit.state.isLastPage, isTrue);
    await cubit.close();
  });

  test('load surfaces the failure message', () async {
    final cubit = PrayerGuideCubit(
      getPrayerGuide: GetPrayerGuide(
        _FakeRepository(const Left(LocalDataFailure('boom'))),
      ),
    );
    await cubit.load();
    expect(cubit.state.status, PrayerGuideStatus.failure);
    expect(cubit.state.errorMessage, 'boom');
    await cubit.close();
  });
}
