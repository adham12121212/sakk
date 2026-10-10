import 'dart:math' as math;

import 'package:flutter/rendering.dart';
import 'package:sakk/features/analytics/presentation/widgets/segment.dart';

/// Donut with rounded, slightly separated segments over a faint track.
class DonutChartPainter extends CustomPainter {
  DonutChartPainter({required this.segments, required this.trackColor});

  final List<Segment> segments;
  final Color trackColor;

  @override
  void paint(Canvas canvas, Size size) {
    final strokeWidth = size.width * 0.13;
    final rect = (Offset.zero & size).deflate(strokeWidth / 2);
    canvas.drawArc(rect, 0, 2 * math.pi, false, Paint()
      ..color = trackColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth);

    final visible = segments.where((s) => s.value > 0).toList();
    final total = visible.fold<double>(0, (sum, s) => sum + s.value);
    if (total <= 0) return;

    // Round caps overlap the next segment, so leave a small gap when there's
    // more than one segment.
    final gap = visible.length > 1 ? 0.22 : 0.0;
    var startAngle = -math.pi / 2;
    for (final segment in visible) {
      final sweep = (segment.value / total) * 2 * math.pi;
      canvas.drawArc(
        rect,
        startAngle + gap / 2,
        math.max(0.0001, sweep - gap),
        false,
        Paint()
          ..color = segment.color
          ..style = PaintingStyle.stroke
          ..strokeWidth = strokeWidth
          ..strokeCap = StrokeCap.round,
      );
      startAngle += sweep;
    }
  }

  @override
  bool shouldRepaint(covariant DonutChartPainter oldDelegate) =>
      oldDelegate.segments != segments || oldDelegate.trackColor != trackColor;
}
