import 'package:flutter/material.dart';

import '../../features/azkar/presentation/pages/azkar_view.dart';
import '../../features/home/presentation/pages/home_layout.dart';
import '../../features/quran/presentation/pages/quran_details_view.dart';
import '../../features/splash/presentation/pages/splash_view.dart';

abstract class AppRoutes {
  static Map<String, WidgetBuilder> routes = {
    SplashView.routeName: (context) => const SplashView(),
    HomeLayout.routeName: (context) => const HomeLayout(),
    QuranDetailsView.routeName: (context) => const QuranDetailsView(),
    AzkarView.routeName: (context) => const AzkarView(),
  };
}
