import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import 'waveform.dart';

/// A gold tile showing a station/reciter name, a waveform, and play controls.
class StationTile extends StatelessWidget {
  final String name;
  final bool isPlaying;
  final VoidCallback onPlayPause;

  const StationTile({
    super.key,
    required this.name,
    required this.isPlaying,
    required this.onPlayPause,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: AppColors.primaryColor,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        children: [
          Text(
            name,
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: theme.textTheme.titleLarge!.copyWith(
              color: AppColors.titleTextColor,
              fontSize: 16,
            ),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              GestureDetector(
                onTap: onPlayPause,
                child: Icon(
                  isPlaying
                      ? Icons.pause_circle_filled
                      : Icons.play_circle_fill,
                  color: AppColors.backgroundColor,
                  size: 34,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(child: Waveform(active: isPlaying)),
              const SizedBox(width: 12),
              Icon(
                isPlaying ? Icons.volume_up : Icons.volume_mute,
                color: AppColors.backgroundColor,
              ),
            ],
          ),
        ],
      ),
    );
  }
}
