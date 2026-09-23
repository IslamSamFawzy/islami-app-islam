import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

/// The dark play/pause control on the gold audio tiles.
class PlayPauseButton extends StatelessWidget {
  final bool isPlaying;
  final VoidCallback onPressed;

  /// 32 on the sura rows, a little larger on a station tile.
  final double size;

  const PlayPauseButton({
    super.key,
    required this.isPlaying,
    required this.onPressed,
    this.size = 32,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onPressed,
      child: Icon(
        isPlaying ? Icons.pause_circle_filled : Icons.play_circle_fill,
        color: AppColors.backgroundColor,
        size: size,
      ),
    );
  }
}
