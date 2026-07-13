import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/di/service_locator.dart';
import '../../../../core/gen/assets.gen.dart';
import '../../../home/presentation/pages/home_layout.dart';
import '../../../intro/presentation/pages/intro_view.dart';
import '../cubit/splash_cubit.dart';

class SplashView extends StatelessWidget {
  static const String routeName = '/';

  const SplashView({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => SplashCubit(sl())..startTimer(),
      child: BlocListener<SplashCubit, SplashState>(
        listener: (context, state) {
          if (state.status == SplashStatus.navigate) {
            Navigator.pushNamedAndRemoveUntil(
              context,
              state.onboardingSeen
                  ? HomeLayout.routeName
                  : IntroView.routeName,
              (route) => false,
            );
          }
        },
        child: const _SplashViewBody(),
      ),
    );
  }
}

class _SplashViewBody extends StatelessWidget {
  const _SplashViewBody();

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    return Scaffold(
      body: Center(
        child: Stack(
          children: [
            Assets.images.splashScreen.image(
              height: double.infinity,
              width: double.infinity,
            ),
            Align(
              alignment: Alignment.topCenter,
              child: Padding(
                padding: const EdgeInsets.only(top: 57),
                child: Assets.images.splashMosqe.image(
                  width: size.width * 0.7,
                ),
              ),
            ),
            Align(
              alignment: Alignment.topRight,
              child: Assets.images.splashGlow.image(
                height: size.height * 0.4,
                width: size.width * 0.3,
              ),
            ),
            Positioned(
              top: size.height * 0.3,
              child: Assets.images.splashLift.image(
                height: size.height * 0.2,
                width: size.width * 0.2,
              ),
            ),
            Align(
              alignment: Alignment.center,
              child: Assets.images.islamiLogo.image(
                height: size.height * 0.4,
                width: size.width * 0.4,
              ),
            ),
            Align(
              alignment: Alignment.bottomRight,
              child: Padding(
                padding: const EdgeInsets.only(bottom: 100),
                child: Assets.images.splashRight.image(
                  height: size.height * 0.2,
                  width: size.width * 0.2,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
