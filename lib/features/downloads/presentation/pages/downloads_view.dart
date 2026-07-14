import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/gen/assets.gen.dart';
import '../../../../core/theme/app_colors.dart';
import '../../domain/entities/download_entry.dart';
import '../bloc/downloads_bloc.dart';

/// The downloads library: every saved sura grouped by reciter, with the total
/// size on disk and controls to delete a single sura or a whole reciter.
class DownloadsView extends StatelessWidget {
  static const String routeName = '/downloads';

  const DownloadsView({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        image: DecorationImage(
          image: Assets.images.radioBackground.provider(),
          fit: BoxFit.cover,
        ),
      ),
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          centerTitle: true,
          iconTheme: const IconThemeData(color: AppColors.primaryColor),
          title: Text(
            'Downloads',
            style: Theme.of(context).textTheme.titleLarge!.copyWith(
                  color: AppColors.primaryColor,
                ),
          ),
        ),
        body: SafeArea(
          top: false,
          child: BlocBuilder<DownloadsBloc, DownloadsState>(
            builder: (context, state) {
              if (state.entries.isEmpty) {
                return const _EmptyHint();
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
      style: Theme.of(context)
          .textTheme
          .bodyLarge!
          .copyWith(color: AppColors.textColor),
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
      ..sort((a, b) =>
          (int.tryParse(a.suraId) ?? 0).compareTo(int.tryParse(b.suraId) ?? 0));
    final name = entries.isEmpty ? 'Reciter $reciterId' : entries.first.reciterName;

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
                style: Theme.of(context)
                    .textTheme
                    .bodyMedium!
                    .copyWith(color: AppColors.textColor),
              ),
              IconButton(
                tooltip: 'Delete all',
                icon: const Icon(Icons.delete_sweep_rounded,
                    color: AppColors.primaryColor),
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
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: AppColors.backgroundColor,
        title: Text(
          'Delete downloads',
          style: Theme.of(context)
              .textTheme
              .titleLarge!
              .copyWith(color: AppColors.primaryColor),
        ),
        content: Text(
          'Remove all downloaded suras for '
          '${name.isEmpty ? 'this reciter' : name}?',
          style: Theme.of(context)
              .textTheme
              .bodyLarge!
              .copyWith(color: AppColors.textColor),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancel',
                style: TextStyle(color: AppColors.textColor)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Delete',
                style: TextStyle(color: AppColors.primaryColor)),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      bloc.add(DeleteReciterDownloadsEvent(reciterId));
    }
  }
}

class _SuraTile extends StatelessWidget {
  final DownloadEntry entry;

  const _SuraTile({required this.entry});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.primaryColor,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              'Sura ${entry.suraId}',
              style: Theme.of(context).textTheme.titleLarge!.copyWith(
                    color: AppColors.titleTextColor,
                    fontSize: 16,
                  ),
            ),
          ),
          Text(
            formatBytes(entry.bytes),
            style: Theme.of(context).textTheme.bodyMedium!.copyWith(
                  color: AppColors.backgroundColor,
                ),
          ),
          IconButton(
            tooltip: 'Delete',
            icon: const Icon(Icons.delete_outline_rounded,
                color: AppColors.backgroundColor),
            onPressed: () => context.read<DownloadsBloc>().add(
                  DeleteDownloadEvent(
                    reciterId: entry.reciterId,
                    suraId: entry.suraId,
                  ),
                ),
          ),
        ],
      ),
    );
  }
}

class _EmptyHint extends StatelessWidget {
  const _EmptyHint();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Text(
          'No downloads yet.\nDownload suras from a reciter to listen offline.',
          textAlign: TextAlign.center,
          style: Theme.of(context)
              .textTheme
              .bodyLarge!
              .copyWith(color: AppColors.primaryColor),
        ),
      ),
    );
  }
}

/// Formats a byte count as a compact human-readable size.
String formatBytes(int bytes) {
  if (bytes <= 0) return '0 B';
  const units = ['B', 'KB', 'MB', 'GB'];
  var size = bytes.toDouble();
  var unit = 0;
  while (size >= 1024 && unit < units.length - 1) {
    size /= 1024;
    unit++;
  }
  final decimals = (size < 10 && unit > 0) ? 1 : 0;
  return '${size.toStringAsFixed(decimals)} ${units[unit]}';
}
