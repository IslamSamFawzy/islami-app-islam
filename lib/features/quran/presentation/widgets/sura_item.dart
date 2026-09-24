import 'package:flutter/material.dart';

import '../../../../core/gen/assets.gen.dart';
import '../../../../core/theme/app_colors.dart';
import '../../domain/entities/sura.dart';
import '../open_sura.dart';

class SuraItem extends StatelessWidget {
  final Sura sura;

  const SuraItem({super.key, required this.sura});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return GestureDetector(
      onTap: () => openSura(context, sura),
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
                    '${sura.id}',
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
