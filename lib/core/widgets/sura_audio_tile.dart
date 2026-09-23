import 'package:flutter/material.dart';

import '../constants/sura_names.dart';
import '../theme/app_colors.dart';
import 'play_pause_button.dart';

/// One sura as a gold row: play/pause, the sura number, its English and Arabic
/// names, and whatever the screen needs at the end — a download control on the
/// reciter's list, the file size and a delete button in the library.
class SuraAudioTile extends StatelessWidget {
  /// The sura number as text: the downloads index stores ids as strings, and a
  /// number this app does not know is still shown rather than dropped.
  final String suraId;

  final bool isPlaying;
  final VoidCallback onPlayPause;

  /// Drawn at the end of the row.
  final Widget? trailing;

  /// Marks the row the player is currently on.
  final bool highlighted;

  const SuraAudioTile({
    super.key,
    required this.suraId,
    required this.isPlaying,
    required this.onPlayPause,
    this.trailing,
    this.highlighted = false,
  });

  @override
  Widget build(BuildContext context) {
    final number = int.tryParse(suraId);
    final info = number == null ? null : SuraNames.byNumber(number);
    final nameStyle = Theme.of(context).textTheme.titleLarge!.copyWith(
      color: AppColors.titleTextColor,
      fontSize: 16,
    );

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.primaryColor,
        borderRadius: BorderRadius.circular(16),
        border: highlighted
            ? Border.all(color: AppColors.backgroundColor, width: 2)
            : null,
      ),
      child: Row(
        children: [
          PlayPauseButton(isPlaying: isPlaying, onPressed: onPlayPause),
          const SizedBox(width: 10),
          Text(
            suraId,
            style: nameStyle.copyWith(
              color: AppColors.titleTextColor.withValues(alpha: 0.7),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              info?.nameEn ?? 'Sura $suraId',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: nameStyle,
            ),
          ),
          // Arabic name, RTL on the right (like the Quran tab's rows).
          if (info != null) ...[
            const SizedBox(width: 8),
            Text(
              info.nameAr,
              textDirection: TextDirection.rtl,
              style: nameStyle,
            ),
          ],
          ?trailing,
        ],
      ),
    );
  }
}
