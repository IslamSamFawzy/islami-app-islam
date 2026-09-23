import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/empty_message.dart';
import '../../../../core/widgets/error_view.dart';
import '../../../../core/widgets/loading_view.dart';
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
              if (state.status.isBusy) {
                return const LoadingView(padding: EdgeInsets.all(20));
              }

              if (state.status.isFailure) {
                return ErrorView(
                  message: state.errorMessage,
                  padding: const EdgeInsets.all(20),
                  color: AppColors.textColor,
                  dense: true,
                );
              }

              if (state.filteredSuras.isEmpty) {
                return const EmptyMessage(
                  message: 'No suras found',
                  padding: EdgeInsets.all(20),
                  dense: true,
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
