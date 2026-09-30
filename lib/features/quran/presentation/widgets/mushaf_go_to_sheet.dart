import 'package:flutter/material.dart';

import '../../../../core/constants/sura_names.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/formatters.dart';
import '../../domain/entities/ayah_ref.dart';
import '../bloc/mushaf/mushaf_reader_bloc.dart';

/// "Go to": a sura, a juz, a page or an ayah. Pops with the [MushafTarget].
class MushafGoToSheet extends StatelessWidget {
  final int currentPage;

  const MushafGoToSheet({super.key, required this.currentPage});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 4,
      child: Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
        ),
        child: SizedBox(
          height: MediaQuery.of(context).size.height * 0.7,
          child: Column(
            children: [
              const TabBar(
                labelColor: AppColors.primaryColor,
                indicatorColor: AppColors.primaryColor,
                unselectedLabelColor: AppColors.textColor,
                tabs: [
                  Tab(text: 'Sura'),
                  Tab(text: 'Juz'),
                  Tab(text: 'Page'),
                  Tab(text: 'Ayah'),
                ],
              ),
              Expanded(
                child: TabBarView(
                  children: [
                    const _SuraTab(),
                    const _JuzTab(),
                    _PageTab(currentPage: currentPage),
                    const _AyahTab(),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SuraTab extends StatelessWidget {
  const _SuraTab();

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      itemCount: SuraNames.all.length,
      itemBuilder: (context, i) {
        final sura = SuraNames.all[i];
        return ListTile(
          leading: Text(
            '${sura.number}',
            style: const TextStyle(color: AppColors.primaryColor),
          ),
          title: Text(
            sura.nameEn,
            style: const TextStyle(color: AppColors.textColor),
          ),
          trailing: Text(
            sura.nameAr,
            style: const TextStyle(color: AppColors.primaryColor, fontSize: 18),
          ),
          onTap: () => Navigator.pop(context, SuraTarget(sura.number)),
        );
      },
    );
  }
}

class _JuzTab extends StatelessWidget {
  const _JuzTab();

  @override
  Widget build(BuildContext context) {
    return GridView.count(
      crossAxisCount: 5,
      padding: const EdgeInsets.all(16),
      mainAxisSpacing: 8,
      crossAxisSpacing: 8,
      children: [
        for (var juz = 1; juz <= 30; juz++)
          OutlinedButton(
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.primaryColor,
              side: const BorderSide(color: AppColors.primaryColor),
              padding: EdgeInsets.zero,
            ),
            onPressed: () => Navigator.pop(context, JuzTarget(juz)),
            child: Semantics(
              label: 'Juz $juz',
              excludeSemantics: true,
              child: Text(toArabicDigits(juz), style: const TextStyle(fontSize: 18)),
            ),
          ),
      ],
    );
  }
}

/// A number field with a Go button, checked against [max].
class _NumberForm extends StatefulWidget {
  final String label;
  final int max;
  final int? initial;
  final ValueChanged<int> onGo;

  const _NumberForm({
    super.key,
    required this.label,
    required this.max,
    required this.onGo,
    this.initial,
  });

  @override
  State<_NumberForm> createState() => _NumberFormState();
}

class _NumberFormState extends State<_NumberForm> {
  late final _text = TextEditingController(
    text: widget.initial?.toString() ?? '',
  );
  String? _error;

  @override
  void dispose() {
    _text.dispose();
    super.dispose();
  }

  void _go() {
    final n = int.tryParse(_text.text.trim());
    if (n == null || n < 1 || n > widget.max) {
      setState(() => _error = 'Enter a number from 1 to ${widget.max}');
      return;
    }
    widget.onGo(n);
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: TextField(
            controller: _text,
            keyboardType: TextInputType.number,
            style: const TextStyle(color: AppColors.textColor),
            decoration: InputDecoration(
              labelText: '${widget.label} (1-${widget.max})',
              errorText: _error,
            ),
            onSubmitted: (_) => _go(),
          ),
        ),
        const SizedBox(width: 12),
        Padding(
          padding: const EdgeInsets.only(top: 8),
          child: FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.primaryColor,
              foregroundColor: AppColors.backgroundColor,
            ),
            onPressed: _go,
            child: const Text('Go'),
          ),
        ),
      ],
    );
  }
}

class _PageTab extends StatelessWidget {
  final int currentPage;

  const _PageTab({required this.currentPage});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: _NumberForm(
        label: 'Page',
        max: MushafReaderBloc.pageCount,
        initial: currentPage,
        onGo: (page) => Navigator.pop(context, PageTarget(page)),
      ),
    );
  }
}

class _AyahTab extends StatefulWidget {
  const _AyahTab();

  @override
  State<_AyahTab> createState() => _AyahTabState();
}

class _AyahTabState extends State<_AyahTab> {
  int _sura = 1;

  @override
  Widget build(BuildContext context) {
    final sura = SuraNames.all[_sura - 1];
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          DropdownButton<int>(
            value: _sura,
            isExpanded: true,
            dropdownColor: AppColors.backgroundColor,
            style: const TextStyle(color: AppColors.textColor),
            items: [
              for (final s in SuraNames.all)
                DropdownMenuItem(
                  value: s.number,
                  child: Text('${s.number}. ${s.nameEn}  ${s.nameAr}'),
                ),
            ],
            onChanged: (n) => setState(() => _sura = n ?? _sura),
          ),
          const SizedBox(height: 12),
          _NumberForm(
            // A new sura has a new range; start the field afresh.
            key: ValueKey(_sura),
            label: 'Ayah',
            max: sura.ayaCount,
            onGo: (ayah) =>
                Navigator.pop(context, AyahTarget(AyahRef(_sura, ayah))),
          ),
        ],
      ),
    );
  }
}
