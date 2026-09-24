import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../domain/entities/sura.dart';
import 'bloc/quran_bloc.dart';
import 'pages/quran_details_view.dart';

/// Marks [sura] as recently read and opens it.
///
/// Both ways into a sura — the list and the Most Recently cards — go through
/// here, so "opening a sura" cannot come to mean two different things.
void openSura(BuildContext context, Sura sura) {
  context.read<QuranBloc>().add(MarkSuraAsReadEvent(sura));
  Navigator.pushNamed(context, QuranDetailsView.routeName, arguments: sura);
}
