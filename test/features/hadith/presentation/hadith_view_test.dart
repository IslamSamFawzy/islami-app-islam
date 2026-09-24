import 'package:carousel_slider/carousel_slider.dart';
import 'package:dartz/dartz.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:islami/core/di/service_locator.dart';
import 'package:islami/core/error/failures.dart';
import 'package:islami/core/theme/theme_manager.dart';
import 'package:islami/features/hadith/domain/entities/hadith.dart';
import 'package:islami/features/hadith/domain/repositories/hadith_repository.dart';
import 'package:islami/features/hadith/domain/usecases/get_all_hadiths.dart';
import 'package:islami/features/hadith/presentation/bloc/hadith_bloc.dart';
import 'package:islami/features/hadith/presentation/pages/hadith_details_view.dart';
import 'package:islami/features/hadith/presentation/pages/hadith_view.dart';

class _FakeRepository implements HadithRepository {
  final List<Hadith> hadiths;

  _FakeRepository(this.hadiths);

  @override
  Future<Either<Failure, List<Hadith>>> getAllHadiths() async => Right(hadiths);
}

void main() {
  // Enough that only neighbours are ever on screen.
  final hadiths = [
    for (var i = 1; i <= 5; i++) Hadith(title: 'H$i', content: 'Body $i'),
  ];

  ({Hadith hadith, int number})? pushed;

  Future<void> pumpView(WidgetTester tester) async {
    pushed = null;
    sl.registerFactory(
      () => HadithBloc(getAllHadiths: GetAllHadiths(_FakeRepository(hadiths))),
    );
    await tester.pumpWidget(
      MaterialApp(
        theme: ThemeManager.darkTheme(),
        home: const HadithView(),
        onGenerateRoute: (settings) {
          if (settings.name == HadithDetailsView.routeName) {
            pushed = settings.arguments as ({Hadith hadith, int number});
          }
          return MaterialPageRoute<void>(
            builder: (_) => const SizedBox.shrink(),
          );
        },
      ),
    );
    await tester.pumpAndSettle();
  }

  Future<void> swipeToNext(WidgetTester tester) async {
    await tester.drag(find.byType(CarouselSlider), const Offset(-400, 0));
    await tester.pumpAndSettle();
  }

  tearDown(() => sl.reset());

  testWidgets('swiping past the last hadith comes back to the first',
      (tester) async {
    await pumpView(tester);
    final centre = tester.getCenter(find.byType(CarouselSlider)).dx;

    expect(find.text('H1'), findsOneWidget);

    // Four swipes reach the last hadith...
    for (var i = 0; i < 4; i++) {
      await swipeToNext(tester);
    }
    expect((tester.getCenter(find.text('H5')).dx - centre).abs(), lessThan(4));

    // ...and the fifth wraps round to the first.
    await swipeToNext(tester);
    expect((tester.getCenter(find.text('H1')).dx - centre).abs(), lessThan(4));
  });

  testWidgets('a wrapped card still opens as its own number', (tester) async {
    await pumpView(tester);
    for (var i = 0; i < 5; i++) {
      await swipeToNext(tester);
    }

    await tester.tap(find.text('H1'));
    await tester.pumpAndSettle();

    // "Hadith 1" after a lap, not 6 — the number comes from the list index.
    expect(pushed?.number, 1);
    expect(pushed?.hadith.title, 'H1');
  });

  testWidgets('swiping back from the first reaches the last', (tester) async {
    await pumpView(tester);
    final centre = tester.getCenter(find.byType(CarouselSlider)).dx;

    await tester.drag(find.byType(CarouselSlider), const Offset(400, 0));
    await tester.pumpAndSettle();

    expect((tester.getCenter(find.text('H5')).dx - centre).abs(), lessThan(4));
  });
}
