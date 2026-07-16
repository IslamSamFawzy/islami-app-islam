import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/constants/sura_names.dart';
import '../../../../core/di/service_locator.dart';
import '../../../../core/gen/assets.gen.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../downloads/presentation/widgets/sura_download_control.dart';
import '../../domain/entities/reciter.dart';
import '../cubit/sura_playback_cubit.dart';

/// The sura list for a single reciter. Each row can be played (local file first,
/// otherwise streamed) and downloaded for offline listening. Reached from the
/// Reciters tab.
class ReciterSurasView extends StatelessWidget {
  static const String routeName = '/reciter-suras';

  const ReciterSurasView({super.key});

  @override
  Widget build(BuildContext context) {
    final reciter = ModalRoute.of(context)!.settings.arguments as Reciter;

    return BlocProvider(
      create: (_) => SuraPlaybackCubit(
        reciter: reciter,
        audioPlayerService: sl(),
        downloadsLocalDataSource: sl(),
        connectivityService: sl(),
      ),
      child: _ReciterSurasBody(reciter: reciter),
    );
  }
}

class _ReciterSurasBody extends StatelessWidget {
  final Reciter reciter;

  const _ReciterSurasBody({required this.reciter});

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
            reciter.name,
            style: Theme.of(context).textTheme.titleLarge!.copyWith(
                  color: AppColors.primaryColor,
                ),
          ),
        ),
        body: SafeArea(
          top: false,
          child: BlocListener<SuraPlaybackCubit, SuraPlaybackState>(
            listenWhen: (a, b) => a.noticeSeq != b.noticeSeq,
            listener: (context, state) {
              if (state.notice.isEmpty) return;
              ScaffoldMessenger.of(context)
                ..hideCurrentSnackBar()
                ..showSnackBar(SnackBar(content: Text(state.notice)));
            },
            child: ListView.separated(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
              itemCount: reciter.surahList.length,
              separatorBuilder: (_, _) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                final sura = reciter.surahList[index];
                return _SuraRow(reciter: reciter, sura: sura);
              },
            ),
          ),
        ),
      ),
    );
  }
}

class _SuraRow extends StatelessWidget {
  final Reciter reciter;
  final int sura;

  const _SuraRow({required this.reciter, required this.sura});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final info = SuraNames.byNumber(sura);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.primaryColor,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          BlocBuilder<SuraPlaybackCubit, SuraPlaybackState>(
            buildWhen: (a, b) =>
                a.isCurrent(sura) != b.isCurrent(sura) ||
                a.isPlaying != b.isPlaying,
            builder: (context, state) {
              final playing = state.isCurrent(sura) && state.isPlaying;
              return GestureDetector(
                onTap: () => context.read<SuraPlaybackCubit>().toggle(sura),
                child: Icon(
                  playing
                      ? Icons.pause_circle_filled
                      : Icons.play_circle_fill,
                  color: AppColors.backgroundColor,
                  size: 32,
                ),
              );
            },
          ),
          const SizedBox(width: 10),
          // Sura number.
          Text(
            '$sura',
            style: theme.textTheme.titleLarge!.copyWith(
              color: AppColors.titleTextColor.withValues(alpha: 0.7),
              fontSize: 16,
            ),
          ),
          const SizedBox(width: 12),
          // English name (falls back to "Sura N" if the number is unknown).
          Expanded(
            child: Text(
              info?.nameEn ?? 'Sura $sura',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.titleLarge!.copyWith(
                color: AppColors.titleTextColor,
                fontSize: 16,
              ),
            ),
          ),
          // Arabic name, RTL on the right (like the Quran tab's rows).
          if (info != null) ...[
            const SizedBox(width: 8),
            Text(
              info.nameAr,
              textDirection: TextDirection.rtl,
              style: theme.textTheme.titleLarge!.copyWith(
                color: AppColors.titleTextColor,
                fontSize: 16,
              ),
            ),
          ],
          SuraDownloadControl(
            reciterId: reciter.id.toString(),
            reciterName: reciter.name,
            suraId: sura.toString(),
            url: reciter.audioUrlFor(sura),
          ),
        ],
      ),
    );
  }
}
