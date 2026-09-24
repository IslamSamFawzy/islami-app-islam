import 'package:flutter/material.dart';

import '../../../../core/gen/assets.gen.dart';
import '../../../../core/theme/app_colors.dart';

/// The gold bar at the bottom of the app: one item per tab.
class HomeNavigationBar extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onTap;

  const HomeNavigationBar({
    super.key,
    required this.currentIndex,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return BottomNavigationBar(
      currentIndex: currentIndex,
      onTap: onTap,
      items: [
        _item(Assets.icons.icQuran, 'Quran'),
        _item(Assets.icons.icHadeth, 'Hadith'),
        _item(Assets.icons.icSebha, 'Sebha'),
        _item(Assets.icons.icRadio, 'Radio'),
        _item(Assets.icons.icTime, 'Time'),
        _item(Assets.icons.icPrayer, 'Salah'),
      ],
    );
  }

  BottomNavigationBarItem _item(SvgGenImage icon, String label) {
    return BottomNavigationBarItem(
      // Unselected: dark icon only, on the gold bar (spec §2.9).
      icon: icon.svg(
        width: 22,
        height: 22,
        colorFilter: const ColorFilter.mode(
          AppColors.titleTextColor,
          BlendMode.srcIn,
        ),
      ),
      // Selected: dark #202020 pill (radius ~40) with the icon tinted white
      // inside; the label renders under it (dark) via the theme.
      //
      // The pill's padding is what decides whether the tabs fit: six of them
      // leave 60dp each on a 360dp screen, so 22 + 2×14 = 50dp keeps a margin.
      activeIcon: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        decoration: BoxDecoration(
          color: AppColors.backgroundColor,
          borderRadius: BorderRadius.circular(40),
        ),
        child: icon.svg(
          width: 22,
          height: 22,
          colorFilter: const ColorFilter.mode(AppColors.white, BlendMode.srcIn),
        ),
      ),
      label: label,
    );
  }
}
