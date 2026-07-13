import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/di/service_locator.dart';
import '../../../../core/gen/assets.gen.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../azkar/domain/entities/azkar.dart';
import '../../../azkar/presentation/pages/azkar_view.dart';
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
    return Container(
      decoration: BoxDecoration(
        image: DecorationImage(
          image: Assets.images.timeBackground.provider(),
          fit: BoxFit.cover,
        ),
      ),
      child: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Assets.images.imgHeader.image(
                  width: MediaQuery.of(context).size.width * 0.6,
                ),
              ),
              const SizedBox(height: 10),
              BlocBuilder<TimeBloc, TimeState>(
                builder: (context, state) {
                  if (state.status == TimeStatus.loading ||
                      state.status == TimeStatus.initial) {
                    return const Padding(
                      padding: EdgeInsets.all(40),
                      child: Center(
                        child: CircularProgressIndicator(
                          color: AppColors.primaryColor,
                        ),
                      ),
                    );
                  }
                  if (state.status == TimeStatus.failure ||
                      state.prayerTimes == null) {
                    return Padding(
                      padding: const EdgeInsets.all(24),
                      child: Center(
                        child: Text(
                          state.errorMessage.isEmpty
                              ? 'Unable to load prayer times'
                              : state.errorMessage,
                          textAlign: TextAlign.center,
                          style: Theme.of(context).textTheme.bodyLarge!
                              .copyWith(color: AppColors.primaryColor),
                        ),
                      ),
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
                  style: Theme.of(context).textTheme.titleLarge!.copyWith(
                    color: AppColors.textColor,
                  ),
                ),
              ),
              const SizedBox(height: 12),
              const _AzkarRow(),
              const SizedBox(height: 24),
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
              imagePath: 'assets/images/azkar_evening.png',
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _AzkarCard(
              type: AzkarType.morning,
              title: 'Morning Azkar',
              imagePath: 'assets/images/azkar_morning.png',
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
  final String imagePath;

  const _AzkarCard({
    required this.type,
    required this.title,
    required this.imagePath,
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
            colors: [Color(0xff262019), Color(0xff0A0806)],
          ),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.primaryColor),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 3D image fills the upper part of the card.
            Expanded(
              child: Center(child: Image.asset(imagePath, fit: BoxFit.contain)),
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
