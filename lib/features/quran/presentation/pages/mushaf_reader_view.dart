import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/constants/sura_names.dart';
import '../../../../core/di/service_locator.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../core/widgets/error_view.dart';
import '../../../../core/widgets/loading_view.dart';
import '../../domain/entities/mushaf_page.dart';
import '../bloc/mushaf/mushaf_reader_bloc.dart';
import '../widgets/mushaf_go_to_sheet.dart';
import '../widgets/mushaf_page_widget.dart';
import 'quran_text_about_view.dart';

/// What the reader is opened with: which sura, and whether to pick up where
/// the reader left off in it (Most Recently) or start at its first page.
class MushafReaderArgs {
  final int sura;
  final bool resume;

  const MushafReaderArgs(this.sura, {this.resume = false});
}

/// The Quran as the Madinah Mushaf prints it: 604 pages, right to left.
class MushafReaderView extends StatelessWidget {
  static const String routeName = '/mushaf';

  const MushafReaderView({super.key});

  @override
  Widget build(BuildContext context) {
    final args = ModalRoute.of(context)!.settings.arguments as MushafReaderArgs;
    return BlocProvider(
      create: (_) => sl<MushafReaderBloc>()
        ..add(MushafOpenedEvent(args.sura, resume: args.resume)),
      child: const _Reader(),
    );
  }
}

class _Reader extends StatefulWidget {
  const _Reader();

  @override
  State<_Reader> createState() => _ReaderState();
}

class _ReaderState extends State<_Reader> with WidgetsBindingObserver {
  PageController? _controller;

  /// Pinch-zoom over the pages. It sits outside the PageView, so a one-finger
  /// swipe reaches the PageView first and always turns the page, however
  /// fast; a pinch reaches the zoom. The line breaks stay the Mushaf's.
  final _zoom = TransformationController();

  /// Paging is off while zoomed in, so a pan moves around the page.
  bool _zoomed = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _controller?.dispose();
    _zoom.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // The app may be killed in the background: save first.
    if (state == AppLifecycleState.paused) {
      context.read<MushafReaderBloc>().add(const MushafSaveNowEvent());
    }
  }

  void _jumpTo(int page) {
    final controller = _controller;
    if (controller == null) {
      _controller = PageController(initialPage: page - 1);
    } else if (controller.hasClients) {
      controller.jumpToPage(page - 1);
    }
  }

  Future<void> _openGoTo() async {
    final bloc = context.read<MushafReaderBloc>();
    final target = await showModalBottomSheet<MushafTarget>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.backgroundColor,
      builder: (_) => MushafGoToSheet(currentPage: bloc.state.page),
    );
    if (target != null) bloc.add(MushafGoToEvent(target));
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<MushafReaderBloc, MushafReaderState>(
      listenWhen: (a, b) => a.jumpCount != b.jumpCount,
      listener: (context, state) => _jumpTo(state.page),
      buildWhen: (a, b) =>
          a.status != b.status ||
          a.page != b.page ||
          (a.pages[a.page] == null) != (b.pages[b.page] == null),
      builder: (context, state) {
        final page = state.pages[state.page];
        return Scaffold(
          appBar: AppBar(
            backgroundColor: Colors.transparent,
            centerTitle: true,
            iconTheme: const IconThemeData(color: AppColors.primaryColor),
            title: Text(page == null ? '' : _suraTitle(page)),
            titleTextStyle: Theme.of(context).textTheme.titleLarge!.copyWith(
              color: AppColors.primaryColor,
              fontWeight: FontWeight.bold,
            ),
            actions: [
              IconButton(
                tooltip: 'About the Quran text',
                icon: const Icon(Icons.info_outline),
                onPressed: () => Navigator.pushNamed(
                  context,
                  QuranTextAboutView.routeName,
                ),
              ),
              IconButton(
                tooltip: 'Go to',
                icon: const Icon(Icons.menu_book_outlined),
                onPressed: state.status.isSuccess ? _openGoTo : null,
              ),
            ],
          ),
          // Clear of the gesture bar, which would cover the page number.
          body: SafeArea(
            top: false,
            child: switch (state.status) {
              _ when state.status.isBusy => const LoadingView(),
              _ when state.status.isFailure => ErrorView(
                message: state.errorMessage ?? 'Could not open the Mushaf',
              ),
              _ => _pages(context),
            },
          ),
        );
      },
    );
  }

  Widget _pages(BuildContext context) {
    _controller ??= PageController(
      initialPage: context.read<MushafReaderBloc>().state.page - 1,
    );
    return InteractiveViewer(
      transformationController: _zoom,
      minScale: 1,
      maxScale: 3,
      panEnabled: _zoomed,
      onInteractionEnd: (_) {
        final zoomed = _zoom.value.getMaxScaleOnAxis() > 1.01;
        if (zoomed != _zoomed) setState(() => _zoomed = zoomed);
      },
      // Right to left: page 2 lies to the left of page 1, as in a Mushaf.
      child: Directionality(
        textDirection: TextDirection.rtl,
        child: PageView.builder(
          controller: _controller,
          itemCount: MushafReaderBloc.pageCount,
          physics: _zoomed
              ? const NeverScrollableScrollPhysics()
              : const PageScrollPhysics(),
          onPageChanged: (i) {
            // A new page starts unzoomed.
            _zoom.value = Matrix4.identity();
            setState(() => _zoomed = false);
            context.read<MushafReaderBloc>().add(MushafPageChangedEvent(i + 1));
          },
          itemBuilder: (context, i) => _PageSlot(number: i + 1),
        ),
      ),
    );
  }

  /// The sura the page opens with, as the Mushaf names it in its margin.
  static String _suraTitle(MushafPage page) {
    final first = page.words.firstOrNull;
    return first == null ? '' : SuraNames.all[first.sura - 1].nameAr;
  }
}

