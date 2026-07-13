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

                  return ListView.separated(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 20,
                    ),
                    itemCount: state.verses.length,
                    separatorBuilder: (_, _) => const SizedBox(height: 12),
                    itemBuilder: (context, index) {
                      return _AyahCard(
                        text:
                            "${state.verses[index]} ﴿${_toArabicNumber(index + 1)}﴾",
                        selected: state.selectedIndex == index,
                        onTap: () => context
                            .read<QuranDetailsBloc>()
                            .add(SelectVerseEvent(index)),
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

/// A single ayah rendered as a bordered card (spec §2.4): 1px gold border,
/// radius 8, transparent fill, gold RTL text with the verse number after it.
/// When [selected] it flips to a solid-gold fill with dark text.
class _AyahCard extends StatelessWidget {
  final String text;
  final bool selected;
  final VoidCallback onTap;

  const _AyahCard({
    required this.text,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: selected ? AppColors.primaryColor : Colors.transparent,
          border: Border.all(color: AppColors.primaryColor, width: 1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(
          text,
          textDirection: TextDirection.rtl,
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.titleLarge!.copyWith(
            color: selected ? AppColors.titleTextColor : AppColors.primaryColor,
            height: 1.8,
          ),
        ),
      ),
    );
  }
}
