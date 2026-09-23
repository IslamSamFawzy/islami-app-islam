import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/constants/sura_names.dart';
import '../../../../core/di/service_locator.dart';
import '../../../../core/gen/assets.gen.dart';
import '../../../../core/utils/arabic_search.dart';
import '../../../../core/widgets/app_background.dart';
import '../../../../core/widgets/empty_message.dart';
import '../../../../core/widgets/notice_listener.dart';
import '../../../../core/widgets/sura_audio_tile.dart';
import '../../../../core/widgets/search_field.dart';
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
        findDownloadedFile: sl(),
        connectivityService: sl(),
      ),
      child: _ReciterSurasBody(reciter: reciter),
    );
  }
}

class _ReciterSurasBody extends StatefulWidget {
  final Reciter reciter;

  const _ReciterSurasBody({required this.reciter});

  @override
  State<_ReciterSurasBody> createState() => _ReciterSurasBodyState();
}

class _ReciterSurasBodyState extends State<_ReciterSurasBody> {
  String _query = '';

  /// Suras matching the query by number, English or Arabic name.
  List<int> get _visibleSuras {
    final reciter = widget.reciter;
    if (_query.trim().isEmpty) return reciter.surahList;
    return reciter.surahList.where((n) {
      final info = SuraNames.byNumber(n);
      return ArabicSearch.suraMatches(
        query: _query,
        number: n,
        nameEn: info?.nameEn ?? 'Sura $n',
        nameAr: info?.nameAr ?? '',
      );
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final reciter = widget.reciter;
    final suras = _visibleSuras;

    return AppBackground(
      image: Assets.images.radioBackground,
      title: reciter.name,
      child: NoticeListener<SuraPlaybackCubit, SuraPlaybackState>(
        noticeOf: (state) => state.notice,
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
              child: SearchField(
                hintText: 'Search suras',
                onChanged: (value) => setState(() => _query = value),
              ),
            ),
            Expanded(
              child: suras.isEmpty
                  ? const EmptyMessage(message: 'No results')
                  : ListView.separated(
                      padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
                      itemCount: suras.length,
                      separatorBuilder: (_, _) =>
                          const SizedBox(height: 12),
                      itemBuilder: (context, index) {
                        return _SuraRow(
                          reciter: reciter,
                          sura: suras[index],
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

class _SuraRow extends StatelessWidget {
  final Reciter reciter;
  final int sura;

  const _SuraRow({required this.reciter, required this.sura});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<SuraPlaybackCubit, SuraPlaybackState>(
      buildWhen: (a, b) =>
          a.isCurrent(sura) != b.isCurrent(sura) ||
          a.isPlaying != b.isPlaying,
      builder: (context, state) {
        return SuraAudioTile(
          suraId: '$sura',
          isPlaying: state.isCurrent(sura) && state.isPlaying,
          onPlayPause: () => context.read<SuraPlaybackCubit>().toggle(sura),
          trailing: SuraDownloadControl(
            reciterId: reciter.id.toString(),
            reciterName: reciter.name,
            suraId: sura.toString(),
            url: reciter.audioUrlFor(sura),
          ),
        );
      },
    );
  }
}
