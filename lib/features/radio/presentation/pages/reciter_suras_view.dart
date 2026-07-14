import 'package:flutter/material.dart';

import '../../../../core/gen/assets.gen.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../downloads/presentation/widgets/sura_download_control.dart';
import '../../domain/entities/reciter.dart';

/// The sura list for a single reciter. Each row can be downloaded for offline
/// listening. Reached from the Reciters tab.
class ReciterSurasView extends StatelessWidget {
  static const String routeName = '/reciter-suras';

  const ReciterSurasView({super.key});

  @override
  Widget build(BuildContext context) {
    final reciter = ModalRoute.of(context)!.settings.arguments as Reciter;

    return Container(
      decoration: BoxDecoration(
        image: DecorationImage(
          image: Assets.images.radioBackground.provider(),
          fit: BoxFit.cover,
        ),
      ),
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          centerTitle: true,
          iconTheme: const IconThemeData(color: AppColors.primaryColor),
          title: Text(
            reciter.name,
            style: Theme.of(context).textTheme.titleLarge!.copyWith(
                  color: AppColors.primaryColor,
                ),
          ),
        ),
        body: SafeArea(
          top: false,
          child: ListView.separated(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
            itemCount: reciter.surahList.length,
            separatorBuilder: (_, _) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              final sura = reciter.surahList[index];
              return _SuraRow(reciter: reciter, sura: sura);
            },
          ),
        ),
      ),
    );
  }
}

class _SuraRow extends StatelessWidget {
  final Reciter reciter;
  final int sura;

  const _SuraRow({required this.reciter, required this.sura});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.primaryColor,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              'Sura $sura',
              style: Theme.of(context).textTheme.titleLarge!.copyWith(
                    color: AppColors.titleTextColor,
                    fontSize: 16,
                  ),
            ),
          ),
          SuraDownloadControl(
            reciterId: reciter.id.toString(),
            reciterName: reciter.name,
            suraId: sura.toString(),
            url: reciter.audioUrlFor(sura),
          ),
        ],
      ),
    );
  }
}
