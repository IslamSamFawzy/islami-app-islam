import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/di/service_locator.dart';
import '../../../../core/gen/assets.gen.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../home/presentation/pages/home_layout.dart';
import '../cubit/intro_cubit.dart';

class IntroView extends StatelessWidget {
  static const String routeName = '/intro';

  const IntroView({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => IntroCubit(sl()),
      child: const _IntroViewBody(),
    );
  }
}

class _IntroPageData {
  final AssetGenImage image;
  final String title;
  final String? body;

  const _IntroPageData({required this.image, required this.title, this.body});
}

class _IntroViewBody extends StatefulWidget {
  const _IntroViewBody();

  @override
  State<_IntroViewBody> createState() => _IntroViewBodyState();
}

class _IntroViewBodyState extends State<_IntroViewBody> {
  final PageController _controller = PageController();

  // Copy from DESIGN_SPEC §2.2, including the two Figma review fixes:
  // page 1 -> "Welcome To Islami App" (not "Islmi"), page 4 -> "Azkar" (not "Bearish").
  static final List<_IntroPageData> _pages = [
    _IntroPageData(
      image: Assets.images.intro1Calligraphy,
      title: 'Welcome To Islami App',
    ),
    _IntroPageData(
      image: Assets.images.intro2Mosque,
      title: 'Welcome To Islami',
      body: 'We Are Very Excited To Have You In Our Community',
    ),
    _IntroPageData(
      image: Assets.images.intro3Quran,
      title: 'Reading the Quran',
      body: 'Read, and your Lord is the Most Generous',
    ),
    _IntroPageData(
      image: Assets.images.intro4Tasbeh,
      title: 'Azkar',
      body: 'Praise the name of your Lord, the Most High',
    ),
    _IntroPageData(
      image: Assets.images.intro5Radio,
      title: 'Holy Quran Radio',
      body:
          'You can listen to the Holy Quran Radio through the application '
          'for free and easily',
    ),
  ];

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _onNext(int page) {
    if (page == _pages.length - 1) {
      context.read<IntroCubit>().finish();
    } else {
      _controller.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
  }

  void _onBack() {
    _controller.previousPage(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeOut,
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<IntroCubit, IntroState>(
      listenWhen: (prev, curr) => curr.status == IntroStatus.done,
      listener: (context, state) {
        Navigator.pushNamedAndRemoveUntil(
          context,
          HomeLayout.routeName,
          (route) => false,
        );
      },
      child: Scaffold(
        body: SafeArea(
          child: Column(
            children: [
              const SizedBox(height: 12),
              Assets.images.imgHeader.image(height: 60, fit: BoxFit.contain),
              Expanded(
                child: PageView.builder(
                  controller: _controller,
                  itemCount: _pages.length,
                  onPageChanged: (i) =>
                      context.read<IntroCubit>().onPageChanged(i),
                  itemBuilder: (_, i) => _IntroPageContent(data: _pages[i]),
                ),
              ),
              _IntroBottomBar(
                pageCount: _pages.length,
                onNext: _onNext,
                onBack: _onBack,
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }
}

class _IntroPageContent extends StatelessWidget {
  final _IntroPageData data;

  const _IntroPageContent({required this.data});

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        children: [
          // Large gold line-art, centered, filling the space above the copy.
          Expanded(child: Center(child: data.image.image(fit: BoxFit.contain))),
          Text(
            data.title,
            textAlign: TextAlign.center,
            style: textTheme.headlineSmall?.copyWith(
              color: AppColors.primaryColor,
            ),
          ),
          if (data.body != null) ...[
            const SizedBox(height: 12),
            Text(
              data.body!,
              textAlign: TextAlign.center,
              maxLines: 2,
              style: textTheme.bodyLarge?.copyWith(color: AppColors.textColor),
            ),
          ],
          const SizedBox(height: 24),
        ],
      ),
    );
  }
}

class _IntroBottomBar extends StatelessWidget {
  final int pageCount;
  final void Function(int page) onNext;
  final VoidCallback onBack;

  const _IntroBottomBar({
    required this.pageCount,
    required this.onNext,
    required this.onBack,
  });

  @override
  Widget build(BuildContext context) {
    final buttonStyle = Theme.of(
      context,
    ).textTheme.bodyLarge?.copyWith(color: AppColors.primaryColor);
    return BlocBuilder<IntroCubit, IntroState>(
      builder: (context, state) {
        final page = state.page;
        final isLast = page == pageCount - 1;
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Row(
            children: [
              // Back — hidden on the first page (spec §2.2), layout preserved.
              Expanded(
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: page == 0
                      ? const SizedBox.shrink()
                      : TextButton(
                          onPressed: onBack,
                          child: Text('Back', style: buttonStyle),
                        ),
                ),
              ),
              _Dots(count: pageCount, active: page),
              Expanded(
                child: Align(
                  alignment: Alignment.centerRight,
                  child: TextButton(
                    onPressed: () => onNext(page),
                    child: Text(isLast ? 'Finish' : 'Next', style: buttonStyle),
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

class _Dots extends StatelessWidget {
  final int count;
  final int active;

  const _Dots({required this.count, required this.active});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(count, (i) {
        final isActive = i == active;
        // Active = elongated gold pill; inactive = small muted dot (spec §2.2).
        return AnimatedContainer(
          duration: const Duration(milliseconds: 250),
          margin: const EdgeInsets.symmetric(horizontal: 3),
          width: isActive ? 22 : 8,
          height: 8,
          decoration: BoxDecoration(
            color: isActive
                ? AppColors.primaryColor
                : AppColors.primaryColor.withValues(alpha: 0.35),
            borderRadius: BorderRadius.circular(4),
          ),
        );
      }),
    );
  }
}
