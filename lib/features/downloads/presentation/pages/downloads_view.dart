import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/di/service_locator.dart';
import '../../../../core/gen/assets.gen.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/notice_listener.dart';
import '../../../../core/widgets/sura_audio_tile.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../core/widgets/app_background.dart';
import '../../../../core/widgets/empty_message.dart';
import '../../domain/entities/download_entry.dart';
import '../bloc/downloads_bloc.dart';
import '../cubit/downloads_playback_cubit.dart';

/// The downloads library: every saved sura grouped by reciter, with the total
/// size on disk and controls to delete a single sura or a whole reciter.
class DownloadsView extends StatelessWidget {
  static const String routeName = '/downloads';

  const DownloadsView({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => DownloadsPlaybackCubit(
        audioPlayerService: sl(),
        findDownloadedFile: sl(),
        downloadsBloc: context.read<DownloadsBloc>(),
      ),
      child: AppBackground(
        image: Assets.images.radioBackground,
        title: 'Downloads',
        child: NoticeListener<DownloadsPlaybackCubit, DownloadsPlaybackState>(
          noticeOf: (state) => state.notice,
          child: BlocBuilder<DownloadsBloc, DownloadsState>(
            builder: (context, state) {
              if (state.entries.isEmpty) {
                return const EmptyMessage(
                  message: 'No downloads yet.\nDownload suras from a '
                      'reciter to listen offline.',
                  padding: EdgeInsets.all(24),
                  color: AppColors.primaryColor,
                );
              }
              final reciterIds = state.reciterIds;
              return ListView(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                children: [
                  _TotalSize(bytes: state.totalBytes),
                  const SizedBox(height: 16),
                  for (final reciterId in reciterIds)
                    _ReciterGroup(state: state, reciterId: reciterId),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}

class _TotalSize extends StatelessWidget {
  final int bytes;

  const _TotalSize({required this.bytes});

  @override
  Widget build(BuildContext context) {
    return Text(
      'Total on device: ${formatBytes(bytes)}',
      textAlign: TextAlign.center,
      style: Theme.of(
        context,
      ).textTheme.bodyLarge!.copyWith(color: AppColors.textColor),
    );
  }
}

class _ReciterGroup extends StatelessWidget {
  final DownloadsState state;
  final String reciterId;

  const _ReciterGroup({required this.state, required this.reciterId});

  @override
  Widget build(BuildContext context) {
    final entries = state.entriesForReciter(reciterId)
      ..sort(
        (a, b) => (int.tryParse(a.suraId) ?? 0).compareTo(
          int.tryParse(b.suraId) ?? 0,
        ),
      );
    final name = entries.isEmpty
        ? 'Reciter $reciterId'
        : entries.first.reciterName;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.only(top: 8, bottom: 8),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  name.isEmpty ? 'Reciter $reciterId' : name,
                  style: Theme.of(context).textTheme.titleLarge!.copyWith(
                    color: AppColors.primaryColor,
                    fontSize: 16,
                  ),
                ),
              ),
              Text(
                formatBytes(state.bytesForReciter(reciterId)),
                style: Theme.of(
                  context,
                ).textTheme.bodyMedium!.copyWith(color: AppColors.textColor),
              ),
              IconButton(
                tooltip: 'Delete all',
                icon: const Icon(
                  Icons.delete_sweep_rounded,
                  color: AppColors.primaryColor,
                ),
                onPressed: () => _confirmDeleteReciter(context, name),
              ),
            ],
          ),
        ),
        for (final entry in entries) _SuraTile(entry: entry),
        const SizedBox(height: 8),
      ],
    );
  }

  Future<void> _confirmDeleteReciter(BuildContext context, String name) async {
    final bloc = context.read<DownloadsBloc>();
    final playback = context.read<DownloadsPlaybackCubit>();
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: AppColors.backgroundColor,
        title: Text(
          'Delete downloads',
          style: Theme.of(
            context,
          ).textTheme.titleLarge!.copyWith(color: AppColors.primaryColor),
        ),
        content: Text(
          'Remove all downloaded suras for '
          '${name.isEmpty ? 'this reciter' : name}?',
          style: Theme.of(
            context,
          ).textTheme.bodyLarge!.copyWith(color: AppColors.textColor),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text(
              'Cancel',
              style: TextStyle(color: AppColors.textColor),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text(
              'Delete',
              style: TextStyle(color: AppColors.primaryColor),
            ),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      // Stop first if the playing sura belongs to this reciter.
      await playback.stopIfReciter(reciterId);
      bloc.add(DeleteReciterDownloadsEvent(reciterId));
    }
  }
}

class _SuraTile extends StatelessWidget {
  final DownloadEntry entry;

  const _SuraTile({required this.entry});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return BlocBuilder<DownloadsPlaybackCubit, DownloadsPlaybackState>(
      buildWhen: (a, b) =>
          a.isCurrent(entry) != b.isCurrent(entry) ||
          a.isPlaying != b.isPlaying,
      builder: (context, playback) {
        final isCurrent = playback.isCurrent(entry);

        return Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: SuraAudioTile(
            suraId: entry.suraId,
            isPlaying: isCurrent && playback.isPlaying,
            // The currently playing row stands out with a dark border.
            highlighted: isCurrent,
            onPlayPause: () =>
                context.read<DownloadsPlaybackCubit>().toggle(entry),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const SizedBox(width: 8),
                Text(
                  formatBytes(entry.bytes),
                  style: theme.textTheme.bodyMedium!.copyWith(
                    color: AppColors.backgroundColor,
                  ),
                ),
                IconButton(
                  tooltip: 'Delete',
                  icon: const Icon(
                    Icons.delete_outline_rounded,
                    color: AppColors.backgroundColor,
                  ),
                  onPressed: () async {
                    final downloads = context.read<DownloadsBloc>();
                    final playbackCubit = context
                        .read<DownloadsPlaybackCubit>();
                    // Stop first so the player never holds a deleted file.
                    await playbackCubit.stopIfCurrent(entry);
                    downloads.add(
                      DeleteDownloadEvent(
                        reciterId: entry.reciterId,
                        suraId: entry.suraId,
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
