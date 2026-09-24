import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/di/service_locator.dart';
import '../../../../core/gen/assets.gen.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/app_background.dart';
import '../../../../core/widgets/error_view.dart';
import '../../../../core/widgets/header_logo.dart';
import '../../../../core/widgets/loading_view.dart';
import '../cubit/prayer_guide_cubit.dart';
import '../widgets/prayer_overview_page.dart';
import '../widgets/prayer_step_page.dart';

/// The "How to pray" tab: an overview page followed by one page per step,
/// each with an animated figure, an explanation and its hadith evidence.
class PrayerGuideView extends StatelessWidget {
  const PrayerGuideView({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => sl<PrayerGuideCubit>()..load(),
      child: const _PrayerGuideBody(),
    );
  }
}

class _PrayerGuideBody extends StatefulWidget {
  const _PrayerGuideBody();

  @override
  State<_PrayerGuideBody> createState() => _PrayerGuideBodyState();
}

class _PrayerGuideBodyState extends State<_PrayerGuideBody> {
  final PageController _controller = PageController();

  static const _pageDuration = Duration(milliseconds: 300);

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _goTo(int page) =>
      _controller.animateToPage(page, duration: _pageDuration, curve: Curves.easeOut);

  @override
  Widget build(BuildContext context) {
    return AppBackground(
      image: Assets.images.timeBackground,
      child: Column(
        children: [
          const HeaderLogo(widthFactor: 0.55),
          const SizedBox(height: 8),
          Expanded(
            child: BlocBuilder<PrayerGuideCubit, PrayerGuideState>(
              buildWhen: (a, b) => a.status != b.status || a.guide != b.guide,
              builder: (context, state) {
                if (state.status.isBusy) return const LoadingView();

                if (state.status.isFailure || state.guide == null) {
                  return ErrorView(
                    message: state.errorMessage,
                    padding: const EdgeInsets.all(24),
                  );
                }

                final guide = state.guide!;
                return PageView.builder(
                  controller: _controller,
                  itemCount: state.pageCount,
                  onPageChanged: context
                      .read<PrayerGuideCubit>()
                      .onPageChanged,
                  itemBuilder: (context, index) => index == 0
                      ? PrayerOverviewPage(guide: guide)
                      : PrayerStepPage(
                          step: guide.steps[index - 1],
                          number: index,
                        ),
                );
              },
            ),
          ),
          _PageControls(onGoTo: _goTo),
        ],
      ),
    );
  }
}

/// Previous / "n of m" / next, under the pages.
class _PageControls extends StatelessWidget {
  final ValueChanged<int> onGoTo;

  const _PageControls({required this.onGoTo});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<PrayerGuideCubit, PrayerGuideState>(
      builder: (context, state) {
        if (!state.status.isSuccess) return const SizedBox.shrink();
        final label = state.isFirstPage
            ? 'نظرة عامة'
            : 'الخطوة ${state.pageIndex} من ${state.pageCount - 1}';
        return Padding(
          padding: const EdgeInsets.fromLTRB(8, 4, 8, 8),
          child: Row(
            children: [
              IconButton(
                tooltip: 'Previous',
                onPressed: state.isFirstPage
                    ? null
                    : () => onGoTo(state.pageIndex - 1),
                icon: const Icon(Icons.chevron_left),
                color: AppColors.primaryColor,
                disabledColor: AppColors.primaryColor.withValues(alpha: 0.3),
              ),
              Expanded(
                child: Text(
                  label,
                  textAlign: TextAlign.center,
                  textDirection: TextDirection.rtl,
                  style: Theme.of(context).textTheme.bodyLarge!.copyWith(
                    color: AppColors.textColor,
                  ),
                ),
              ),
              IconButton(
                tooltip: 'Next',
                onPressed: state.isLastPage
                    ? null
                    : () => onGoTo(state.pageIndex + 1),
                icon: const Icon(Icons.chevron_right),
                color: AppColors.primaryColor,
                disabledColor: AppColors.primaryColor.withValues(alpha: 0.3),
              ),
            ],
          ),
        );
      },
    );
  }
}
