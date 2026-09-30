import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../app/theme.dart';

/// ─────────────────────────────────────────────────────────────
/// Graphique en barres « Ventes sur la semaine » (maquette vendeur)
/// ─────────────────────────────────────────────────────────────
class WeeklyBarChart extends StatelessWidget {
  /// 7 valeurs (L M M J V S D) — déjà mises à l'échelle (ex. en k BIF).
  final List<double> values;
  final List<String> dayLabels;

  const WeeklyBarChart({
    super.key,
    required this.values,
    this.dayLabels = const ['L', 'M', 'M', 'J', 'V', 'S', 'D'],
  });

  @override
  Widget build(BuildContext context) {
    final rawMax = values.fold<double>(0, math.max);
    final max = _niceMax(rawMax);
    final highlight = values.indexWhere((v) => v == rawMax && rawMax > 0);
    final ticks = [max, max * .75, max * .5, max * .25, 0]
        .map((v) => v.round())
        .toList();

    return SizedBox(
      height: 190,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Étiquettes de l'axe Y (0 · quart · moitié · max)
          Column(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: ticks.reversed
                .map((t) => Text('$t',
                    style: TextStyle(
                        color: context.mutedColor, fontSize: 10.5)))
                .toList(),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              children: [
                Expanded(
                  child: LayoutBuilder(
                    builder: (_, constraints) => CustomPaint(
                      size: Size(constraints.maxWidth, constraints.maxHeight),
                      painter: _BarsPainter(values, highlight, max),
                    ),
                  ),
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    for (final d in dayLabels)
                      Expanded(
                        child: Center(
                          child: Text(d,
                              style: TextStyle(
                                  color: context.mutedColor, fontSize: 11)),
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  static double _niceMax(double v) {
    if (v <= 0) return 10;
    final mag = math.pow(10, (math.log(v) / math.ln10).floor()).toDouble();
    return (v / mag).ceil() * mag;
  }
}

class _BarsPainter extends CustomPainter {
  final List<double> values;
  final int highlight;
  final double max;
  _BarsPainter(this.values, this.highlight, this.max);

  @override
  void paint(Canvas canvas, Size size) {
    final gridPaint = Paint()
      ..color = const Color(0x22000000)
      ..strokeWidth = 1;
    for (final f in [0.0, .25, .5, .75, 1.0]) {
      _dashedLine(canvas, Offset(0, size.height * (1 - f)),
          Offset(size.width, size.height * (1 - f)), gridPaint);
    }
    final n = values.length;
    if (n == 0) return;
    final slot = size.width / n;
    final barW = slot * 0.52;
    for (var i = 0; i < n; i++) {
      final h = max == 0 ? 0.0 : size.height * (values[i] / max);
      final left = i * slot + (slot - barW) / 2;
      final rect = Rect.fromLTWH(left, size.height - h, barW, h);
      final rrect = RRect.fromRectAndCorners(rect,
          topLeft: const Radius.circular(8),
          topRight: const Radius.circular(8),
          bottomLeft: const Radius.circular(3),
          bottomRight: const Radius.circular(3));
      final paint = Paint()
        ..color = i == highlight ? AppTheme.brand : AppTheme.sage;
      canvas.drawRRect(rrect, paint);
    }
  }

  void _dashedLine(Canvas canvas, Offset a, Offset b, Paint paint) {
    const dash = 5.0, gap = 5.0;
    final total = (b - a).dx;
    var x = a.dx;
    while (x < total) {
      canvas.drawLine(
          Offset(x, a.dy), Offset(math.min(x + dash, total), a.dy), paint);
      x += dash + gap;
    }
  }

  @override
  bool shouldRepaint(covariant _BarsPainter old) =>
      old.values != values || old.highlight != highlight || old.max != max;
}

/// ─────────────────────────────────────────────────────────────
/// Donut « Comment les clients reçoivent-ils ? » (maquette vendeur)
/// ─────────────────────────────────────────────────────────────
class SplitDonut extends StatelessWidget {
  final double fraction; // 0..1 (part « Livraison », vert forêt)
  final String centerTop;
  final String centerBottom;
  final double size;

  const SplitDonut({
    super.key,
    required this.fraction,
    required this.centerTop,
    this.centerBottom = '',
    this.size = 150,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        alignment: Alignment.center,
        children: [
          CustomPaint(
            size: Size(size, size),
            painter: _DonutPainter(fraction.clamp(0.0, 1.0),
                context.isDark ? const Color(0xFF37332C) : AppTheme.cream),
          ),
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(centerTop,
                  style: TextStyle(
                      color: context.textColor,
                      fontSize: 26,
                      fontWeight: FontWeight.w900)),
              if (centerBottom.isNotEmpty)
                Text(centerBottom,
                    style: TextStyle(
                        color: context.mutedColor, fontSize: 11.5)),
            ],
          ),
        ],
      ),
    );
  }
}

class _DonutPainter extends CustomPainter {
  final double fraction;
  final Color neutral;
  _DonutPainter(this.fraction, this.neutral);

  @override
  void paint(Canvas canvas, Size size) {
    const stroke = 18.0;
    final rect = Rect.fromLTWH(stroke / 2, stroke / 2,
        size.width - stroke, size.height - stroke);
    final base = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke
      ..color = neutral;
    final arc = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke
      ..strokeCap = StrokeCap.round
      ..color = AppTheme.forest;
    canvas.drawArc(rect, 0, math.pi * 2, false, base);
    if (fraction > 0) {
      canvas.drawArc(rect, -math.pi / 2, math.pi * 2 * fraction, false, arc);
    }
  }

  @override
  bool shouldRepaint(covariant _DonutPainter old) =>
      old.fraction != fraction || old.neutral != neutral;
}
