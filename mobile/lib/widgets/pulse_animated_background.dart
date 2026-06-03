import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';

import '../theme/pulse_theme.dart';

class PulseAnimatedBackground extends StatefulWidget {
  const PulseAnimatedBackground({super.key, this.opacity = 1});

  final double opacity;

  @override
  State<PulseAnimatedBackground> createState() =>
      _PulseAnimatedBackgroundState();
}

class _PulseAnimatedBackgroundState extends State<PulseAnimatedBackground>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 14),
    );
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final disableAnimations = MediaQuery.of(context).disableAnimations;
    if (disableAnimations) {
      _controller.stop();
      _controller.value = 0.36;
    } else if (!_controller.isAnimating) {
      _controller.repeat();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final disableAnimations = MediaQuery.of(context).disableAnimations;

    return IgnorePointer(
      child: RepaintBoundary(
        child: AnimatedBuilder(
          animation: _controller,
          builder: (context, child) {
            return CustomPaint(
              painter: _PulseBackgroundPainter(
                progress: disableAnimations ? 0.36 : _controller.value,
                opacity: widget.opacity,
                isCompact: MediaQuery.sizeOf(context).width < 430,
              ),
              size: Size.infinite,
            );
          },
        ),
      ),
    );
  }
}

class _PulseBackgroundPainter extends CustomPainter {
  _PulseBackgroundPainter({
    required this.progress,
    required this.opacity,
    required this.isCompact,
  });

  final double progress;
  final double opacity;
  final bool isCompact;

  static const _pink = PulseTheme.primary;
  static const _orange = PulseTheme.primaryLight;

  @override
  void paint(Canvas canvas, Size size) {
    if (size.isEmpty) return;

    final phase = progress * math.pi * 2;
    _drawSoftGlows(canvas, size, phase);
    _drawPulseLine(canvas, size, phase);
    _drawParticles(canvas, size, phase);
  }

  void _drawSoftGlows(Canvas canvas, Size size, double phase) {
    final topShift = math.sin(phase) * 18;
    final sideShift = math.cos(phase * 0.7) * 14;

    _drawGlow(
      canvas,
      Offset(size.width * 0.18 + sideShift, 72 + topShift),
      isCompact ? 150 : 210,
      _pink.withValues(alpha: 0.16 * opacity),
    );
    _drawGlow(
      canvas,
      Offset(size.width * 0.86 - sideShift, 132 - topShift * 0.45),
      isCompact ? 120 : 180,
      _orange.withValues(alpha: 0.12 * opacity),
    );
    _drawGlow(
      canvas,
      Offset(size.width * 0.52, size.height * 0.72),
      isCompact ? 170 : 240,
      _pink.withValues(alpha: 0.055 * opacity),
    );
  }

  void _drawGlow(Canvas canvas, Offset center, double radius, Color color) {
    final paint = Paint()
      ..shader = ui.Gradient.radial(
        center,
        radius,
        [
          color,
          color.withValues(alpha: 0),
        ],
        const [0, 1],
      );
    canvas.drawCircle(center, radius, paint);
  }

  void _drawPulseLine(Canvas canvas, Size size, double phase) {
    final baseline = isCompact ? 76.0 : 88.0;
    final amplitude = isCompact ? 5.0 : 7.0;
    final path = Path();

    for (double x = -24; x <= size.width + 24; x += 6) {
      final normalized = (x / size.width).clamp(0.0, 1.0);
      final wave = math.sin(normalized * math.pi * 4 + phase * 0.55);
      var y = baseline + wave * amplitude;

      final spikeCenter = size.width * (0.58 + math.sin(phase * 0.25) * 0.04);
      final distance = (x - spikeCenter).abs();
      if (distance < 42) {
        final spike = 1 - (distance / 42);
        y += math.sin(spike * math.pi * 3) * spike * -18;
      }

      if (x == -24) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }

    final glowPaint = Paint()
      ..color = _pink.withValues(alpha: 0.055 * opacity)
      ..strokeWidth = isCompact ? 5 : 6
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8);
    final linePaint = Paint()
      ..color = _orange.withValues(alpha: 0.13 * opacity)
      ..strokeWidth = 1.1
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;

    canvas.drawPath(path, glowPaint);
    canvas.drawPath(path, linePaint);
  }

  void _drawParticles(Canvas canvas, Size size, double phase) {
    final count = isCompact ? 24 : 36;
    for (var i = 0; i < count; i++) {
      final baseX = (i * 79.0) % size.width;
      final baseY = (i * 137.0) % size.height;
      final driftX = math.sin(phase + i * 0.71) * (isCompact ? 4 : 7);
      final driftY = math.cos(phase * 0.8 + i * 0.43) * (isCompact ? 5 : 9);
      final twinkle = 0.55 + math.sin(phase * 1.2 + i) * 0.45;
      final isWarm = i.isEven;
      final color = (isWarm ? _orange : _pink).withValues(
        alpha: (0.045 + twinkle * 0.045) * opacity,
      );
      final radius = (isCompact ? 0.8 : 1.0) + (i % 3) * 0.35;
      final paint = Paint()..color = color;

      canvas.drawCircle(Offset(baseX + driftX, baseY + driftY), radius, paint);
    }
  }

  @override
  bool shouldRepaint(covariant _PulseBackgroundPainter oldDelegate) {
    return oldDelegate.progress != progress ||
        oldDelegate.opacity != opacity ||
        oldDelegate.isCompact != isCompact;
  }
}
