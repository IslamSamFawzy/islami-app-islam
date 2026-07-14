import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/theme/app_colors.dart';
import '../bloc/downloads_bloc.dart';

/// The trailing control on a sura row: a download button that becomes a
/// progress ring while downloading and a "downloaded" tick (tap to delete)
/// once complete. Reads the app-wide [DownloadsBloc] from context.
class SuraDownloadControl extends StatelessWidget {
  final String reciterId;
  final String reciterName;
  final String suraId;
  final String url;

  const SuraDownloadControl({
    super.key,
    required this.reciterId,
    required this.reciterName,
    required this.suraId,
    required this.url,
  });

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<DownloadsBloc, DownloadsState>(
      buildWhen: (a, b) =>
          a.isDownloaded(reciterId, suraId) !=
              b.isDownloaded(reciterId, suraId) ||
          a.isDownloading(reciterId, suraId) !=
              b.isDownloading(reciterId, suraId) ||
          a.isQueued(reciterId, suraId) != b.isQueued(reciterId, suraId) ||
          a.progressFor(reciterId, suraId) != b.progressFor(reciterId, suraId),
      builder: (context, state) {
        final bloc = context.read<DownloadsBloc>();

        if (state.isDownloaded(reciterId, suraId)) {
          return IconButton(
            tooltip: 'Delete download',
            icon: const Icon(Icons.download_done_rounded,
                color: AppColors.backgroundColor),
            onPressed: () => bloc.add(
              DeleteDownloadEvent(reciterId: reciterId, suraId: suraId),
            ),
          );
        }

        if (state.isDownloading(reciterId, suraId)) {
          final progress = state.progressFor(reciterId, suraId);
          return GestureDetector(
            onTap: () => bloc.add(
              CancelDownloadEvent(reciterId: reciterId, suraId: suraId),
            ),
            child: SizedBox(
              width: 40,
              height: 40,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  CircularProgressIndicator(
                    value: progress == 0 ? null : progress,
                    strokeWidth: 2.5,
                    color: AppColors.backgroundColor,
                    backgroundColor:
                        AppColors.backgroundColor.withValues(alpha: 0.2),
                  ),
                  const Icon(Icons.close,
                      size: 16, color: AppColors.backgroundColor),
                ],
              ),
            ),
          );
        }

        if (state.isQueued(reciterId, suraId)) {
          return IconButton(
            tooltip: 'Cancel',
            icon: const Icon(Icons.hourglass_top_rounded,
                color: AppColors.backgroundColor),
            onPressed: () => bloc.add(
              CancelDownloadEvent(reciterId: reciterId, suraId: suraId),
            ),
          );
        }

        return IconButton(
          tooltip: 'Download',
          icon: const Icon(Icons.download_rounded,
              color: AppColors.backgroundColor),
          onPressed: () => bloc.add(
            EnqueueDownloadEvent(
              reciterId: reciterId,
              reciterName: reciterName,
              suraId: suraId,
              url: url,
            ),
          ),
        );
      },
    );
  }
}
