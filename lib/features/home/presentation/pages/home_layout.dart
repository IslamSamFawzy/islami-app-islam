import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/gen/assets.gen.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../hadith/presentation/pages/hadith_view.dart';
import '../../../quran/presentation/pages/quran_view.dart';
import '../../../radio/presentation/pages/radio_view.dart';
import '../../../tasbeh/presentation/pages/tasbeh_view.dart';
import '../../../time/presentation/pages/time_view.dart';
import '../cubit/home_cubit.dart';

class HomeLayout extends StatelessWidget {
  static const String routeName = '/layout';

  const HomeLayout({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => HomeCubit(),
      child: const _HomeLayoutBody(),
    );
  }
}

class _HomeLayoutBody extends StatelessWidget {
  const _HomeLayoutBody();

  static const List<Widget> _screens = [
    QuranView(),
    HadithView(),
    TasbehView(),
    RadioView(),
    TimeView(),
  ];

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<HomeCubit, int>(
      builder: (context, selectedIndex) {
        return Scaffold(
          body: IndexedStack(
            index: selectedIndex,
            children: _screens,
          ),
          bottomNavigationBar: BottomNavigationBar(
            currentIndex: selectedIndex,
            onTap: (index) => context.read<HomeCubit>().changeTab(index),
            items: [
              _buildItem(Assets.icons.icQuran, 'Quran'),
              _buildItem(Assets.icons.icHadeth, 'Hadith'),
              _buildItem(Assets.icons.icSebha, 'Sebha'),
              _buildItem(Assets.icons.icRadio, 'Radio'),
              _buildItem(Assets.icons.icTime, 'Time'),
            ],
          ),
        );
      },
    );
  }

  BottomNavigationBarItem _buildItem(SvgGenImage icon, String label) {
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
      // Selected: dark #202020 pill (radius ~40, padding 20×6) with the icon
      // tinted white inside; the label renders under it (dark) via the theme.
      activeIcon: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
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
