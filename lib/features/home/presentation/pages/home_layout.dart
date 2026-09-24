import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../hadith/presentation/pages/hadith_view.dart';
import '../../../prayer_guide/presentation/pages/prayer_guide_view.dart';
import '../../../quran/presentation/pages/quran_view.dart';
import '../../../radio/presentation/pages/radio_view.dart';
import '../../../tasbeh/presentation/pages/tasbeh_view.dart';
import '../../../time/presentation/pages/time_view.dart';
import '../cubit/home_cubit.dart';
import '../widgets/home_navigation_bar.dart';

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
    PrayerGuideView(),
  ];

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<HomeCubit, int>(
      builder: (context, selectedIndex) {
        return Scaffold(
          body: IndexedStack(
            index: selectedIndex,
            children: [
              for (var i = 0; i < _screens.length; i++)
                // Every screen stays alive in the stack, so their animations
                // (the prayer figure, the radio waveform) would keep ticking
                // out of sight. Only the visible tab gets a ticker.
                TickerMode(enabled: i == selectedIndex, child: _screens[i]),
            ],
          ),
          bottomNavigationBar: HomeNavigationBar(
            currentIndex: selectedIndex,
            onTap: (index) => context.read<HomeCubit>().changeTab(index),
          ),
        );
      },
    );
  }
}
