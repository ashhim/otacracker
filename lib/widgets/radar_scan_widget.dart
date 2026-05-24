import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../core/app_theme.dart';

class RadarScanWidget extends StatefulWidget {
  const RadarScanWidget({
    super.key,
    required this.active,
    required this.targetCount,
  });

  final bool active;
  final int targetCount;

  @override
  State<RadarScanWidget> createState() => _RadarScanWidgetState();
}

class _RadarScanWidgetState extends State<RadarScanWidget> with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 4),
  );

  @override
  void initState() {
    super.initState();
    if (widget.active) {
      _controller.repeat();
    }
  }

  @override
  void didUpdateWidget(covariant RadarScanWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.active && !_controller.isAnimating) {
      _controller.repeat();
    } else if (!widget.active && _controller.isAnimating) {
      _controller.stop();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AspectRatio(
      aspectRatio: 1,
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, _) {
          return CustomPaint(
            painter: _RadarPainter(
              progress: _controller.value,
              active: widget.active,
              targetCount: widget.targetCount,
            ),
          );
        },
      ),
    );
  }
}

class _RadarPainter extends CustomPainter {
  _RadarPainter({
    required this.progress,
    required this.active,
    required this.targetCount,
  });

  final double progress;
  final bool active;
  final int targetCount;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;
    final ringPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1
      ..color = AppTheme.border;
    final sweepPaint = Paint()
      ..shader = SweepGradient(
        colors: [
          AppTheme.neonGreen.withValues(alpha: 0),
          AppTheme.neonGreen.withValues(alpha: active ? 0.72 : 0.22),
          AppTheme.neonBlue.withValues(alpha: active ? 0.18 : 0.06),
          AppTheme.neonGreen.withValues(alpha: 0),
        ],
        stops: const [0, 0.14, 0.2, 1],
        transform: GradientRotation(progress * math.pi * 2),
      ).createShader(Rect.fromCircle(center: center, radius: radius))
      ..style = PaintingStyle.fill;

    canvas.drawCircle(center, radius, Paint()..color = AppTheme.panelAlt);
    for (var index = 1; index <= 4; index++) {
      canvas.drawCircle(center, radius * (index / 4), ringPaint);
    }
    canvas.drawLine(
      Offset(center.dx, 0),
      Offset(center.dx, size.height),
      ringPaint,
    );
    canvas.drawLine(
      Offset(0, center.dy),
      Offset(size.width, center.dy),
      ringPaint,
    );
    canvas.drawCircle(center, radius, sweepPaint);
    canvas.drawCircle(center, 6, Paint()..color = AppTheme.neonGreen);
    canvas.drawCircle(
      center,
      14,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1
        ..color = AppTheme.neonGreen.withValues(alpha: 0.32),
    );

    final targetPaint = Paint()..color = AppTheme.neonAmber;
    for (var index = 0; index < targetCount.clamp(0, 6); index++) {
      final angle = (index + 1) * 0.8 + progress * 0.8;
      final targetRadius = radius * (0.3 + (index % 4) * 0.14);
      final point = Offset(
        center.dx + math.cos(angle) * targetRadius,
        center.dy + math.sin(angle) * targetRadius,
      );
      canvas.drawCircle(point, 4, targetPaint);
      canvas.drawCircle(
        point,
        10,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1
          ..color = AppTheme.neonAmber.withValues(alpha: 0.25),
      );
    }
  }

  @override
  bool shouldRepaint(covariant _RadarPainter oldDelegate) {
    return oldDelegate.progress != progress ||
        oldDelegate.active != active ||
        oldDelegate.targetCount != targetCount;
  }
}
