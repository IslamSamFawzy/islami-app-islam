import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/di/service_locator.dart';
import '../../../../core/gen/assets.gen.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/app_background.dart';
import '../../../../core/widgets/error_view.dart';
import '../../../../core/widgets/header_logo.dart';
import '../../../../core/widgets/loading_view.dart';
import '../../../../core/widgets/notice_listener.dart';
import '../../../../core/widgets/offline_banner.dart';
import '../../../downloads/presentation/pages/downloads_view.dart';
import '../bloc/radio_bloc.dart';
import '../widgets/radio_list.dart';
import '../widgets/radio_search_field.dart';
import '../widgets/radio_tabs.dart';
import '../widgets/reciter_list.dart';

class RadioView extends StatelessWidget {
  const RadioView({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => sl<RadioBloc>()..add(const LoadRadioDataEvent()),
      child: const _RadioViewBody(),
    );
  }
}

class _RadioViewBody extends StatelessWidget {
  const _RadioViewBody();

  @override
  Widget build(BuildContext context) {
    return AppBackground(
      image: Assets.images.radioBackground,
      child: NoticeListener<RadioBloc, RadioState>(
        noticeOf: (state) => state.notice,
        child: Column(
          children: [
            Stack(
              children: [
                const HeaderLogo(widthFactor: 0.55),
                Positioned.fill(
                  child: Align(
                    alignment: Alignment.centerRight,
                    child: IconButton(
                      tooltip: 'Downloads',
                      icon: const Icon(
                        Icons.download_for_offline_outlined,
                        color: AppColors.primaryColor,
                      ),
                      onPressed: () => Navigator.pushNamed(
                        context,
                        DownloadsView.routeName,
                      ),
                    ),
                  ),
                ),
              ],
            ),
            BlocBuilder<RadioBloc, RadioState>(
              buildWhen: (a, b) => a.showOfflineBanner != b.showOfflineBanner,
              builder: (context, state) => state.showOfflineBanner
                  ? const OfflineBanner()
                  : const SizedBox.shrink(),
            ),
            const SizedBox(height: 10),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 16),
              child: RadioSearchField(),
            ),
            const SizedBox(height: 12),
            const RadioTabs(),
            const SizedBox(height: 12),
            Expanded(
              child: BlocBuilder<RadioBloc, RadioState>(
                builder: (context, state) {
                  if (state.status.isBusy) return const LoadingView();
                  if (state.status.isFailure) {
                    return ErrorView(
                      message: state.errorMessage,
                      padding: const EdgeInsets.all(24),
                    );
                  }
                  return state.tab == RadioTab.radio
                      ? RadioList(state: state)
                      : RecitersList(state: state);
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
