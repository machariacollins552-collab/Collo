import 'package:flutter/material.dart';

import '../core/format.dart';
import '../core/theme.dart';
import '../models/weight_entry.dart';

/// Line chart of weight over time, drawn with a [CustomPainter] (no chart library needed).
/// Shows a dashed gold line for the target weight when [target] is given.
class WeightChart extends StatelessWidget {
  const WeightChart({super.key, required this.entries, this.target, this.height = 220});

  /// Readings sorted from oldest to newest.
  final List<WeightEntry> entries;
  final double? target;
  final double height;

  @override
  Widget build(BuildContext context) {
    final description = entries.isEmpty
        ? 'Weight chart with no readings yet.'
        : 'Weight chart. ${entries.length} readings, latest ${formatKg(entries.last.kg)} kilograms.';
    return Semantics(
      label: description,
      child: SizedBox(
        height: height,
        width: double.infinity,
        child: CustomPaint(painter: _WeightChartPainter(entries: entries, target: target)),
      ),
    );
  }
}

class _WeightChartPainter extends CustomPainter {
  _WeightChartPainter({required this.entries, required this.target});

  final List<WeightEntry> entries;
  final double? target;

  static const TextStyle _axisStyle = TextStyle(fontSize: 11, color: AppColors.muted);

  void _text(Canvas canvas, String text, Offset at, {TextAlign align = TextAlign.left}) {
    final painter = TextPainter(
      text: TextSpan(text: text, style: _axisStyle),
      textDirection: TextDirection.ltr,
    )..layout(maxWidth: 90);
    double dx = at.dx;
    if (align == TextAlign.right) {
      dx = at.dx - painter.width;
    } else if (align == TextAlign.center) {
      dx = at.dx - painter.width / 2;
    }
    painter.paint(canvas, Offset(dx, at.dy - painter.height / 2));
  }

  @override
  void paint(Canvas canvas, Size size) {
    if (entries.isEmpty) return;

    const leftPad = 44.0;
    const rightPad = 14.0;
    const topPad = 12.0;
    const bottomPad = 26.0;
    final plot = Rect.fromLTRB(leftPad, topPad, size.width - rightPad, size.height - bottomPad);
    if (plot.width <= 0 || plot.height <= 0) return;

    // Vertical range, padded and including the target line.
    var minKg = entries.first.kg;
    var maxKg = entries.first.kg;
    for (final e in entries) {
      if (e.kg < minKg) minKg = e.kg;
      if (e.kg > maxKg) maxKg = e.kg;
    }
    final t = target;
    if (t != null) {
      if (t < minKg) minKg = t;
      if (t > maxKg) maxKg = t;
    }
    var lo = (minKg - 0.5).floorToDouble();
    var hi = (maxKg + 0.5).ceilToDouble();
    if (hi - lo < 2) {
      lo -= 1;
      hi += 1;
    }
    double yFor(double kg) => plot.bottom - (kg - lo) / (hi - lo) * plot.height;

    // Horizontal grid and y labels.
    final gridPaint = Paint()
      ..color = AppColors.border
      ..strokeWidth = 1;
    for (var i = 0; i <= 2; i++) {
      final kg = lo + (hi - lo) * i / 2;
      final y = yFor(kg);
      canvas.drawLine(Offset(plot.left, y), Offset(plot.right, y), gridPaint);
      _text(canvas, formatKg(kg), Offset(plot.left - 8, y), align: TextAlign.right);
    }

    // Horizontal position by date.
    final firstDate = entries.first.date;
    final lastDate = entries.last.date;
    final spanDays = daysBetween(firstDate, lastDate);
    double xFor(WeightEntry e) {
      if (spanDays <= 0) return plot.center.dx;
      return plot.left + daysBetween(firstDate, e.date) / spanDays * plot.width;
    }

    // Target line (dashed gold).
    if (t != null) {
      final y = yFor(t);
      final dash = Paint()
        ..color = AppColors.gold
        ..strokeWidth = 1.6;
      var x = plot.left;
      while (x < plot.right) {
        canvas.drawLine(Offset(x, y), Offset((x + 6).clamp(plot.left, plot.right).toDouble(), y), dash);
        x += 11;
      }
      _text(canvas, 'target', Offset(plot.right, y - 9), align: TextAlign.right);
    }

    final points = <Offset>[for (final e in entries) Offset(xFor(e), yFor(e.kg))];

    // Soft area under the line, then the line itself.
    if (points.length > 1) {
      final area = Path()..moveTo(points.first.dx, plot.bottom);
      for (final p in points) {
        area.lineTo(p.dx, p.dy);
      }
      area
        ..lineTo(points.last.dx, plot.bottom)
        ..close();
      canvas.drawPath(area, Paint()..color = AppColors.forest.withValues(alpha: 0.07));

      final line = Path()..moveTo(points.first.dx, points.first.dy);
      for (final p in points.skip(1)) {
        line.lineTo(p.dx, p.dy);
      }
      canvas.drawPath(
        line,
        Paint()
          ..color = AppColors.forest
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2.6
          ..strokeJoin = StrokeJoin.round
          ..strokeCap = StrokeCap.round,
      );
    }

    // Dots: small for history, larger gold-ringed dot for the latest reading.
    for (var i = 0; i < points.length; i++) {
      final isLast = i == points.length - 1;
      canvas.drawCircle(points[i], isLast ? 6 : 3.5, Paint()..color = AppColors.ivory);
      canvas.drawCircle(
        points[i],
        isLast ? 4.2 : 2.4,
        Paint()..color = isLast ? AppColors.forest : AppColors.forestSoft,
      );
      if (isLast) {
        canvas.drawCircle(
          points[i],
          7,
          Paint()
            ..color = AppColors.gold
            ..style = PaintingStyle.stroke
            ..strokeWidth = 1.5,
        );
      }
    }

    // Date labels at both ends.
    final labelY = plot.bottom + 16;
    if (spanDays <= 0) {
      _text(canvas, shortDate(firstDate), Offset(plot.center.dx, labelY), align: TextAlign.center);
    } else {
      _text(canvas, shortDate(firstDate), Offset(plot.left, labelY));
      _text(canvas, shortDate(lastDate), Offset(plot.right, labelY), align: TextAlign.right);
    }
  }

  @override
  bool shouldRepaint(covariant _WeightChartPainter oldDelegate) {
    return oldDelegate.entries != entries || oldDelegate.target != target;
  }
}
