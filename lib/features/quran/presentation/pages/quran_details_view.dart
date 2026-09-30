import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:scrollable_positioned_list/scrollable_positioned_list.dart';

import '../../../../core/di/service_locator.dart';
import '../../../../core/gen/assets.gen.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../core/widgets/error_view.dart';
import '../../../../core/widgets/loading_view.dart';
import '../../domain/entities/sura.dart';
import '../bloc/details/quran_details_bloc.dart';

/// What the details screen is opened with: which sura, and whether to pick up
/// where the reader left off (Most Recently) or start at the top (the list).
class QuranDetailsArgs {
  final Sura sura;
  final bool resume;

  const QuranDetailsArgs(this.sura, {this.resume = false});
}

class QuranDetailsView extends StatelessWidget {
  static const String routeName = '/quran-details';

  const QuranDetailsView({super.key});

  @override
  Widget build(BuildContext context) {
    final args = ModalRoute.of(context)!.settings.arguments as QuranDetailsArgs;
    final sura = args.sura;
    final theme = Theme.of(context);

    return BlocProvider(
      create: (_) => sl<QuranDetailsBloc>()
        ..add(LoadVersesEvent(sura.id, resume: args.resume)),
      child: Scaffold(
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          centerTitle: true,
          iconTheme: const IconThemeData(color: AppColors.primaryColor),
          title: Text(sura.nameEn),
          titleTextStyle: theme.textTheme.titleLarge!.copyWith(
            color: AppColors.primaryColor,
            fontWeight: FontWeight.bold,
          ),
        ),
        body: Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Assets.images.imgLeftCorner.image(width: 90, height: 90),
                  Text(
                    sura.nameAr,
                    style: theme.textTheme.headlineLarge!.copyWith(
                      color: AppColors.primaryColor,
                    ),
                  ),
                  Assets.images.imgRightCorner.image(width: 90, height: 90),
                ],
              ),
            ),
            Expanded(child: _VersesList(withBasmala: sura.opensWithBasmala)),
            Assets.images.imgBottomDecoration.image(),
          ],
        ),
      ),
    );
  }
}

/// The ayah list, which also reports where the reader is.
class _VersesList extends StatefulWidget {
  /// Show the basmala as a header above the first ayah. It is not an ayah:
  /// it takes list slot 0, and every ayah index is shifted by one.
  final bool withBasmala;

  const _VersesList({required this.withBasmala});

  @override
  State<_VersesList> createState() => _VersesListState();
}

class _VersesListState extends State<_VersesList> with WidgetsBindingObserver {
  final ItemPositionsListener _positions = ItemPositionsListener.create();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _positions.itemPositions.addListener(_reportFirstVisible);
  }

  @override
  void dispose() {
    _positions.itemPositions.removeListener(_reportFirstVisible);
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // Leaving the app should not lose the last few seconds of reading.
    if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.inactive) {
      context.read<QuranDetailsBloc>().add(const SaveProgressNowEvent());
    }
  }

  /// The topmost ayah that is completely on screen — the one the reader is
  /// actually on. If a single ayah fills the screen, that one counts.
  void _reportFirstVisible() {
    final positions = _positions.itemPositions.value;
    if (positions.isEmpty) return;

    final whole = positions.where(
      (p) => p.itemLeadingEdge >= 0 && p.itemTrailingEdge <= 1,
    );
    final candidates = whole.isEmpty ? positions : whole;
    final first = candidates.reduce(
      (a, b) => a.itemLeadingEdge <= b.itemLeadingEdge ? a : b,
    );

    // The basmala header counts as being on the first ayah.
    final ayah = first.index - _offset;

    if (!mounted) return;
    context.read<QuranDetailsBloc>().add(
      VerseVisibleEvent(ayah < 0 ? 0 : ayah),
    );
  }

  int get _offset => widget.withBasmala ? 1 : 0;

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<QuranDetailsBloc, QuranDetailsState>(
      builder: (context, state) {
        if (state.status.isBusy) return const LoadingView();

        if (state.status.isFailure) {
          return ErrorView(message: state.errorMessage);
        }

        return ScrollablePositionedList.separated(
          itemPositionsListener: _positions,
          // Where the reader left off, or the top (basmala included) for a
          // fresh read.
          initialScrollIndex:
              state.initialIndex <= 0 ? 0 : state.initialIndex + _offset,
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
          itemCount: state.verses.length + _offset,
          separatorBuilder: (_, _) => const SizedBox(height: 12),
          itemBuilder: (context, item) {
            if (item < _offset) return const _Basmala();
            final index = item - _offset;
            return _AyahCard(
              text: "${state.verses[index]} ﴿${toArabicDigits(index + 1)}﴾",
              selected: state.selectedIndex == index,
              onTap: () => context.read<QuranDetailsBloc>().add(
                SelectVerseEvent(index),
              ),
            );
          },
        );
      },
    );
  }
}

/// The basmala above every sura except Al-Fatiha and At-Tawba: gold text on
/// its own, without a card or a number, since it is not one of the ayat.
class _Basmala extends StatelessWidget {
  const _Basmala();

  /// Tanzil's text, the same as Al-Fatiha 1:1.
  static const String text = 'بِسْمِ اللَّهِ الرَّحْمَـٰنِ الرَّحِيمِ';

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Text(
        text,
        textDirection: TextDirection.rtl,
        textAlign: TextAlign.center,
        style: Theme.of(context).textTheme.headlineSmall!.copyWith(
          color: AppColors.primaryColor,
          height: 1.8,
        ),
      ),
    );
  }
}

/// A single ayah rendered as a bordered card (spec §2.4): 1px gold border,
/// radius 8, transparent fill, gold RTL text with the verse number after it.
/// When [selected] it flips to a solid-gold fill with dark text.
class _AyahCard extends StatelessWidget {
  final String text;
  final bool selected;
  final VoidCallback onTap;

  const _AyahCard({
    required this.text,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: selected ? AppColors.primaryColor : Colors.transparent,
          border: Border.all(color: AppColors.primaryColor, width: 1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(
          text,
          textDirection: TextDirection.rtl,
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.titleLarge!.copyWith(
            color: selected ? AppColors.titleTextColor : AppColors.primaryColor,
            height: 1.8,
          ),
        ),
      ),
    );
  }
}
