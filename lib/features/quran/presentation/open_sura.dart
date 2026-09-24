import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../domain/entities/sura.dart';
import 'bloc/quran_bloc.dart';
import 'pages/quran_details_view.dart';

/// Marks [sura] as recently read and opens it.
///
/// Both ways into a sura go through here: the list opens it at the top, the
/// Most Recently cards pass [resume] so it opens where the reader stopped.
void openSura(BuildContext context, Sura sura, {bool resume = false}) {
  context.read<QuranBloc>().add(MarkSuraAsReadEvent(sura));
  Navigator.pushNamed(
    context,
    QuranDetailsView.routeName,
    arguments: QuranDetailsArgs(sura, resume: resume),
  );
}
