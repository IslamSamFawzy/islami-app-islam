import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/empty_message.dart';
import '../../../downloads/presentation/bloc/downloads_bloc.dart';
import '../../domain/entities/reciter.dart';
import '../bloc/radio_bloc.dart';
import '../pages/reciter_suras_view.dart';

/// The list of reciters for the active search query.
class RecitersList extends StatelessWidget {
  final RadioState state;

  const RecitersList({super.key, required this.state});

  @override
  Widget build(BuildContext context) {
    if (state.reciters.isEmpty) {
      return const EmptyMessage(
        message: 'No reciters available',
        color: AppColors.primaryColor,
        dense: true,
      );
    }
    final reciters = state.filteredReciters;
    if (reciters.isEmpty) return const EmptyMessage(message: 'No results');
    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
      itemCount: reciters.length,
      separatorBuilder: (context, index) => const SizedBox(height: 14),
      itemBuilder: (context, index) {
        final reciter = reciters[index];
        return ReciterTile(reciter: reciter);
      },
    );
  }
}

/// A reciter row on the Reciters tab. Tapping it opens the reciter's sura list
/// (where suras can be downloaded); a badge shows how many are already saved.
class ReciterTile extends StatelessWidget {
  final Reciter reciter;

  const ReciterTile({super.key, required this.reciter});

  @override
  Widget build(BuildContext context) {
    final reciterId = reciter.id.toString();
    return GestureDetector(
      onTap: () => Navigator.pushNamed(
        context,
        ReciterSurasView.routeName,
        arguments: reciter,
      ),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        decoration: BoxDecoration(
          color: AppColors.primaryColor,
          borderRadius: BorderRadius.circular(18),
        ),
        child: Row(
          children: [
            Expanded(
              child: Text(
                reciter.name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.titleLarge!.copyWith(
                  color: AppColors.titleTextColor,
                  fontSize: 16,
                ),
              ),
            ),
            BlocBuilder<DownloadsBloc, DownloadsState>(
              buildWhen: (a, b) =>
                  a.entriesForReciter(reciterId).length !=
                  b.entriesForReciter(reciterId).length,
              builder: (context, state) {
                final count = state.entriesForReciter(reciterId).length;
                if (count == 0) return const SizedBox.shrink();
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: Text(
                    '$count saved',
                    style: Theme.of(context).textTheme.bodyMedium!.copyWith(
                      color: AppColors.backgroundColor,
                    ),
                  ),
                );
              },
            ),
            const Icon(Icons.chevron_right, color: AppColors.backgroundColor),
          ],
        ),
      ),
    );
  }
}
