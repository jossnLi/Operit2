import 'dart:math' as math;

import 'package:flutter/material.dart';

/// Animated placeholders shown inside the AI bubble before the first token.
enum AiTypingStyle {
  dots,
  sparkle,
  skeleton,
  textCursor,
  waveform,
  orbit,
  none;

  /// Decodes one stored preference value, falling back to the default style.
  static AiTypingStyle fromStorageName(String? value) {
    for (final style in AiTypingStyle.values) {
      if (style.name == value) {
        return style;
      }
    }
    return AiTypingStyle.dots;
  }
}

/// Renders the waiting-for-reply placeholder selected in the appearance page.
///
/// Every style derives its color from [color] so it follows the bubble text
/// color of the active theme, and collapses to a static frame when the platform
/// reports `MediaQuery.disableAnimations`.
class AiTypingIndicator extends StatefulWidget {
  const AiTypingIndicator({
    super.key,
    required this.style,
    required this.color,
    this.label,
    this.showLabel = true,
    this.scale = 1,
  });

  final AiTypingStyle style;
  final Color color;
  final String? label;
  final bool showLabel;
  final double scale;

  @override
  State<AiTypingIndicator> createState() => _AiTypingIndicatorState();
}

class _AiTypingIndicatorState extends State<AiTypingIndicator>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1150),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.style == AiTypingStyle.none) {
      return const SizedBox.shrink();
    }
    final reduceMotion =
        MediaQuery.maybeOf(context)?.disableAnimations ?? false;
    final Widget motion = reduceMotion
        ? _motion(enter: false)
        : AnimatedBuilder(
            animation: _controller,
            builder: (context, _) => _motion(enter: true),
          );
    final bool showText =
        widget.showLabel &&
        widget.label != null &&
        widget.label!.trim().isNotEmpty &&
        widget.style != AiTypingStyle.textCursor;
    if (!showText) {
      return motion;
    }
    return Row(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: <Widget>[
        motion,
        SizedBox(width: 7 * widget.scale),
        Text(
          widget.label!,
          style: TextStyle(
            fontSize: 12.5 * widget.scale,
            height: 1.1,
            color: widget.color.withValues(alpha: 0.62),
            letterSpacing: 0.2,
          ),
        ),
      ],
    );
  }

  /// Builds the animated mark for the active style.
  Widget _motion({required bool enter}) {
    switch (widget.style) {
      case AiTypingStyle.sparkle:
        return _sparkle(enter);
      case AiTypingStyle.skeleton:
        return _skeleton(enter);
      case AiTypingStyle.textCursor:
        return _textCursor(enter);
      case AiTypingStyle.waveform:
        return _waveform(enter);
      case AiTypingStyle.orbit:
        return _orbit(enter);
      case AiTypingStyle.dots:
      case AiTypingStyle.none:
        return _dots(enter);
    }
  }

  /// Three dots riding one staggered wave, the closest read of "typing".
  Widget _dots(bool enter) {
    const int count = 3;
    final double size = 6 * widget.scale;
    return SizedBox(
      height: size + 6 * widget.scale,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: <Widget>[
          for (var index = 0; index < count; index++)
            Padding(
              padding: EdgeInsetsDirectional.only(
                start: index == 0 ? 0 : 5 * widget.scale,
              ),
              child: _dot(index, enter: enter, size: size),
            ),
        ],
      ),
    );
  }

  /// One dot peaks in sequence so the row reads as motion, not a spinner.
  Widget _dot(int index, {required bool enter, required double size}) {
    final progress = enter
        ? (_controller.value + index * 0.16) % 1.0
        : (index == 1 ? 0.5 : 0.2);
    final wave = progress < 0.5 ? progress * 2 : (1 - progress) * 2;
    return Transform.translate(
      offset: Offset(0, -1.6 * wave * widget.scale),
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: widget.color.withValues(alpha: 0.35 + 0.65 * wave),
          shape: BoxShape.circle,
        ),
      ),
    );
  }

  /// A slowly rotating four-point star with a breathing halo.
  Widget _sparkle(bool enter) {
    final double t = enter ? _controller.value : 0.25;
    final double size = 17 * widget.scale;
    final double pulse = 0.5 + 0.5 * math.sin(t * math.pi * 2);
    return Transform.rotate(
      angle: t * math.pi * 2,
      child: Opacity(
        opacity: 0.5 + 0.5 * pulse,
        child: SizedBox(
          width: size,
          height: size,
          child: CustomPaint(painter: _SparklePainter(color: widget.color)),
        ),
      ),
    );
  }

  /// A short placeholder line that a highlight sweeps across.
  Widget _skeleton(bool enter) {
    final double t = enter ? _controller.value : 0.5;
    final double width = 54 * widget.scale;
    final double height = 12 * widget.scale;
    return ClipRRect(
      borderRadius: BorderRadius.circular(height / 2),
      child: SizedBox(
        width: width,
        height: height,
        child: DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment(-1.0 + t * 2.4, 0),
              end: Alignment(0.2 + t * 2.4, 0),
              colors: <Color>[
                widget.color.withValues(alpha: 0.08),
                widget.color.withValues(alpha: 0.26),
                widget.color.withValues(alpha: 0.08),
              ],
              stops: const <double>[0.0, 0.5, 1.0],
            ),
          ),
        ),
      ),
    );
  }

  /// A terminal-style label with a blinking caret.
  Widget _textCursor(bool enter) {
    final bool caretOn = enter ? _controller.value < 0.55 : true;
    final String text = widget.label?.trim().isNotEmpty == true
        ? widget.label!
        : '…';
    return SizedBox(
      height: 17 * widget.scale,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: <Widget>[
          if (widget.showLabel)
            Text(
              text,
              style: TextStyle(
                fontSize: 12.5 * widget.scale,
                height: 1.1,
                color: widget.color.withValues(alpha: 0.66),
                letterSpacing: 0.2,
              ),
            ),
          if (widget.showLabel) SizedBox(width: 2 * widget.scale),
          Container(
            width: 1.8 * widget.scale,
            height: 13 * widget.scale,
            decoration: BoxDecoration(
              color: caretOn
                  ? widget.color.withValues(alpha: 0.85)
                  : Colors.transparent,
              borderRadius: BorderRadius.circular(1),
            ),
          ),
        ],
      ),
    );
  }

  /// Five thin bars breathing out of phase, a small voice-assistant meter.
  Widget _waveform(bool enter) {
    const int count = 5;
    final double t = enter ? _controller.value : 0.35;
    return SizedBox(
      height: 15 * widget.scale,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: <Widget>[
          for (var index = 0; index < count; index++)
            Padding(
              padding: EdgeInsetsDirectional.only(
                start: index == 0 ? 0 : 3 * widget.scale,
              ),
              child: Container(
                width: 2.6 * widget.scale,
                height:
                    (4 + 8 * (0.5 + 0.5 * math.sin(
                          (t + index * 0.18) * math.pi * 2,
                        ))) *
                    widget.scale,
                decoration: BoxDecoration(
                  color: widget.color.withValues(alpha: 0.72),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
        ],
      ),
    );
  }

  /// One light point travelling an ellipse with a short fading trail.
  Widget _orbit(bool enter) {
    final double t = enter ? _controller.value : 0.3;
    final double size = 18 * widget.scale;
    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(
        painter: _OrbitPainter(color: widget.color, progress: t),
      ),
    );
  }
}

