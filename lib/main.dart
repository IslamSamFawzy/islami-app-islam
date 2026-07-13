import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'core/di/service_locator.dart' as di;
import 'core/routes/app_routes.dart';
import 'core/theme/theme_manager.dart';
import 'features/splash/presentation/pages/splash_view.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  // Initialize dependency injection (GetIt).
  await di.init();

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      theme: ThemeManager.darkTheme(),
      debugShowCheckedModeBanner: false,
      initialRoute: SplashView.routeName,
      routes: AppRoutes.routes,
    );
  }
}
