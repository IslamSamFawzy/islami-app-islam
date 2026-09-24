import 'package:flutter/material.dart';

import '../../features/azkar/presentation/pages/azkar_view.dart';
import '../../features/downloads/presentation/pages/downloads_view.dart';
import '../../features/hadith/presentation/pages/hadith_details_view.dart';
import '../../features/home/presentation/pages/home_layout.dart';
import '../../features/intro/presentation/pages/intro_view.dart';
import '../../features/qibla/presentation/pages/qibla_view.dart';
import '../../features/quran/presentation/pages/quran_details_view.dart';
import '../../features/radio/presentation/pages/reciter_suras_view.dart';
import '../../features/splash/presentation/pages/splash_view.dart';
import '../../features/time/presentation/pages/adhan_settings_view.dart';

abstract class AppRoutes {
  static Map<String, WidgetBuilder> routes = {
    SplashView.routeName: (context) => const SplashView(),
    IntroView.routeName: (context) => const IntroView(),
    HomeLayout.routeName: (context) => const HomeLayout(),
    QuranDetailsView.routeName: (context) => const QuranDetailsView(),
    HadithDetailsView.routeName: (context) => const HadithDetailsView(),
    AzkarView.routeName: (context) => const AzkarView(),
    ReciterSurasView.routeName: (context) => const ReciterSurasView(),
    DownloadsView.routeName: (context) => const DownloadsView(),
    QiblaView.routeName: (context) => const QiblaView(),
    AdhanSettingsView.routeName: (context) => const AdhanSettingsView(),
  };
}
