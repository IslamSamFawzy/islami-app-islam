import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/di/service_locator.dart';
import '../../../../core/gen/assets.gen.dart';
import '../../../../core/theme/app_colors.dart';
import '../../domain/entities/azkar.dart';
import '../bloc/azkar_bloc.dart';

class AzkarView extends StatelessWidget {
  static const String routeName = '/azkar';

  const AzkarView({super.key});

  @override
  Widget build(BuildContext context) {
    final type = ModalRoute.of(context)!.settings.arguments as AzkarType;
    return BlocProvider(
      create: (_) => sl<AzkarBloc>()..add(LoadAzkarEvent(type)),
      child: const _AzkarViewBody(),
    );
  }
}

class _AzkarViewBody extends StatelessWidget {
  const _AzkarViewBody();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      decoration: BoxDecoration(
        image: DecorationImage(
          image: Assets.images.timeBackground.provider(),
          fit: BoxFit.cover,
        ),
      ),
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          centerTitle: true,
          iconTheme: const IconThemeData(color: AppColors.primaryColor),
          title: BlocBuilder<AzkarBloc, AzkarState>(
            builder: (context, state) => Text(
              state.collection?.title ?? 'Azkar',
              style: theme.textTheme.titleLarge!.copyWith(
                color: AppColors.primaryColor,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
        body: BlocBuilder<AzkarBloc, AzkarState>(
          builder: (context, state) {
            if (state.status == AzkarStatus.loading ||
                state.status == AzkarStatus.initial) {
              return const Center(
                child: CircularProgressIndicator(
                  color: AppColors.primaryColor,
                ),
              );
            }
            if (state.status == AzkarStatus.failure ||
                state.collection == null) {
              return Center(
                child: Text(
                  state.errorMessage,
                  style: theme.textTheme.bodyLarge!
                      .copyWith(color: AppColors.primaryColor),
                ),
              );
            }

            final azkar = state.collection!.azkar;
            return ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: azkar.length,
              separatorBuilder: (_, __) => const SizedBox(height: 14),
              itemBuilder: (context, index) {
                final zikr = azkar[index];
                return Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.primaryColor.withValues(alpha: 0.9),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(
                        zikr.text,
                        textAlign: TextAlign.center,
                        textDirection: TextDirection.rtl,
                        style: theme.textTheme.bodyLarge!.copyWith(
                          color: AppColors.titleTextColor,
                          height: 1.9,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          if (zikr.note.isNotEmpty) ...[
                            Text(
                              zikr.note,
                              style: const TextStyle(
                                color: AppColors.titleTextColor,
                                fontStyle: FontStyle.italic,
                              ),
                            ),
                            const SizedBox(width: 12),
                          ],
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 14,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.backgroundColor,
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              'التكرار: ${zikr.count}',
                              style: const TextStyle(
                                color: AppColors.primaryColor,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                );
              },
            );
          },
        ),
      ),
    );
  }
}
