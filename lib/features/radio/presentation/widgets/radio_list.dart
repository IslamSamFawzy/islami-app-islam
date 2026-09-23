import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../bloc/radio_bloc.dart';
import '../widgets/station_tile.dart';
import 'radio_empty_state.dart';

/// The list of radio stations for the active search query.
class RadioList extends StatelessWidget {
  final RadioState state;

  const RadioList({super.key, required this.state});

  @override
  Widget build(BuildContext context) {
    if (state.radios.isEmpty) {
      return const RadioEmptyHint(text: 'No radios available');
    }
    final radios = state.filteredRadios;
    if (radios.isEmpty) return const RadioNoResults();
    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
      itemCount: radios.length,
      separatorBuilder: (context, index) => const SizedBox(height: 14),
      itemBuilder: (context, index) {
        final station = radios[index];
        final id = 'radio_${station.id}';
        return StationTile(
          name: station.name,
          isPlaying: state.currentId == id && state.isPlaying,
          onPlayPause: () => context.read<RadioBloc>().add(
            PlayItemEvent(id: id, url: station.url),
          ),
        );
      },
    );
  }
}
