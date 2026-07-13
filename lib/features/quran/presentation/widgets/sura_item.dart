import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/gen/assets.gen.dart';
import '../../../../core/theme/app_colors.dart';
import '../../domain/entities/sura.dart';
import '../bloc/quran_bloc.dart';
import '../pages/quran_details_view.dart';

class SuraItem extends StatelessWidget {
  final Sura sura;

  const SuraItem({super.key, required this.sura});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return GestureDetector(
      onTap: () {
        // Record this sura as recently read, then open it.
        context.read<QuranBloc>().add(MarkSuraAsReadEvent(sura));
        Navigator.pushNamed(
          context,
          QuranDetailsView.routeName,
          arguments: sura,
        );
      },
      child: Row(
        children: [
          Stack(
            alignment: Alignment.center,
            children: [
              Assets.images.imgSuraNumberTheme.image(width: 50, height: 50),
              SizedBox(
                width: 28,
                height: 28,
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(
                    sura.id,
                    style: theme.textTheme.titleLarge!.copyWith(
                      color: AppColors.white,
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(width: 24),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  sura.nameEn,
                  style: theme.textTheme.titleLarge!.copyWith(
                    color: AppColors.white,
                  ),
                ),
                Text(
                  '${sura.ayaCount} Verses',
                  style: theme.textTheme.bodyMedium!.copyWith(
                    color: AppColors.white,
                  ),
                ),
              ],
            ),
          ),
          Text(
            sura.nameAr,
            style: theme.textTheme.titleLarge!.copyWith(
              color: AppColors.white,
            ),
          ),
        ],
      ),
    );
  }
}
