import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/di/service_locator.dart';
import '../../../../core/gen/assets.gen.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/app_background.dart';
import '../../../../core/widgets/error_view.dart';
import '../../../../core/widgets/header_logo.dart';
import '../../../../core/widgets/loading_view.dart';
import '../../../../core/widgets/offline_banner.dart';
import '../../../azkar/domain/entities/azkar.dart';
import '../../../azkar/presentation/pages/azkar_view.dart';
import '../../../qibla/presentation/pages/qibla_view.dart';
import '../bloc/time_bloc.dart';
import '../widgets/prayer_times_card.dart';

class TimeView extends StatelessWidget {
  const TimeView({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => sl<TimeBloc>()..add(const LoadPrayerTimesEvent()),
      child: const _TimeViewBody(),
    );
  }
}

class _TimeViewBody extends StatelessWidget {
  const _TimeViewBody();

  @override
  Widget build(BuildContext context) {
    return AppBackground(
      image: Assets.images.timeBackground,
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const HeaderLogo(),
            BlocBuilder<TimeBloc, TimeState>(
              buildWhen: (a, b) => a.showOfflineBanner != b.showOfflineBanner,
              builder: (context, state) => state.showOfflineBanner
                  ? const OfflineBanner()
                  : const SizedBox.shrink(),
            ),
            const SizedBox(height: 10),
            BlocBuilder<TimeBloc, TimeState>(
              builder: (context, state) {
                if (state.status.isBusy) {
                  return const LoadingView(padding: EdgeInsets.all(40));
                }
                if (state.status.isFailure || state.prayerTimes == null) {
                  return ErrorView(
                    message: state.errorMessage.isEmpty
                        ? 'Unable to load prayer times'
                        : state.errorMessage,
                    padding: const EdgeInsets.all(24),
                  );
                }
                return PrayerTimesCard(
                  prayerTimes: state.prayerTimes!,
                  nextPrayerName: state.nextPrayerName,
                  countdown: state.countdown,
                  muted: state.muted,
                  onToggleMute: () =>
                      context.read<TimeBloc>().add(const ToggleMuteEvent()),
                );
              },
            ),
            const SizedBox(height: 20),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Text(
                'Azkar',
                style: Theme.of(
                  context,
                ).textTheme.titleLarge!.copyWith(color: AppColors.textColor),
              ),
            ),
            const SizedBox(height: 12),
            const _AzkarRow(),
            const SizedBox(height: 20),
            const _QiblaCard(),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}

/// Entry card that opens the Qibla compass. Shares the Azkar cards' visual
/// language (dark gradient + gold border) but is shorter and full-width.
class _QiblaCard extends StatelessWidget {
  const _QiblaCard();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: GestureDetector(
        onTap: () => Navigator.pushNamed(context, QiblaView.routeName),
        child: Container(
          height: 110,
          padding: const EdgeInsets.symmetric(horizontal: 18),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                AppColors.cardGradientTop,
                AppColors.cardGradientBottom,
              ],
            ),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.primaryColor),
          ),
          child: Row(
            children: [
              const Icon(
                Icons.explore_outlined,
                color: AppColors.primaryColor,
                size: 48,
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Qibla',
                      style: theme.textTheme.titleLarge!.copyWith(
                        color: AppColors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Tap to find the Qibla direction',
                      style: theme.textTheme.bodyMedium!.copyWith(
                        color: AppColors.textColor,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.chevron_right,
                color: AppColors.primaryColor.withValues(alpha: 0.7),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _AzkarRow extends StatelessWidget {
  const _AzkarRow();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: Row(
        children: [
          Expanded(
            child: _AzkarCard(
              type: AzkarType.evening,
              title: 'Evening Azkar',
              image: Assets.images.azkarEvening,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _AzkarCard(
              type: AzkarType.morning,
              title: 'Morning Azkar',
              image: Assets.images.azkarMorning,
            ),
          ),
        ],
      ),
    );
  }
}

class _AzkarCard extends StatelessWidget {
  final AzkarType type;
  final String title;
  final AssetGenImage image;

  const _AzkarCard({
    required this.type,
    required this.title,
    required this.image,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        Navigator.pushNamed(context, AzkarView.routeName, arguments: type);
      },
      child: Container(
        height: 200,
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              AppColors.cardGradientTop,
              AppColors.cardGradientBottom,
            ],
          ),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.primaryColor),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 3D image fills the upper part of the card.
            Expanded(
              child: Center(child: image.image(fit: BoxFit.contain)),
            ),
            const SizedBox(height: 8),
            Center(
              child: Text(
                title,
                style: const TextStyle(
                  color: AppColors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
