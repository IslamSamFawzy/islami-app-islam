import 'package:carousel_slider/carousel_slider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/di/service_locator.dart';
import '../../../../core/gen/assets.gen.dart';
import '../../../../core/theme/app_colors.dart';
import '../bloc/hadith_bloc.dart';
import 'hadith_details_view.dart';

class HadithView extends StatelessWidget {
  const HadithView({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => sl<HadithBloc>()..add(const LoadHadithsEvent()),
      child: const _HadithViewBody(),
    );
  }
}

class _HadithViewBody extends StatelessWidget {
  const _HadithViewBody();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      decoration: BoxDecoration(
        image: DecorationImage(
          image: Assets.images.hadethBackground.provider(),
          fit: BoxFit.cover,
        ),
      ),
      child: SafeArea(
        child: Column(
          spacing: 20,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Align(
              alignment: Alignment.center,
              child: Assets.images.imgHeader.image(
                width: MediaQuery.of(context).size.width * 0.7,
              ),
            ),
            Expanded(
              child: BlocBuilder<HadithBloc, HadithState>(
                builder: (context, state) {
                  if (state.status == HadithStatus.loading ||
                      state.status == HadithStatus.initial) {
                    return const Center(
                      child: CircularProgressIndicator(
                        color: AppColors.primaryColor,
                      ),
                    );
                  }

                  if (state.status == HadithStatus.failure) {
                    return Center(
                      child: Text(
                        state.errorMessage,
                        style: theme.textTheme.bodyLarge!
                            .copyWith(color: AppColors.primaryColor),
                      ),
                    );
                  }

                  return CarouselSlider.builder(
                    itemCount: state.hadiths.length,
                    options: CarouselOptions(
                      height: double.infinity,
                      viewportFraction: 0.8,
                      enlargeCenterPage: true,
                      enableInfiniteScroll: false,
                    ),
                    itemBuilder: (context, index, realIndex) {
                      final hadith = state.hadiths[index];
                      return GestureDetector(
                        onTap: () => Navigator.pushNamed(
                          context,
                          HadithDetailsView.routeName,
                          arguments: (hadith: hadith, number: index + 1),
                        ),
                        child: Container(
                          margin: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 20,
                          ),
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: AppColors.primaryColor,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Stack(
                            children: [
                              // Dark filigree corner ornaments on the gold
                              // parchment (spec §2.5): top-left as-is, top-right
                              // mirrored.
                              Positioned(
                                left: 0,
                                top: 0,
                                child: Assets.images.imgHadithCorner.image(
                                  width: 70,
                                  height: 70,
                                ),
                              ),
                              Positioned(
                                right: 0,
                                top: 0,
                                child: Transform.flip(
                                  flipX: true,
                                  child: Assets.images.imgHadithCorner.image(
                                    width: 70,
                                    height: 70,
                                  ),
                                ),
                              ),
                              Positioned.fill(
                                child: Column(
                                  children: [
                                    const SizedBox(height: 8),
                                    Text(
                                      hadith.title,
                                      textAlign: TextAlign.center,
                                      style: theme.textTheme.titleLarge,
                                    ),
                                    const Divider(
                                      color: AppColors.backgroundColor,
                                    ),
                                    Expanded(
                                      child: SingleChildScrollView(
                                        child: Text(
                                          hadith.content,
                                          textAlign: TextAlign.center,
                                          textDirection: TextDirection.rtl,
                                          style: theme.textTheme.bodyLarge!
                                              .copyWith(height: 1.8),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
