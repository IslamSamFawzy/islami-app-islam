import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/theme/app_colors.dart';
import '../bloc/quran_bloc.dart';
import 'sura_item.dart';

class SuraListView extends StatelessWidget {
  const SuraListView({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        spacing: 10,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Suras List',
            style: theme.textTheme.titleLarge!.copyWith(
              color: AppColors.textColor,
            ),
          ),
          BlocBuilder<QuranBloc, QuranState>(
            builder: (context, state) {
              if (state.status == QuranStatus.loading ||
                  state.status == QuranStatus.initial) {
                return const Padding(
                  padding: EdgeInsets.all(20),
                  child: Center(
                    child: CircularProgressIndicator(
                      color: AppColors.primaryColor,
                    ),
                  ),
                );
              }

              if (state.status == QuranStatus.failure) {
                return Padding(
                  padding: const EdgeInsets.all(20),
                  child: Center(
                    child: Text(
                      state.errorMessage,
                      style: theme.textTheme.bodyMedium!
                          .copyWith(color: AppColors.textColor),
                    ),
                  ),
                );
              }

              if (state.filteredSuras.isEmpty) {
                return Padding(
                  padding: const EdgeInsets.all(20),
                  child: Center(
                    child: Text(
                      'No suras found',
                      style: theme.textTheme.bodyMedium!
                          .copyWith(color: AppColors.textColor),
                    ),
                  ),
                );
              }

              return ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemBuilder: (context, index) {
                  return SuraItem(sura: state.filteredSuras[index]);
                },
                separatorBuilder: (context, index) {
                  // Thin gold divider under each row (spec §2.3).
                  return const Divider(
                    color: AppColors.primaryColor,
                    endIndent: 40,
                    indent: 40,
                  );
                },
                itemCount: state.filteredSuras.length,
              );
            },
          ),
        ],
      ),
    );
  }
}