/// Draws a four-point star whose inner radius stays well above zero.
class _SparklePainter extends CustomPainter {
  const _SparklePainter({required this.color});

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final double radius = size.shortestSide / 2;
    final Offset center = Offset(size.width / 2, size.height / 2);
    final Path path = Path();
    const int points = 4;
    for (var index = 0; index < points * 2; index++) {
      final bool outer = index.isEven;
      final double r = outer ? radius : radius * 0.24;
      final double angle = -math.pi / 2 + index * (math.pi / points);
      final Offset target = Offset(
        center.dx + r * math.cos(angle),
        center.dy + r * math.sin(angle),
      );
      if (index == 0) {
        path.moveTo(target.dx, target.dy);
      } else {
        path.lineTo(target.dx, target.dy);
      }
    }
    path.close();
    final Paint paint = Paint()
      ..color = color.withValues(alpha: 0.34)
      ..style = PaintingStyle.fill;
    canvas.drawPath(path, paint);
    final Paint core = Paint()
      ..color = color.withValues(alpha: 0.85)
      ..style = PaintingStyle.fill;
    canvas.drawCircle(center, radius * 0.2, core);
  }

  @override
  bool shouldRepaint(_SparklePainter oldDelegate) =>
      oldDelegate.color != color;
}

/// Draws the orbit ring plus a dot with a fading trail behind it.
class _OrbitPainter extends CustomPainter {
  const _OrbitPainter({required this.color, required this.progress});

  final Color color;
  final double progress;

  @override
  void paint(Canvas canvas, Size size) {
    final Offset center = Offset(size.width / 2, size.height / 2);
    final double radius = size.shortestSide / 2 - 2.4;
    final Paint ring = Paint()
      ..color = color.withValues(alpha: 0.16)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;
    canvas.drawCircle(center, radius, ring);
    for (var index = 0; index < 3; index++) {
      final double offset = index * 0.16;
      final double angle = progress * math.pi * 2 - offset;
      final Offset dot = Offset(
        center.dx + radius * math.cos(angle),
        center.dy + radius * math.sin(angle),
      );
      canvas.drawCircle(
        dot,
        index == 0 ? 2.6 : 1.8 - index * 0.4,
        Paint()
          ..color = color.withValues(alpha: index == 0 ? 0.85 : 0.32 - index * 0.09),
      );
    }
  }

  @override
  bool shouldRepaint(_OrbitPainter oldDelegate) =>
      oldDelegate.progress != progress || oldDelegate.color != color;
}
