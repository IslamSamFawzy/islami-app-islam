import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/gen/assets.gen.dart';
import '../../../../core/theme/app_colors.dart';
import '../bloc/quran_bloc.dart';
import '../pages/quran_details_view.dart';

class MostRecentlyWidget extends StatelessWidget {
  const MostRecentlyWidget({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return BlocBuilder<QuranBloc, QuranState>(
      builder: (context, state) {
        // Hide the section entirely while the user is searching.
        if (state.query.isNotEmpty) {
          return const SizedBox.shrink();
        }

        final recent = state.recentSuras;

        return Column(
          spacing: 10,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Text(
                'Most Recently',
                style: theme.textTheme.titleLarge!.copyWith(
                  color: AppColors.textColor,
                ),
              ),
            ),
            if (recent.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Text(
                  'No recently read suras yet',
                  style: theme.textTheme.bodyMedium!.copyWith(
                    color: AppColors.textColor,
                  ),
                ),
              )
            else
              SizedBox(
                height: 150,
                child: ListView.separated(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  scrollDirection: Axis.horizontal,
                  itemBuilder: (context, index) {
                    final sura = recent[index];
                    return GestureDetector(
                      onTap: () {
                        context
                            .read<QuranBloc>()
                            .add(MarkSuraAsReadEvent(sura));
                        Navigator.pushNamed(
                          context,
                          QuranDetailsView.routeName,
                          arguments: sura,
                        );
                      },
                      child: Container(
                        height: 145,
                        padding: const EdgeInsets.all(12),
                        width: MediaQuery.of(context).size.width * 0.7,
                        decoration: BoxDecoration(
                          color: AppColors.primaryColor,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                                children: [
                                  Text(
                                    sura.nameEn,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: theme.textTheme.headlineSmall,
                                  ),
                                  Text(
                                    sura.nameAr,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: theme.textTheme.headlineSmall,
                                  ),
                                  Text(
                                    '${sura.ayaCount} Verses',
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: theme.textTheme.bodyMedium,
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 8),
                            Assets.images.imgMostRecent.image(
                              width: 90,
                              fit: BoxFit.contain,
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                  separatorBuilder: (context, index) {
                    return const SizedBox(width: 10);
                  },
                  itemCount: recent.length,
                ),
              ),
          ],
        );
      },
    );
  }
}
