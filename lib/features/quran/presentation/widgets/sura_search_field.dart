import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/gen/assets.gen.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/search_field.dart';
import '../bloc/quran_bloc.dart';

/// The Quran tab's sura search. Uses the shared [SearchField] styling, keeping
/// its own Quran prefix icon so the tab looks exactly as before.
class SuraSearchField extends StatelessWidget {
  const SuraSearchField({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: SearchField(
        hintText: 'Sura Name',
        onChanged: (value) =>
            context.read<QuranBloc>().add(SearchSurasEvent(value)),
        prefixIcon: Padding(
          padding: const EdgeInsets.all(6.0),
          child: Assets.icons.icQuran.svg(
            colorFilter: const ColorFilter.mode(
              AppColors.primaryColor,
              BlendMode.srcIn,
            ),
          ),
        ),
      ),
    );
  }
}