/// One page of the PageView: asks for its content, then shows it with its
/// margins.
class _PageSlot extends StatefulWidget {
  final int number;

  const _PageSlot({required this.number});

  @override
  State<_PageSlot> createState() => _PageSlotState();
}

class _PageSlotState extends State<_PageSlot> {
  @override
  void initState() {
    super.initState();
    context.read<MushafReaderBloc>().add(MushafPageNeededEvent(widget.number));
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<MushafReaderBloc, MushafReaderState>(
      buildWhen: (a, b) =>
          a.pages[widget.number] != b.pages[widget.number] ||
          a.failedPages.contains(widget.number) !=
              b.failedPages.contains(widget.number) ||
          a.selected != b.selected,
      builder: (context, state) {
        final page = state.pages[widget.number];
        if (page == null) {
          if (!state.failedPages.contains(widget.number)) {
            return const LoadingView();
          }
          return ErrorView(
            message: 'Could not load page ${widget.number}',
            onRetry: () => context
                .read<MushafReaderBloc>()
                .add(MushafPageNeededEvent(widget.number)),
          );
        }
        return _framed(context, page, state);
      },
    );
  }

  Widget _framed(BuildContext context, MushafPage page, MushafReaderState state) {
    final margin = Theme.of(context).textTheme.bodyMedium!.copyWith(
      color: AppColors.primaryColor.withValues(alpha: 0.8),
    );
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 0, 12, 8),
      child: Column(
        children: [
          // The margin: juz and hizb, as the Mushaf marks them.
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('الجزء ${toArabicDigits(page.juz)}', style: margin),
              Text('الحزب ${toArabicDigits(page.hizb)}', style: margin),
            ],
          ),
          const SizedBox(height: 4),
          Expanded(
            child: MushafPageWidget(
              page: page,
              selected: state.selected,
              onAyahTap: (ayah) => context
                  .read<MushafReaderBloc>()
                  .add(MushafAyahTappedEvent(ayah)),
            ),
          ),
          Semantics(
            label: 'Page ${page.number}',
            excludeSemantics: true,
            child: Text(toArabicDigits(page.number), style: margin),
          ),
        ],
      ),
    );
  }
}
