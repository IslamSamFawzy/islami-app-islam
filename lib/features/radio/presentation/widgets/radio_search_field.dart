import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/widgets/search_field.dart';
import '../bloc/radio_bloc.dart';

/// The search field above the tabs. Owns its controller so the text can be
/// cleared when the tab switches; its hint follows the active tab.
class RadioSearchField extends StatefulWidget {
  const RadioSearchField({super.key});

  @override
  State<RadioSearchField> createState() => _RadioSearchFieldState();
}

class _RadioSearchFieldState extends State<RadioSearchField> {
  final _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<RadioBloc, RadioState>(
      buildWhen: (a, b) => a.tab != b.tab,
      listenWhen: (a, b) => a.tab != b.tab,
      // The bloc already cleared the query on tab switch; clear the text too.
      listener: (context, state) => _controller.clear(),
      builder: (context, state) => SearchField(
        controller: _controller,
        hintText: state.tab == RadioTab.radio
            ? 'Search stations'
            : 'Search reciters',
        onChanged: (value) =>
            context.read<RadioBloc>().add(SearchRadioEvent(value)),
      ),
    );
  }
}
