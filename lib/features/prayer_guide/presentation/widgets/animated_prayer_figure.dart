import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../domain/entities/prayer_posture.dart';
import '../animation/pose.dart';
import '../animation/posture_poses.dart';
import 'prayer_figure_painter.dart';

/// Loops the figure through [postures]: it holds each posture for [hold],
/// then eases into the next one over [transition], and wraps back to the
/// first. A single posture is drawn still. Respects the platform's
/// "reduce motion" setting by showing the first posture only.
///
/// [postures] must not be empty (the content parser guarantees this).
class AnimatedPrayerFigure extends StatefulWidget {
  final List<PrayerPosture> postures;
  final Duration hold;
  final Duration transition;
  final String? semanticsLabel;

  const AnimatedPrayerFigure({
    super.key,
    required this.postures,
    this.hold = const Duration(milliseconds: 900),
    this.transition = const Duration(milliseconds: 800),
    this.semanticsLabel,
  });

  @override
  State<AnimatedPrayerFigure> createState() => _AnimatedPrayerFigureState();
}

class _AnimatedPrayerFigureState extends State<AnimatedPrayerFigure>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  bool? _reduceMotionSetting;

  bool get _reduceMotion => _reduceMotionSetting ?? false;

  Duration get _cycle => (widget.hold + widget.transition) * widget.postures.length;

  bool get _shouldAnimate => widget.postures.length > 1 && !_reduceMotion;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: _cycle);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final reduce = MediaQuery.maybeDisableAnimationsOf(context) ?? false;
    // Only (re)start when the setting actually changes — other dependency
    // changes (theme, insets) must not reset the loop.
    if (reduce != _reduceMotionSetting) {
      _reduceMotionSetting = reduce;
      _restart();
    }
  }

  @override
  void didUpdateWidget(covariant AnimatedPrayerFigure oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!listEquals(oldWidget.postures, widget.postures) ||
        oldWidget.hold != widget.hold ||
        oldWidget.transition != widget.transition) {
      _controller.duration = _cycle;
      _restart();
    }
  }

  void _restart() {
    _controller.reset();
    if (_shouldAnimate) _controller.repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  /// The blended pose at [progress] (0..1) of one full cycle.
  Pose _poseAt(double progress) {
    final postures = widget.postures;
    if (!_shouldAnimate) return PosturePoses.of(postures.first);

    final holdMs = widget.hold.inMilliseconds;
    final transitionMs = widget.transition.inMilliseconds;
    final stepMs = holdMs + transitionMs;
    final elapsed = progress * stepMs * postures.length;
    final index = (elapsed ~/ stepMs).clamp(0, postures.length - 1);
    final local = elapsed - index * stepMs;

    final from = PosturePoses.of(postures[index]);
    if (local <= holdMs || transitionMs == 0) return from;

    final to = PosturePoses.of(postures[(index + 1) % postures.length]);
    final t = ((local - holdMs) / transitionMs).clamp(0.0, 1.0);
    return Pose.lerp(from, to, Curves.easeInOut.transform(t));
  }

  @override
  Widget build(BuildContext context) {
    final labelStyle = Theme.of(context).textTheme.bodyMedium!.copyWith(
      color: AppColors.textColor,
    );
    return Semantics(
      label: widget.semanticsLabel,
      image: true,
      child: RepaintBoundary(
        child: AnimatedBuilder(
          animation: _controller,
          builder: (context, _) => CustomPaint(
            size: Size.infinite,
            painter: PrayerFigurePainter(
              pose: _poseAt(_controller.value),
              color: AppColors.primaryColor,
              farColor: Color.lerp(
                AppColors.primaryColor,
                AppColors.backgroundColor,
                0.45,
              )!,
              matColor: AppColors.primaryColor.withValues(alpha: 0.28),
              labelStyle: labelStyle,
            ),
          ),
        ),
      ),
    );
  }
}
