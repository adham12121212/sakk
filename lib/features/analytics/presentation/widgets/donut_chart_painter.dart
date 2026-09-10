

import 'dart:math' as math;

import 'package:flutter/cupertino.dart';
import 'package:sakk/features/analytics/presentation/widgets/segment.dart';

class DonutChartPainter extends CustomPainter {
  DonutChartPainter({required this.segments});

  final List<Segment> segments;

  @override
  void paint(Canvas canvas, Size size) {
    final total = segments.fold<double>(0, (sum, s) => sum + s.value);
    if (total <= 0) return;

    final rect = Offset.zero & size;
    final strokeWidth = size.width * 0.19;
    var startAngle = -math.pi / 2;

    for (final segment in segments) {
      if (segment.value <= 0) continue;
      final sweepAngle = (segment.value / total) * 2 * math.pi;
      final paint = Paint()
        ..color = segment.color
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeWidth
        ..strokeCap = StrokeCap.butt;

      canvas.drawArc(
        rect.deflate(strokeWidth / 2),
        startAngle,
        sweepAngle,
        false,
        paint,
      );
      startAngle += sweepAngle;
    }
  }

  @override
  bool shouldRepaint(covariant DonutChartPainter oldDelegate) {
    return oldDelegate.segments != segments;
  }
}
