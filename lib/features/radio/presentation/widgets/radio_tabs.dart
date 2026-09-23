import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/theme/app_colors.dart';
import '../bloc/radio_bloc.dart';

/// Toggles between the Radio and Reciters tabs.
class RadioTabs extends StatelessWidget {
  const RadioTabs({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<RadioBloc, RadioState>(
      buildWhen: (a, b) => a.tab != b.tab,
      builder: (context, state) {
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            children: [
              Expanded(
                child: _TabButton(
                  label: 'Radio',
                  selected: state.tab == RadioTab.radio,
                  onTap: () => context.read<RadioBloc>().add(
                    const SelectTabEvent(RadioTab.radio),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _TabButton(
                  label: 'Reciters',
                  selected: state.tab == RadioTab.reciters,
                  onTap: () => context.read<RadioBloc>().add(
                    const SelectTabEvent(RadioTab.reciters),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _TabButton extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _TabButton({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: selected ? AppColors.primaryColor : Colors.transparent,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.primaryColor),
        ),
        child: Text(
          label,
          // Both states use Janna (theme font); only the colour changes so the
          // unselected tab never falls back to Arial (Figma comment #6).
          style: Theme.of(context).textTheme.bodyLarge!.copyWith(
            color: selected ? AppColors.titleTextColor : AppColors.textColor,
          ),
        ),
      ),
    );
  }
}
