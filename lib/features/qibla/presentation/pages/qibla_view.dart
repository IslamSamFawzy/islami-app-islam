import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/di/service_locator.dart';
import '../../../../core/gen/assets.gen.dart';
import '../../../../core/theme/app_colors.dart';
import '../cubit/qibla_cubit.dart';
import '../widgets/qibla_compass.dart';

class QiblaView extends StatelessWidget {
  static const String routeName = '/qibla';

  const QiblaView({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => sl<QiblaCubit>()..init(),
      child: const _QiblaViewBody(),
    );
  }
}

class _QiblaViewBody extends StatelessWidget {
  const _QiblaViewBody();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      decoration: BoxDecoration(
        image: DecorationImage(
          image: Assets.images.timeBackground.provider(),
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
            'Qibla',
            style: theme.textTheme.titleLarge!.copyWith(
              color: AppColors.primaryColor,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        body: BlocConsumer<QiblaCubit, QiblaState>(
          // Fire the haptic once, on the frame we cross into alignment.
          listenWhen: (prev, curr) =>
              curr.alignedSeq != prev.alignedSeq && curr.isAligned,
          listener: (_, _) => HapticFeedback.mediumImpact(),
          builder: (context, state) {
            switch (state.status) {
              case QiblaStatus.loading:
                return const Center(
                  child: CircularProgressIndicator(
                    color: AppColors.primaryColor,
                  ),
                );
              case QiblaStatus.permissionDenied:
                return _MessageState(
                  icon: Icons.location_off_outlined,
                  message: 'Location permission is needed to find the Qibla.',
                  onRetry: () => context.read<QiblaCubit>().retry(),
                );
              case QiblaStatus.serviceDisabled:
                return _MessageState(
                  icon: Icons.location_disabled_outlined,
                  message: 'Turn on location services to find the Qibla.',
                  onRetry: () => context.read<QiblaCubit>().retry(),
                );
              case QiblaStatus.error:
                return _MessageState(
                  icon: Icons.error_outline,
                  message: state.errorMessage.isEmpty
                      ? 'Something went wrong.'
                      : state.errorMessage,
                  onRetry: () => context.read<QiblaCubit>().retry(),
                );
              case QiblaStatus.ready:
                return _ReadyState(state: state);
            }
          },
        ),
      ),
    );
  }
}

class _ReadyState extends StatelessWidget {
  final QiblaState state;

  const _ReadyState({required this.state});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final width = MediaQuery.of(context).size.width;

    return SafeArea(
      child: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (state.usingCachedLocation)
                _Hint(
                  icon: Icons.cloud_off_outlined,
                  text: 'Showing your last known location (offline).',
                ),
              if (state.hasNoCompass)
                _NoCompass(state: state, theme: theme)
              else
                SizedBox(
                  width: width * 0.70,
                  child: QiblaCompass(
                    heading: state.heading,
                    qiblaBearing: state.qiblaBearing,
                    isAligned: state.isAligned,
                  ),
                ),
              const SizedBox(height: 28),
              Text(
                state.bearingLabel,
                style: theme.textTheme.headlineLarge!.copyWith(
                  color: state.isAligned
                      ? AppColors.white
                      : AppColors.primaryColor,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                '${_thousands(state.distanceKm.round())} km to Mecca',
                style: theme.textTheme.bodyLarge!.copyWith(
                  color: AppColors.textColor,
                ),
              ),
              if (state.isAligned && !state.hasNoCompass) ...[
                const SizedBox(height: 10),
                Text(
                  'Facing the Qibla',
                  style: theme.textTheme.bodyMedium!.copyWith(
                    color: AppColors.white,
                  ),
                ),
              ],
              if (state.lowAccuracy && !state.hasNoCompass) ...[
                const SizedBox(height: 18),
                _Hint(
                  icon: Icons.threesixty,
                  text: 'Move your phone in a figure-8 to calibrate.',
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

/// Shown when the device has no usable compass — still give the bearing, which
/// only needs the location.
class _NoCompass extends StatelessWidget {
  final QiblaState state;
  final ThemeData theme;

  const _NoCompass({required this.state, required this.theme});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 24),
      child: Column(
        children: [
          const Icon(
            Icons.explore_off_outlined,
            color: AppColors.primaryColor,
            size: 72,
          ),
          const SizedBox(height: 16),
          Text(
            "This device has no compass sensor, so the dial can't rotate. "
            'The Qibla direction below is measured from north.',
            textAlign: TextAlign.center,
            style: theme.textTheme.bodyMedium!.copyWith(
              color: AppColors.textColor,
            ),
          ),
        ],
      ),
    );
  }
}

class _MessageState extends StatelessWidget {
  final IconData icon;
  final String message;
  final VoidCallback onRetry;

  const _MessageState({
    required this.icon,
    required this.message,
    required this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: AppColors.primaryColor, size: 64),
            const SizedBox(height: 20),
            Text(
              message,
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyLarge!.copyWith(
                color: AppColors.primaryColor,
              ),
            ),
            const SizedBox(height: 24),
            OutlinedButton(
              onPressed: onRetry,
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: AppColors.primaryColor),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                padding: const EdgeInsets.symmetric(
                  horizontal: 28,
                  vertical: 12,
                ),
              ),
              child: Text(
                'Retry',
                style: theme.textTheme.bodyLarge!.copyWith(
                  color: AppColors.primaryColor,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Hint extends StatelessWidget {
  final IconData icon;
  final String text;

  const _Hint({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.primaryColor.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: AppColors.primaryColor.withValues(alpha: 0.4),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: AppColors.primaryColor, size: 18),
          const SizedBox(width: 8),
          Flexible(
            child: Text(
              text,
              style: theme.textTheme.bodyMedium!.copyWith(
                color: AppColors.textColor,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Groups an integer with thin spaces/commas, e.g. `1234` → `1,234`.
String _thousands(int value) {
  final s = value.abs().toString();
  final buf = StringBuffer(value < 0 ? '-' : '');
  for (var i = 0; i < s.length; i++) {
    if (i > 0 && (s.length - i) % 3 == 0) buf.write(',');
    buf.write(s[i]);
  }
  return buf.toString();
}
