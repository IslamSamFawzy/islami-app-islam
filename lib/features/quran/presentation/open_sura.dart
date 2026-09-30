import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../domain/entities/sura.dart';
import 'bloc/quran_bloc.dart';
import 'pages/mushaf_reader_view.dart';

/// Marks [sura] as recently read and opens the Mushaf on it.
///
/// Both ways into a sura go through here: the list opens it at its first
/// page, the Most Recently cards pass [resume] so it opens where the reader
/// stopped. The reader can page on into other suras, so the recents are
/// reloaded when it closes.
void openSura(BuildContext context, Sura sura, {bool resume = false}) {
  final bloc = context.read<QuranBloc>()..add(MarkSuraAsReadEvent(sura));
  Navigator.pushNamed(
    context,
    MushafReaderView.routeName,
    arguments: MushafReaderArgs(sura.id, resume: resume),
  ).then((_) {
    if (!bloc.isClosed) bloc.add(const LoadRecentSurasEvent());
  });
}
