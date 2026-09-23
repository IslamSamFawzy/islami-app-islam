import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/di/service_locator.dart';
import '../../../../core/gen/assets.gen.dart';
import '../../../../core/widgets/header_logo.dart';
import '../bloc/quran_bloc.dart';
import '../widgets/most_recently_widget.dart';
import '../widgets/sura_list_view.dart';
import '../widgets/sura_search_field.dart';

class QuranView extends StatelessWidget {
  const QuranView({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => sl<QuranBloc>()..add(const LoadSurasEvent()),
      child: const _QuranViewBody(),
    );
  }
}

class _QuranViewBody extends StatelessWidget {
  const _QuranViewBody();

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Assets.images.quranBackground.image(
          width: double.infinity,
          fit: BoxFit.cover,
        ),
        SafeArea(
          child: SingleChildScrollView(
            child: Column(
              spacing: 20,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const HeaderLogo(widthFactor: 0.7),
                const SuraSearchField(),
                const MostRecentlyWidget(),
                const SuraListView(),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
