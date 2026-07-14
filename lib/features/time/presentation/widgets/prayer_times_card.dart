import 'package:carousel_slider/carousel_slider.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../../core/theme/app_colors.dart';
import '../../domain/entities/prayer_times.dart';

/// A self-contained "Pray Time" card:
///   * one continuous amber shape with a smooth wavy top, drawn by
///     [_ScallopClipper]: a broad gentle centre dome flanked by two shallow,
///     smooth notches, holding the gregorian date, title and hijri date,
///   * an infinite prayer carousel where the centered prayer "pops out",
///   * a "Next Pray" countdown row with a mute toggle.
///
/// It is decoupled from any bloc — pass it the data and callbacks it needs so
/// it can be reused anywhere.
class PrayerTimesCard extends StatefulWidget {
  /// Today's schedule + the gregorian/hijri date labels.
  final PrayerTimes prayerTimes;

  /// Name of the next upcoming prayer — the carousel starts centered on it and
  /// it is the only one that stays highlighted.
  final String? nextPrayerName;

  /// Countdown shown in the "Next Pray - HH:MM" row.
  final Duration countdown;

  /// Whether the mute icon shows the muted state.
  final bool muted;

  /// Called when the user taps the mute icon. If null, the icon is not tappable.
  final VoidCallback? onToggleMute;

  const PrayerTimesCard({
    super.key,
    required this.prayerTimes,
    this.nextPrayerName,
    this.countdown = Duration.zero,
    this.muted = false,
    this.onToggleMute,
  });

  @override
  State<PrayerTimesCard> createState() => _PrayerTimesCardState();
}

class _PrayerTimesCardState extends State<PrayerTimesCard> {
  late final CarouselSliderController _carouselController;
  late int _currentIndex;

  @override
  void initState() {
    super.initState();
    _carouselController = CarouselSliderController();
    // Start centered on the next upcoming prayer (falls back to the first).
    final prayers = widget.prayerTimes.prayers;
    final next = prayers.indexWhere((p) => p.name == widget.nextPrayerName);
    _currentIndex = next < 0 ? 0 : next;
  }

