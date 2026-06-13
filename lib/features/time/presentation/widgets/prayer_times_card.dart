import 'package:carousel_slider/carousel_slider.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../../core/theme/app_colors.dart';
import '../../domain/entities/prayer_times.dart';

/// A self-contained "Pray Time" card:
///   * one continuous amber shape with a smooth wavy (scalloped) top, drawn by
///     [_ScallopClipper], holding the gregorian date, title and hijri date,
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
    // One continuous amber shape with a smooth wavy (scalloped) top, drawn by
    // _ScallopClipper. PhysicalShape fills it with the amber colour and casts a
    // soft shadow that follows the wavy outline.
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: PhysicalShape(
        clipper: _ScallopClipper(),
        clipBehavior: Clip.antiAlias,
        color: AppColors.primaryColor.withValues(alpha: 0.92),
        elevation: 6,
        shadowColor: Colors.black45,
        child: Column(
          children: [
            // Top wavy area: gregorian date | title | hijri date.
            Padding(
              padding: const EdgeInsets.fromLTRB(18, 14, 18, 0),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _DateLabel(
                    line1: times.gregorianDate,
                    line2: times.gregorianYear,
                  ),
                  Expanded(
                    child: Column(
                      children: [
                        Text(
                          'Pray Time',
                          style: Theme.of(context).textTheme.titleLarge!
                              .copyWith(color: AppColors.titleTextColor),
                        ),
                        Text(
                          times.weekday,
                          style: Theme.of(context).textTheme.bodyLarge!
                              .copyWith(color: AppColors.titleTextColor),
                        ),
                      ],
                    ),
                  ),
                  _DateLabel(line1: times.hijriDate, line2: times.hijriYear),
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
            const SizedBox(height: 12),
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
            const SizedBox(height: 16),
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

/// Draws the card outline: rounded bottom corners + a smooth wavy top with
/// three humps (left date, center title, right date) separated by two valleys.
/// Tweak [_valleyDepth] for deeper/shallower dips and the `0.27 / 0.37 / 0.63 /
/// 0.73` fractions to move the valleys horizontally.
class _ScallopClipper extends CustomClipper<Path> {
  static const double _radius = 26; // outer corner radius
  static const double _valleyDepth = 52; // how far the dips drop from the top

  @override
  Path getClip(Size size) {
    final w = size.width;
    final h = size.height;
    // Control-point depth so the cubic dip bottoms out near _valleyDepth.
    const cy = _valleyDepth * 1.35;

    return Path()
      ..moveTo(0, _radius)
      ..quadraticBezierTo(0, 0, _radius, 0)
      // flat top across the left date hump
      ..lineTo(w * 0.27, 0)
      // valley 1
      ..cubicTo(w * 0.31, cy, w * 0.33, cy, w * 0.37, 0)
      // flat top across the center title dome
      ..lineTo(w * 0.63, 0)
      // valley 2
      ..cubicTo(w * 0.67, cy, w * 0.69, cy, w * 0.73, 0)
      // flat top across the right date hump
      ..lineTo(w - _radius, 0)
      ..quadraticBezierTo(w, 0, w, _radius)
      // right side down + rounded bottom corners
      ..lineTo(w, h - _radius)
      ..quadraticBezierTo(w, h, w - _radius, h)
      ..lineTo(_radius, h)
      ..quadraticBezierTo(0, h, 0, h - _radius)
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
    return Column(
      children: [
        Text(
          '$line1,',
          style: const TextStyle(
            color: AppColors.titleTextColor,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          line2,
          style: const TextStyle(
            color: AppColors.titleTextColor,
            fontWeight: FontWeight.bold,
          ),
        ),
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
                fontSize: selected ? 15 : 12,
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
                fontSize: selected ? 13 : 11,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
