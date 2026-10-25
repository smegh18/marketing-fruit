import 'dart:math' as math;
import 'package:flutter/material.dart';

class FinancialForecastSection extends StatelessWidget {
  const FinancialForecastSection({super.key, required double width});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final bool dark = theme.brightness == Brightness.dark;

    final Color outerSurface = theme.cardColor;
    final Color innerSurface = dark
        ? const Color(0xFF2D2F33)
        : const Color(0xFFF1F3F6);

    return Container(
      width: double.infinity,
      color: theme.scaffoldBackgroundColor,
      child: Container(
        width: double.infinity,
        decoration: BoxDecoration(
          color: outerSurface,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.06),
              blurRadius: 18,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Financial Forecast',
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: theme.hintColor,
                ),
              ),
              const SizedBox(height: 14),

              Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  color: innerSurface,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: dark
                        ? Colors.white.withOpacity(0.06)
                        : Colors.black.withOpacity(0.05),
                  ),
                ),
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 20, 20, 20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _ForecastParagraph(
                        textSpans: const [
                          _Span.normal(
                              "Based on your recent gameplay, here's an analysis of your financial performance: Your recent transactions show a "),
                          _Span.bold("positive trend"),
                          _Span.normal(
                              ", indicating strong overall profitability. Keep up the good work! Focus on "),
                          _Span.bold("improving your spending control"),
                          _Span.normal(
                              " by making more mindful purchases. Your "),
                          _Span.bold("gameplay consistency is low"),
                          _Span.normal(
                              ". Try to log in and make transactions more regularly to keep your financial activity stable. Your "),
                          _Span.bold("education consistency is low"),
                          _Span.normal(
                              ". Be sure to check out the financial tutorials and quizzes to gain new insights."),
                        ],
                      ),
                      const SizedBox(height: 16),

                      Center(
                        child: Text(
                          "Your Strengths & Weaknesses",
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.hintColor,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),

                      // Crisp, centered radar with proper math and sizing
                      SizedBox(
                        height: 180, // compact and balanced
                        width: double.infinity,
                        child: _RadarChart(
                          labels: [
                            'Earning Efficiency',
                            'Spending Control',
                            'Net Profitability',
                            'Gameplay Consistency',
                            'Education Consistency',
                          ],
                          // Values are 0..1 for each axis, clockwise from top
                          values: [0.35, 0.8, 0.9, 0.25, 0.3],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ForecastParagraph extends StatelessWidget {
  final List<_Span> textSpans;
  const _ForecastParagraph({required this.textSpans});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final base = theme.textTheme.bodyMedium?.copyWith(
      height: 1.5,
      color: theme.hintColor,
      fontSize: 14.5,
    );
    final bold = base?.copyWith(fontWeight: FontWeight.w700);

    return Text.rich(
      TextSpan(
        children: textSpans
            .map((s) => TextSpan(text: s.text, style: s.isBold ? bold : base))
            .toList(),
      ),
    );
  }
}

class _Span {
  final String text;
  final bool isBold;
  const _Span.normal(this.text) : isBold = false;
  const _Span.bold(this.text) : isBold = true;
}

/// Proper radar chart (grid + filled polygon + labels)
class _RadarChart extends StatelessWidget {
  final List<String> labels;
  final List<double> values; // 0..1 each

  const _RadarChart({
    required this.labels,
    required this.values,
  }) : assert(values.length >= 3);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final bool dark = theme.brightness == Brightness.dark;

    final gridColor =
        dark ? Colors.white.withOpacity(0.10) : Colors.black.withOpacity(0.10);
    final axisColor =
        dark ? Colors.white.withOpacity(0.10) : Colors.black.withOpacity(0.10);
    final fillColor = const Color(0xFF3ED0B5).withOpacity(0.25);
    final strokeColor = const Color(0xFF3ED0B5);

    return LayoutBuilder(
      builder: (context, c) {
        final size = Size(c.maxWidth, c.maxHeight);
        return Stack(
          children: [
            CustomPaint(
              size: size,
              painter: _RadarPainter(
                n: labels.length,
                values: values,
                gridColor: gridColor,
                axisColor: axisColor,
                fillColor: fillColor,
                strokeColor: strokeColor,
              ),
            ),
            // Radial labels placed outside the grid
            ..._labelWidgets(size, labels, Theme.of(context)),
          ],
        );
      },
    );
  }

  List<Widget> _labelWidgets(Size size, List<String> labels, ThemeData theme) {
    final List<Widget> widgets = [];
    final int n = labels.length;
    final double cx = size.width / 2;
    final double cy = size.height * 0.58; // slightly below middle like screenshot
    final double r = size.shortestSide * 0.33;
    final style = theme.textTheme.bodySmall?.copyWith(
      color: theme.hintColor,
    );

    for (int i = 0; i < n; i++) {
      final angle = -math.pi / 2 + i * 2 * math.pi / n;
      final dx = cx + (r + 28) * math.cos(angle);
      final dy = cy + (r + 28) * math.sin(angle);

      widgets.add(Positioned(
        left: dx - 60,
        top: dy - 10,
        width: 120,
        child: Text(
          labels[i],
          textAlign: TextAlign.center,
          style: style,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
      ));
    }
    return widgets;
  }
}

class _RadarPainter extends CustomPainter {
  final int n;
  final List<double> values; // 0..1
  final Color gridColor;
  final Color axisColor;
  final Color fillColor;
  final Color strokeColor;

  _RadarPainter({
    required this.n,
    required this.values,
    required this.gridColor,
    required this.axisColor,
    required this.fillColor,
    required this.strokeColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2;
    final cy = size.height * 0.58; // lower center like the screenshot
    final center = Offset(cx, cy);

    final double maxR = size.shortestSide * 0.33;

    final gridPaint = Paint()
      ..color = gridColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;

    final axisPaint = Paint()
      ..color = axisColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;

    // Concentric grid polygons
    const rings = 6;
    for (int ring = 1; ring <= rings; ring++) {
      final r = maxR * (ring / rings);
      final path = Path();
      for (int i = 0; i < n; i++) {
        final a = -math.pi / 2 + i * 2 * math.pi / n;
        final x = cx + r * math.cos(a);
        final y = cy + r * math.sin(a);
        if (i == 0) {
          path.moveTo(x, y);
        } else {
          path.lineTo(x, y);
        }
      }
      path.close();
      canvas.drawPath(path, gridPaint);
    }

    // Axes
    for (int i = 0; i < n; i++) {
      final a = -math.pi / 2 + i * 2 * math.pi / n;
      final x = cx + maxR * math.cos(a);
      final y = cy + maxR * math.sin(a);
      canvas.drawLine(center, Offset(x, y), axisPaint);
    }

    // Data polygon
    final dataPath = Path();
    for (int i = 0; i < n; i++) {
      final v = values[i].clamp(0.0, 1.0);
      final a = -math.pi / 2 + i * 2 * math.pi / n;
      final x = cx + (maxR * v) * math.cos(a);
      final y = cy + (maxR * v) * math.sin(a);
      if (i == 0) {
        dataPath.moveTo(x, y);
      } else {
        dataPath.lineTo(x, y);
      }
    }
    dataPath.close();

    // Fill and stroke
    final fillPaint = Paint()
      ..color = fillColor
      ..style = PaintingStyle.fill;
    final strokePaint = Paint()
      ..color = strokeColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;

    canvas.drawPath(dataPath, fillPaint);
    canvas.drawPath(dataPath, strokePaint);

    // Small node at first point for visual anchor
    final firstAngle = -math.pi / 2;
    final first = Offset(
      cx + (maxR * values.first) * math.cos(firstAngle),
      cy + (maxR * values.first) * math.sin(firstAngle),
    );
    canvas.drawCircle(first, 3.5, Paint()..color = strokeColor);
  }

  @override
  bool shouldRepaint(covariant _RadarPainter oldDelegate) {
    return oldDelegate.values != values ||
        oldDelegate.gridColor != gridColor ||
        oldDelegate.fillColor != fillColor ||
        oldDelegate.strokeColor != strokeColor;
  }
}
