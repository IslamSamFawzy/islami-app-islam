import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/di/service_locator.dart';
import '../../../../core/gen/assets.gen.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/offline_banner.dart';
import '../../../downloads/presentation/bloc/downloads_bloc.dart';
import '../../../downloads/presentation/pages/downloads_view.dart';
import '../../domain/entities/reciter.dart';
import '../bloc/radio_bloc.dart';
import '../widgets/station_tile.dart';
import 'reciter_suras_view.dart';

class RadioView extends StatelessWidget {
  const RadioView({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => sl<RadioBloc>()..add(const LoadRadioDataEvent()),
      child: const _RadioViewBody(),
    );
  }
}

class _RadioViewBody extends StatelessWidget {
  const _RadioViewBody();

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        image: DecorationImage(
          image: Assets.images.radioBackground.provider(),
          fit: BoxFit.cover,
        ),
      ),
      child: SafeArea(
        child: BlocListener<RadioBloc, RadioState>(
          listenWhen: (a, b) => a.noticeSeq != b.noticeSeq,
          listener: (context, state) {
            if (state.notice.isEmpty) return;
            ScaffoldMessenger.of(context)
              ..hideCurrentSnackBar()
              ..showSnackBar(SnackBar(content: Text(state.notice)));
          },
          child: Column(
            children: [
              Stack(
                children: [
                  Center(
                    child: Assets.images.imgHeader.image(
                      width: MediaQuery.of(context).size.width * 0.55,
                    ),
                  ),
                  Positioned.fill(
                    child: Align(
                      alignment: Alignment.centerRight,
                      child: IconButton(
                        tooltip: 'Downloads',
                        icon: const Icon(
                          Icons.download_for_offline_outlined,
                          color: AppColors.primaryColor,
                        ),
                        onPressed: () => Navigator.pushNamed(
                          context,
                          DownloadsView.routeName,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              BlocBuilder<RadioBloc, RadioState>(
                buildWhen: (a, b) => a.showOfflineBanner != b.showOfflineBanner,
                builder: (context, state) => state.showOfflineBanner
                    ? const OfflineBanner()
                    : const SizedBox.shrink(),
              ),
              const SizedBox(height: 10),
              const _Tabs(),
              const SizedBox(height: 12),
              Expanded(
                child: BlocBuilder<RadioBloc, RadioState>(
                  builder: (context, state) {
                    if (state.status == RadioStatus.loading ||
                        state.status == RadioStatus.initial) {
                      return const Center(
                        child: CircularProgressIndicator(
                          color: AppColors.primaryColor,
                        ),
                      );
                    }
                    if (state.status == RadioStatus.failure) {
                      return Center(
                        child: Padding(
                          padding: const EdgeInsets.all(24),
                          child: Text(
                            state.errorMessage,
                            textAlign: TextAlign.center,
                            style: Theme.of(context).textTheme.bodyLarge!
                                .copyWith(color: AppColors.primaryColor),
                          ),
                        ),
                      );
                    }
                    return state.tab == RadioTab.radio
                        ? _RadioList(state: state)
                        : _RecitersList(state: state);
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Tabs extends StatelessWidget {
  const _Tabs();

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<RadioBloc, RadioState>(
      buildWhen: (a, b) => a.tab != b.tab,
      builder: (context, state) {
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            children: [
              Expanded(
                child: _TabButton(
                  label: 'Radio',
                  selected: state.tab == RadioTab.radio,
                  onTap: () => context.read<RadioBloc>().add(
                    const SelectTabEvent(RadioTab.radio),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _TabButton(
                  label: 'Reciters',
                  selected: state.tab == RadioTab.reciters,
                  onTap: () => context.read<RadioBloc>().add(
                    const SelectTabEvent(RadioTab.reciters),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _TabButton extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _TabButton({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: selected ? AppColors.primaryColor : Colors.transparent,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.primaryColor),
        ),
        child: Text(
          label,
          // Both states use Janna (theme font); only the colour changes so the
          // unselected tab never falls back to Arial (Figma comment #6).
          style: Theme.of(context).textTheme.bodyLarge!.copyWith(
            color: selected ? AppColors.titleTextColor : AppColors.textColor,
          ),
        ),
      ),
    );
  }
}

class _RadioList extends StatelessWidget {
  final RadioState state;

  const _RadioList({required this.state});

  @override
  Widget build(BuildContext context) {
    if (state.radios.isEmpty) {
      return const _EmptyHint(text: 'No radios available');
    }
    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
      itemCount: state.radios.length,
      separatorBuilder: (_, _) => const SizedBox(height: 14),
      itemBuilder: (context, index) {
        final station = state.radios[index];
        final id = 'radio_${station.id}';
        return StationTile(
          name: station.name,
          isPlaying: state.currentId == id && state.isPlaying,
          onPlayPause: () => context.read<RadioBloc>().add(
            PlayItemEvent(id: id, url: station.url),
          ),
        );
      },
    );
  }
}

class _RecitersList extends StatelessWidget {
  final RadioState state;

  const _RecitersList({required this.state});

  @override
  Widget build(BuildContext context) {
    if (state.reciters.isEmpty) {
      return const _EmptyHint(text: 'No reciters available');
    }
    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
      itemCount: state.reciters.length,
      separatorBuilder: (_, _) => const SizedBox(height: 14),
      itemBuilder: (context, index) {
        final reciter = state.reciters[index];
        return _ReciterTile(reciter: reciter);
      },
    );
  }
}

/// A reciter row on the Reciters tab. Tapping it opens the reciter's sura list
/// (where suras can be downloaded); a badge shows how many are already saved.
class _ReciterTile extends StatelessWidget {
  final Reciter reciter;

  const _ReciterTile({required this.reciter});

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

class _EmptyHint extends StatelessWidget {
  final String text;

  const _EmptyHint({required this.text});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Text(text, style: const TextStyle(color: AppColors.primaryColor)),
    );
  }
}