  @override
  Widget build(BuildContext context) {
    final times = widget.prayerTimes;
    // One continuous amber shape with a smooth wavy top, drawn by
    // _ScallopClipper. PhysicalShape fills it with the amber colour and casts a
    // soft shadow that follows the wavy outline.
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: PhysicalShape(
        clipper: _ScallopClipper(),
        clipBehavior: Clip.antiAlias,
        color: AppColors.primaryColor.withValues(alpha: 0.92),
        elevation: 6,
        shadowColor: Colors.black45,
        child: Column(
          children: [
            // Top wavy area: gregorian date | title | hijri date. The dates sit
            // a touch lower (in the corner shoulders); the title rides the dome.
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.only(top: 6),
                    child: _DateLabel(
                      line1: times.gregorianDate,
                      line2: times.gregorianYear,
                    ),
                  ),
                  Expanded(
                    child: Column(
                      children: [
                        Text(
                          'Pray Time',
                          style: Theme.of(context).textTheme.titleLarge!
                              .copyWith(color: AppColors.titleTextColor),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          times.weekday,
                          style: Theme.of(context).textTheme.bodyLarge!
                              .copyWith(
                                color: AppColors.titleTextColor,
                                fontSize: 18,
                              ),
                        ),
                      ],
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.only(top: 6),
                    child: _DateLabel(
                      line1: times.hijriDate,
                      line2: times.hijriYear,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),
            // Prayer list — infinite (no start/end), the centered card
            // "pops out" (taller + dark gradient), sides stay short.
            CarouselSlider.builder(
              carouselController: _carouselController,
              itemCount: times.prayers.length,
              options: CarouselOptions(
                height: 150,
                viewportFraction: 0.28,
                enlargeCenterPage: true,
                enlargeFactor: 0.45,
                enlargeStrategy: CenterPageEnlargeStrategy.height,
                enableInfiniteScroll: true,
                initialPage: _currentIndex,
                onPageChanged: (index, _) =>
                    setState(() => _currentIndex = index),
              ),
              itemBuilder: (context, index, _) {
                final prayer = times.prayers[index];
                return GestureDetector(
                  onTap: () => _carouselController.animateToPage(index),
                  child: _PrayerPill(
                    prayer: prayer,
                    selected: index == _currentIndex,
                  ),
                );
              },
            ),
            const SizedBox(height: 14),
            // Next prayer + mute.
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  'Next Pray - ${_formatCountdown(widget.countdown)}',
                  style: Theme.of(context).textTheme.bodyLarge!.copyWith(
                    color: AppColors.titleTextColor,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(width: 8),
                GestureDetector(
                  onTap: widget.onToggleMute,
                  child: Icon(
                    widget.muted ? Icons.volume_off : Icons.volume_up,
                    color: AppColors.titleTextColor,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  String _formatCountdown(Duration d) {
    final clamped = d.isNegative ? Duration.zero : d;
    final h = clamped.inHours.toString().padLeft(2, '0');
    final m = (clamped.inMinutes % 60).toString().padLeft(2, '0');
    return '$h:$m';
  }
}

/// Draws the card outline: rounded bottom corners + a smooth wavy top that is a
/// single broad, gentle centre dome flanked by two shallow concave notches
/// (the date labels sit on the lower corner shoulders on either side).
///
/// Every top-edge junction uses a horizontal control tangent, so the whole
/// silhouette is one continuous, crease-free wave. Tune the four geometry
/// constants below against the Figma frame:
///   * [_shoulderDrop]  — how far the corner shoulders sit below the apex.
///   * [_notchDepth]    — how deep the two notches dip below the apex.
///   * [_notchAxis]     — horizontal centre of the notches (fraction of width).
///   * [_notchHalfWidth]— half-width of each notch (fraction of width).
class _ScallopClipper extends CustomClipper<Path> {
  static const double _radius = 26; // outer corner radius
  static const double _shoulderDrop = 8; // corners this far below the apex
  static const double _notchDepth = 26; // notch floors this far below the apex
  static const double _notchAxis = 0.29; // notch centre (0..1 of the width)
  static const double _notchHalfWidth = 0.09; // half a notch, as a fraction

  @override
  Path getClip(Size size) {
    final w = size.width;
    final h = size.height;

    const r = _radius;
    const sy = _shoulderDrop; // shoulder y
    const ny = _notchDepth; // notch-floor y (apex is y = 0)

    final nl = _notchAxis * w; // left notch centre
    final nr = (1 - _notchAxis) * w; // right notch centre
    final nh = _notchHalfWidth * w; // notch half-width
    final domeL = nl + nh; // dome starts (left)
    final domeR = nr - nh; // dome ends (right)
    final apexX = 0.5 * w;
    final co = nh * 0.5; // notch control-point x offset
    final domeCo = (apexX - domeL) * 0.5; // dome control-point x offset

    return Path()
      ..moveTo(0, sy + r)
      ..quadraticBezierTo(0, sy, r, sy) // top-left corner
      ..lineTo(nl - nh, sy) // left shoulder
      // left notch: dip down to the floor, then back up (smooth U)
      ..cubicTo(nl - nh + co, sy, nl - co, ny, nl, ny)
      ..cubicTo(nl + co, ny, nl + nh - co, sy, domeL, sy)
      // centre dome: rise to the apex and back down
      ..cubicTo(domeL + domeCo, sy, apexX - domeCo, 0, apexX, 0)
      ..cubicTo(apexX + domeCo, 0, domeR - domeCo, sy, domeR, sy)
      // right notch: mirror of the left
      ..cubicTo(nr - nh + co, sy, nr - co, ny, nr, ny)
      ..cubicTo(nr + co, ny, nr + nh - co, sy, nr + nh, sy)
      ..lineTo(w - r, sy) // right shoulder
      ..quadraticBezierTo(w, sy, w, sy + r) // top-right corner
      ..lineTo(w, h - r)
      ..quadraticBezierTo(w, h, w - r, h) // bottom-right corner
      ..lineTo(r, h)
      ..quadraticBezierTo(0, h, 0, h - r) // bottom-left corner
      ..close();
  }

  @override
  bool shouldReclip(covariant CustomClipper<Path> oldClipper) => false;
}

class _DateLabel extends StatelessWidget {
  final String line1;
  final String line2;

  const _DateLabel({required this.line1, required this.line2});

  @override
  Widget build(BuildContext context) {
    final style = Theme.of(context).textTheme.bodyMedium!.copyWith(
      color: AppColors.titleTextColor,
      fontSize: 13,
      fontWeight: FontWeight.bold,
    );
    return Column(
      children: [
        Text('$line1,', style: style),
        Text(line2, style: style),
      ],
    );
  }
}

class _PrayerPill extends StatelessWidget {
  final Prayer prayer;
  final bool selected;

  const _PrayerPill({required this.prayer, required this.selected});

  @override
  Widget build(BuildContext context) {
    // This container fills the carousel slot height (the center slot is tall,
    // the side slots are short). The content is bottom-aligned so the taller
    // center card visually pops up above the shorter side cards, and the
    // FittedBox keeps the content from overflowing when a slot is short.
    return AnimatedContainer(
      duration: const Duration(milliseconds: 250),
      curve: Curves.easeOut,
      margin: const EdgeInsets.symmetric(horizontal: 4),
      alignment: Alignment.bottomCenter,
      padding: EdgeInsets.symmetric(
        vertical: selected ? 18 : 12,
        horizontal: 6,
      ),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: selected
              ? const [Color(0xff5A4F3D), Color(0xff262019), Color(0xff060504)]
              : const [Color(0xff2A2218), Color(0xff0A0805)],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: AppColors.backgroundColor.withValues(alpha: 0.4),
        ),
        boxShadow: selected
            ? const [
                BoxShadow(
                  color: Colors.black45,
                  blurRadius: 14,
                  offset: Offset(0, 6),
                ),
              ]
            : null,
      ),
      // FittedBox guarantees the content always fits the card height, even
      // when the carousel compresses the side cards (prevents overflow).
      child: FittedBox(
        fit: BoxFit.scaleDown,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              prayer.name,
              style: TextStyle(
                color: selected ? Colors.white : Colors.white70,
                fontWeight: FontWeight.bold,
                fontSize: selected ? 13 : 12,
              ),
            ),
            SizedBox(height: selected ? 10 : 6),
            Text(
              DateFormat('hh:mm').format(prayer.time),
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: selected ? 24 : 16,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              DateFormat('a').format(prayer.time),
              style: TextStyle(
                color: selected ? Colors.white : Colors.white70,
                fontSize: selected ? 12 : 11,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
