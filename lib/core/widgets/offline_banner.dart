import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../presentation/connectivity_cubit.dart';
import '../theme/app_colors.dart';

/// A small, non-blocking strip shown under a screen's header when the visible
/// data came from the cache and there is no connection. Gold background with
/// dark text; it sits in the layout flow so it never covers content.
class OfflineBanner extends StatelessWidget {
  final String message;

  const OfflineBanner({
    super.key,
    this.message = 'Offline — showing saved data',
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      color: AppColors.primaryColor,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.cloud_off_rounded,
            size: 16,
            color: AppColors.titleTextColor,
          ),
          const SizedBox(width: 8),
          Flexible(
            child: Text(
              message,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppColors.titleTextColor,
                    fontWeight: FontWeight.w600,
                  ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Shows the [OfflineBanner] while the device is offline and [B]'s state has
/// something saved worth labelling as such.
///
/// The "are we offline?" half comes from the app-wide [ConnectivityCubit]; the
/// screen only says what counts as data it can still show.
class OfflineBannerFor<B extends StateStreamable<S>, S>
    extends StatelessWidget {
  final bool Function(S state) hasData;

  const OfflineBannerFor({super.key, required this.hasData});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ConnectivityCubit, bool>(
      builder: (context, online) {
        if (online) return const SizedBox.shrink();
        return BlocBuilder<B, S>(
          buildWhen: (previous, current) =>
              hasData(previous) != hasData(current),
          builder: (context, state) =>
              hasData(state) ? const OfflineBanner() : const SizedBox.shrink(),
        );
      },
    );
  }
}
