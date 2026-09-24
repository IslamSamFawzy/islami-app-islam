import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'core/di/service_locator.dart' as di;
import 'core/presentation/connectivity_cubit.dart';
import 'core/routes/app_routes.dart';
import 'core/theme/theme_manager.dart';
import 'features/downloads/presentation/bloc/downloads_bloc.dart';
import 'features/splash/presentation/pages/splash_view.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  // Initialize dependency injection (GetIt).
  await di.init();

  // Reconcile the downloads index against the filesystem once at startup.
  di.sl<DownloadsBloc>().add(const LoadDownloadsEvent());

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    // Above the app: one downloads bloc, so every screen (the reciter sura
    // list, the Downloads screen) sees one queue and one index, and one
    // connectivity cubit, so every screen reads the same "are we online?".
    return MultiBlocProvider(
      providers: [
        BlocProvider<DownloadsBloc>.value(value: di.sl<DownloadsBloc>()),
        BlocProvider<ConnectivityCubit>.value(
          value: di.sl<ConnectivityCubit>(),
        ),
      ],
      child: MaterialApp(
        theme: ThemeManager.darkTheme(),
        debugShowCheckedModeBanner: false,
        initialRoute: SplashView.routeName,
        routes: AppRoutes.routes,
      ),
    );
  }
}
