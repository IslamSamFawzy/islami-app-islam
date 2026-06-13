import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/di/service_locator.dart';
import '../../../../core/gen/assets.gen.dart';
import '../../../../core/theme/app_colors.dart';
import '../../domain/entities/sura.dart';
import '../bloc/details/quran_details_bloc.dart';

class QuranDetailsView extends StatelessWidget {
  static const String routeName = '/quran-details';

  const QuranDetailsView({super.key});

  @override
  Widget build(BuildContext context) {
    final sura = ModalRoute.of(context)!.settings.arguments as Sura;
    final theme = Theme.of(context);

    return BlocProvider(
      create: (_) =>
          sl<QuranDetailsBloc>()..add(LoadVersesEvent(sura.id)),
      child: Scaffold(
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          centerTitle: true,
          iconTheme: const IconThemeData(color: AppColors.primaryColor),
          title: Text(sura.nameEn),
          titleTextStyle: theme.textTheme.titleLarge!.copyWith(
            color: AppColors.primaryColor,
            fontWeight: FontWeight.bold,
          ),
        ),
        body: Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Assets.images.imgLeftCorner.image(width: 90, height: 90),
                  Text(
                    sura.nameAr,
                    style: theme.textTheme.headlineLarge!.copyWith(
                      color: AppColors.primaryColor,
                    ),
                  ),
                  Assets.images.imgRightCorner.image(width: 90, height: 90),
                ],
              ),
            ),
            Expanded(
              child: BlocBuilder<QuranDetailsBloc, QuranDetailsState>(
                builder: (context, state) {
                  if (state.status == DetailsStatus.loading ||
                      state.status == DetailsStatus.initial) {
                    return const Center(
                      child: CircularProgressIndicator(
                        color: AppColors.primaryColor,
                      ),
                    );
                  }

                  if (state.status == DetailsStatus.failure) {
                    return Center(
                      child: Text(
                        state.errorMessage,
                        textAlign: TextAlign.center,
                        style: theme.textTheme.bodyLarge!.copyWith(
                          color: AppColors.primaryColor,
                        ),
                      ),
                    );
                  }

                  return ListView.builder(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 20,
                    ),
                    itemCount: state.verses.length,
                    itemBuilder: (context, index) {
                      return Text(
                        "${state.verses[index]} ﴿${_toArabicNumber(index + 1)}﴾",
                        textDirection: TextDirection.rtl,
                        textAlign: TextAlign.center,
                        style: theme.textTheme.titleLarge!.copyWith(
                          color: AppColors.primaryColor,
                          height: 1.8,
                        ),
                      );
                    },
                  );
                },
              ),
            ),
            Assets.images.imgBottomDecoration.image(),
          ],
        ),
      ),
    );
  }

  String _toArabicNumber(int number) {
    const arabicNumbers = ['٠', '١', '٢', '٣', '٤', '٥', '٦', '٧', '٨', '٩'];
    return number
        .toString()
        .split('')
        .map((e) => arabicNumbers[int.parse(e)])
        .join();
  }
}
