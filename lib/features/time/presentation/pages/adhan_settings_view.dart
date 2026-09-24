import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/di/service_locator.dart';
import '../../../../core/gen/assets.gen.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/app_background.dart';
import '../../domain/entities/prayer_name.dart';
import '../cubit/adhan_settings_cubit.dart';

/// Which adhans the user wants: a master switch and one switch per prayer.
class AdhanSettingsView extends StatelessWidget {
  static const String routeName = '/settings';

  const AdhanSettingsView({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => sl<AdhanSettingsCubit>()..load(),
      child: const _AdhanSettingsBody(),
    );
  }
}

class _AdhanSettingsBody extends StatelessWidget {
  const _AdhanSettingsBody();

  @override
  Widget build(BuildContext context) {
    return AppBackground(
      image: Assets.images.timeBackground,
      title: 'Settings',
      child: BlocBuilder<AdhanSettingsCubit, AdhanSettingsState>(
        builder: (context, state) {
          final cubit = context.read<AdhanSettingsCubit>();
          final enabled = state.settings.enabled;

          return ListView(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
            children: [
              _SettingsCard(
                child: _AdhanSwitch(
                  title: 'Adhan notifications',
                  subtitle: 'Play the adhan at prayer times',
                  value: enabled,
                  onChanged: cubit.setEnabled,
                ),
              ),
              if (state.permissionDenied) const _PermissionHint(),
              const SizedBox(height: 16),
              Padding(
                padding: const EdgeInsets.only(left: 4, bottom: 8),
                child: Text(
                  'Prayers',
                  style: Theme.of(context).textTheme.titleLarge!.copyWith(
                    color: AppColors.textColor,
                    fontSize: 16,
                  ),
                ),
              ),
              _SettingsCard(
                child: Column(
                  children: [
                    for (final prayer in PrayerName.values)
                      _AdhanSwitch(
                        title: prayer.label,
                        value: state.settings.prayers.contains(prayer),
                        // Every prayer follows the master switch.
                        onChanged: enabled
                            ? (_) => cubit.togglePrayer(prayer)
                            : null,
                      ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

/// The dark bordered card the rest of the app uses for grouped content.
class _SettingsCard extends StatelessWidget {
  final Widget child;

  const _SettingsCard({required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
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
      child: child,
    );
  }
}

class _AdhanSwitch extends StatelessWidget {
  final String title;
  final String? subtitle;
  final bool value;

  /// Null disables the row (a prayer while the master switch is off).
  final ValueChanged<bool>? onChanged;

  const _AdhanSwitch({
    required this.title,
    required this.value,
    required this.onChanged,
    this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final off = onChanged == null;

    return SwitchListTile(
      value: value,
      onChanged: onChanged,
      contentPadding: const EdgeInsets.symmetric(horizontal: 8),
      activeThumbColor: AppColors.primaryColor,
      activeTrackColor: AppColors.primaryColor.withValues(alpha: 0.4),
      title: Text(
        title,
        style: theme.textTheme.titleLarge!.copyWith(
          color: off ? AppColors.white.withValues(alpha: 0.5) : AppColors.white,
          fontSize: 16,
        ),
      ),
      subtitle: subtitle == null
          ? null
          : Text(
              subtitle!,
              style: theme.textTheme.bodyMedium!.copyWith(
                color: AppColors.textColor.withValues(alpha: 0.7),
              ),
            ),
    );
  }
}

/// Shown when the device refused the notification permission, which is why the
/// master switch went back off.
class _PermissionHint extends StatelessWidget {
  const _PermissionHint();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 12, 4, 0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(
            Icons.notifications_off_outlined,
            color: AppColors.primaryColor,
            size: 20,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'Notifications are turned off for Islami, so the adhan cannot '
              'play. Allow them in your device settings, then switch this on '
              'again.',
              style: Theme.of(context).textTheme.bodyMedium!.copyWith(
                color: AppColors.textColor,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
