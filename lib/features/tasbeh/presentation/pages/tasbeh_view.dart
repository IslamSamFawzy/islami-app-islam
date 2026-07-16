import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/gen/assets.gen.dart';
import '../../../../core/theme/app_colors.dart';
import '../cubit/tasbeh_cubit.dart';
import '../widgets/tasbeh_beads.dart';

class TasbehView extends StatelessWidget {
  const TasbehView({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => TasbehCubit(),
      child: const _TasbehViewBody(),
    );
  }
}

class _TasbehViewBody extends StatelessWidget {
  const _TasbehViewBody();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      decoration: BoxDecoration(
        image: DecorationImage(
          image: Assets.images.taspehBackground.provider(),
          fit: BoxFit.cover,
        ),
      ),
      child: SafeArea(
        child: Column(
          children: [
            Center(
              child: Assets.images.imgHeader.image(
                width: MediaQuery.of(context).size.width * 0.55,
              ),
            ),
            const SizedBox(height: 8),
            // Plain cream text, no underline (matches the Figma); tashkeel kept.
            Text(
              'سَبِّحِ اسْمَ رَبِّكَ الأَعْلَى',
              style: theme.textTheme.headlineSmall!.copyWith(
                color: AppColors.textColor,
              ),
            ),
            const Spacer(),
            BlocBuilder<TasbehCubit, TasbehState>(
              builder: (context, state) {
                return GestureDetector(
                  onTap: () {
                    HapticFeedback.selectionClick();
                    context.read<TasbehCubit>().increment();
                  },
                  child: TasbehBeads(
                    totalCount: state.totalCount,
                    dhikr: state.currentDhikr,
                    count: state.count,
                  ),
                );
              },
            ),
            const Spacer(),
          ],
        ),
      ),
    );
  }
}
