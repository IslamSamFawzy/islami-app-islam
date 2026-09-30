import 'package:flutter/material.dart';

import '../../../../core/constants/sura_names.dart';
import '../../../../core/theme/app_colors.dart';
import '../../domain/entities/ayah_ref.dart';
import '../../domain/entities/mushaf_page.dart';

/// One Mushaf page laid out as print lays it out: 15 line slots, each line
/// breaking where the Mushaf breaks it and justified across the full width.
/// Nothing is reflowed; a narrower screen scales the page down.
class MushafPageWidget extends StatelessWidget {
  final MushafPage page;

  /// The ayah shown in gold, if any.
  final AyahRef? selected;

  final ValueChanged<AyahRef> onAyahTap;

  const MushafPageWidget({
    super.key,
    required this.page,
    required this.onAyahTap,
    this.selected,
  });

  /// The Mushaf's page height, in lines.
  static const int linesPerPage = 15;

  /// Page width in em of the Hafs font: the widest of the 8,820 ayah lines
  /// (page 552, line 10) with [minGapInEm] between its words. So every line
  /// is shown at the same size, none shrunk to fit (tested).
  static const double widthInEm = 21.5;

  /// The least room left between two words of a justified line.
  static const double minGapInEm = 0.15;

  static const String fontFamily = 'UthmanicHafs';

  /// Height of a line of words, in em: room for the marks above and below.
  static const double lineHeightInEm = 1.6;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        final fontSize = width / widthInEm;
        // Each of the 15 lines gets the same slot, as on paper; pages 1 and 2
        // have fewer lines and sit in the middle.
        final lineHeight = constraints.maxHeight.isFinite
            ? constraints.maxHeight / linesPerPage
            : fontSize * 2.2;
        final short = page.lines.length < linesPerPage;
        return Column(
          mainAxisAlignment:
              short ? MainAxisAlignment.center : MainAxisAlignment.start,
          children: [
            for (final line in page.lines)
              SizedBox(
                width: width,
                height: lineHeight,
                child: _line(line, fontSize),
              ),
          ],
        );
      },
    );
  }

  Widget _line(MushafLine line, double fontSize) {
    return switch (line) {
      SuraHeaderLine(:final sura) => _SuraHeader(sura: sura, fontSize: fontSize),
      BasmalaLine(:final words) => _Line(
        centered: true,
        children: [for (final w in words) _text(w, fontSize, selected: false)],
      ),
      AyahLine(:final words, :final centered) => _Line(
        centered: centered,
        children: _ayahLine(
          [for (final w in words) if (w.kind != MushafWordKind.empty) w],
          fontSize,
          centered: centered,
        ),
      ),
    };
  }

  /// The words of a line. On a justified line the space between two words
  /// stretches, and a tap there counts for the ayah of the word before it,
  /// so no part of the line is dead to the finger.
  List<Widget> _ayahLine(
    List<MushafWord> words,
    double fontSize, {
    required bool centered,
  }) {
    if (centered) return [for (final w in words) _word(w, fontSize)];
    final pad = EdgeInsets.symmetric(horizontal: fontSize * minGapInEm / 2);
    return [
      for (var i = 0; i < words.length; i++) ...[
        if (i > 0)
          Expanded(
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: () =>
                  onAyahTap(AyahRef(words[i - 1].sura, words[i - 1].ayah)),
              // As tall as the words: the line's height is theirs.
              child: SizedBox(height: fontSize * lineHeightInEm),
            ),
          ),
        Padding(padding: pad, child: _word(words[i], fontSize)),
      ],
    ];
  }

  Widget _word(MushafWord word, double fontSize) {
    final ref = AyahRef(word.sura, word.ayah);
    final isSelected = ref == selected;
    Widget child = _text(word.text, fontSize, selected: isSelected);
    if (word.kind == MushafWordKind.ayahEnd) {
      child = Semantics(
        label: 'Sura ${SuraNames.all[word.sura - 1].nameEn}, ayah ${word.ayah}',
        button: true,
        excludeSemantics: true,
        child: child,
      );
    }
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () => onAyahTap(ref),
      child: child,
    );
  }

  Widget _text(String text, double fontSize, {required bool selected}) {
    final label = Text(
      text,
      textDirection: TextDirection.rtl,
      softWrap: false,
      style: TextStyle(
        fontFamily: fontFamily,
        fontSize: fontSize,
        height: lineHeightInEm,
        color: selected ? AppColors.backgroundColor : AppColors.primaryColor,
      ),
    );
    if (!selected) return label;
    // The app's gold highlight: gold fill, dark text.
    return DecoratedBox(
      decoration: BoxDecoration(
        color: AppColors.primaryColor,
        borderRadius: BorderRadius.circular(fontSize * 0.2),
      ),
      child: label,
    );
  }
}

/// A line of words: spread across the width like print, or centred.
class _Line extends StatelessWidget {
  final bool centered;
  final List<Widget> children;

  const _Line({required this.centered, required this.children});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final row = Row(
          textDirection: TextDirection.rtl,
          mainAxisSize: centered ? MainAxisSize.min : MainAxisSize.max,
          mainAxisAlignment: centered
              ? MainAxisAlignment.center
              : MainAxisAlignment.start,
          crossAxisAlignment: CrossAxisAlignment.center,
          spacing: centered ? constraints.maxWidth / 60 : 0,
          children: children,
        );
        // A justified line is as wide as the page, or as its words if they
        // are wider; then it is scaled down, never wrapped: the line break is
        // the Mushaf's.
        return FittedBox(
          fit: BoxFit.scaleDown,
          child: centered
              ? row
              : ConstrainedBox(
                  constraints: BoxConstraints(minWidth: constraints.maxWidth),
                  child: IntrinsicWidth(child: row),
                ),
        );
      },
    );
  }
}

/// The sura's name in a gold frame, where the Mushaf prints its header.
class _SuraHeader extends StatelessWidget {
  final int sura;
  final double fontSize;

  const _SuraHeader({required this.sura, required this.fontSize});

  @override
  Widget build(BuildContext context) {
    final name = SuraNames.all[sura - 1];
    return Semantics(
      header: true,
      label: 'Sura ${name.nameEn}, ${name.nameAr}',
      excludeSemantics: true,
      child: Container(
        margin: EdgeInsets.symmetric(vertical: fontSize * 0.2),
        decoration: BoxDecoration(
          border: Border.all(color: AppColors.primaryColor, width: 1.5),
          borderRadius: BorderRadius.circular(fontSize * 0.4),
        ),
        alignment: Alignment.center,
        child: FittedBox(
          fit: BoxFit.scaleDown,
          // The sura-name font draws "surah002" as Al-Baqarah's name.
          child: Text(
            'surah${sura.toString().padLeft(3, '0')}',
            style: TextStyle(
              fontFamily: 'SurahName',
              fontSize: fontSize * 1.6,
              height: 1.2,
              color: AppColors.primaryColor,
            ),
          ),
        ),
      ),
    );
  }
}
