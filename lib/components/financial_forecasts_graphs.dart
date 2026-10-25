import 'dart:math' as math;
import 'package:flutter/material.dart';

class FinancialPerformanceGraphs extends StatefulWidget {
  const FinancialPerformanceGraphs({super.key, required double width});

  @override
  State<FinancialPerformanceGraphs> createState() =>
      _FinancialPerformanceGraphsState();
}

class _FinancialPerformanceGraphsState
    extends State<FinancialPerformanceGraphs> {
  String monthFilter = 'All Months';
  String yearFilter = 'All Years';

  static const List<String> kMonths = [
    'All Months',
    'January',
    'February',
    'March',
    'April',
    'May',
    'June',
    'July',
    'August',
    'September',
    'October',
    'November',
    'December',
  ];

  List<String> get yearOptions {
    final int currentYear = DateTime.now().year;
    final years = List<String>.generate(6, (i) => (currentYear - i).toString());
    return ['All Years', ...years];
  }

  // Base series to lock Y scale
  final List<double> baseAllMonthsSeries = const [
    18, 18.2, 18.1, 19.5, 21.0, 21.3, 25.2, 26.1, 26.6, 27.0, 30.2, 31.2
  ];

  late final double fixedYMin =
      baseAllMonthsSeries.reduce((a, b) => a < b ? a : b);
  late final double fixedYMax =
      baseAllMonthsSeries.reduce((a, b) => a > b ? a : b);

  // Current series (monthly = 12 points, weekly = 4-5 points)
  List<double> getCurrentSeries() {
    if (monthFilter == 'All Months') {
      return baseAllMonthsSeries;
    } else {
      // Produce 4 or 5 weekly points within fixed Y range
      final weeks = _weeksInMonth(monthFilter, _selectedYearInt);
      final span = fixedYMax - fixedYMin;
      return List<double>.generate(
        weeks,
        (i) => fixedYMin + span * (0.35 + 0.15 * math.sin(i * 1.3) + 0.08 * i),
      ).map((v) => v.clamp(fixedYMin, fixedYMax)).toList();
    }
  }

  int get _selectedYearInt {
    if (yearFilter == 'All Years') return DateTime.now().year;
    return int.tryParse(yearFilter) ?? DateTime.now().year;
  }

  // X labels: months or weeks (W1..W5)
  List<String> xLabels(Size _) {
    if (monthFilter == 'All Months') {
      return const [
        'Jan','Feb','Mar','Apr','May','Jun',
        'Jul','Aug','Sep','Oct','Nov','Dec'
      ];
    } else {
      final w = _weeksInMonth(monthFilter, _selectedYearInt);
      return List<String>.generate(w, (i) => 'W${i + 1}');
    }
  }

  int _daysInMonth(String monthName, int year) {
    final idx = kMonths.indexOf(monthName);
    if (idx <= 0) return 30;
    final month = idx;
    final firstNext = (month == 12)
        ? DateTime(year + 1, 1, 1)
        : DateTime(year, month + 1, 1);
    final lastThis = firstNext.subtract(const Duration(days: 1));
    return lastThis.day;
  }

  int _weeksInMonth(String monthName, int year) {
    final days = _daysInMonth(monthName, year);
    return (days / 7).ceil();
  }

  void _showMenu(Offset globalPos, List<String> options, void Function(String) setVal) async {
    final result = await showMenu<String>(
      context: context,
      position: RelativeRect.fromLTRB(globalPos.dx, globalPos.dy, globalPos.dx, 0),
      items: options.map((o) => PopupMenuItem(value: o, child: Text(o))).toList(),
    );
    if (result != null) setState(() => setVal(result));
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final bool dark = theme.brightness == Brightness.dark;

    final Color cardColor = theme.cardColor;
    final Color panelColor =
        dark ? const Color(0xFF2D2F33) : const Color(0xFFF1F3F6);
    final Color borderColor =
        dark ? Colors.white.withOpacity(0.06) : Colors.black.withOpacity(0.05);

    final series = getCurrentSeries();

    // Removed outer grey container; this white card is now the top-level section
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: cardColor,
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
        child: LayoutBuilder(
          builder: (context, constraints) {
            final isNarrow = constraints.maxWidth < 900;

            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Financial Performance Graphs',
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: theme.hintColor,
                  ),
                ),
                const SizedBox(height: 16),

                Wrap(
                  spacing: 16,
                  runSpacing: 12,
                  children: [
                    _DropdownFilter(
                      label: 'Filter by Month:',
                      value: monthFilter,
                      onShowMenu: (pos) => _showMenu(pos, kMonths, (v) => monthFilter = v),
                    ),
                    _DropdownFilter(
                      label: 'Filter by Year:',
                      value: yearFilter,
                      onShowMenu: (pos) => _showMenu(pos, [
                        'All Years',
                        ...List<String>.generate(
                            6, (i) => (DateTime.now().year - i).toString())
                      ], (v) => yearFilter = v),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Wider line (flex 3) and narrower donut (flex 2)
                isNarrow
                    ? Column(
                        children: [
                          _Panel(
                            color: panelColor,
                            borderColor: borderColor,
                            child: _LineAreaCard(
                              title: 'Game Currency Balance Over Time',
                              series: series,
                              monthMode: monthFilter == 'All Months',
                              labelsBuilder: xLabels,
                              fixedYMin: fixedYMin,
                              fixedYMax: fixedYMax,
                            ),
                          ),
                          const SizedBox(height: 16),
                          _Panel(
                            color: panelColor,
                            borderColor: borderColor,
                            child: const _DonutCard(scaling: 0.75),
                          ),
                        ],
                      )
                    : Row(
                        children: [
                          Expanded(
                            flex: 3,
                            child: _Panel(
                              color: panelColor,
                              borderColor: borderColor,
                              child: _LineAreaCard(
                                title: 'Game Currency Balance Over Time',
                                series: series,
                                monthMode: monthFilter == 'All Months',
                                labelsBuilder: xLabels,
                                fixedYMin: fixedYMin,
                                fixedYMax: fixedYMax,
                              ),
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            flex: 2,
                            child: _Panel(
                              color: panelColor,
                              borderColor: borderColor,
                              child: const _DonutCard(scaling: 0.75),
                            ),
                          ),
                        ],
                      ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _DropdownFilter extends StatelessWidget {
  final String label;
  final String value;
  final bool alignRight;
  final void Function(Offset) onShowMenu;

  const _DropdownFilter({
    required this.label,
    required this.value,
    required this.onShowMenu,
    this.alignRight = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final labelStyle = theme.textTheme.bodyMedium?.copyWith(
      color: theme.hintColor,
      fontWeight: FontWeight.w700,
    );
    final valueStyle = theme.textTheme.bodyMedium?.copyWith(
      color: theme.hintColor,
      fontWeight: FontWeight.w600,
    );

    return Align(
      alignment: alignRight ? Alignment.centerRight : Alignment.centerLeft,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTapDown: (d) => onShowMenu(d.globalPosition),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(label, style: labelStyle),
            const SizedBox(width: 8),
            Text(value, style: valueStyle),
            const SizedBox(width: 4),
            Icon(Icons.arrow_drop_down_rounded,
                size: 20, color: theme.hintColor),
          ],
        ),
      ),
    );
  }
}

class _Panel extends StatelessWidget {
  final Widget child;
  final Color color;
  final Color borderColor;

  const _Panel({
    required this.child,
    required this.color,
    required this.borderColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 420,
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: borderColor),
      ),
      padding: const EdgeInsets.all(16),
      child: child,
    );
  }
}

class _LineAreaCard extends StatelessWidget {
  final String title;
  final List<double> series;
  final bool monthMode;
  final List<String> Function(Size) labelsBuilder;
  final double fixedYMin;
  final double fixedYMax;

  const _LineAreaCard({
    required this.title,
    required this.series,
    required this.monthMode,
    required this.labelsBuilder,
    required this.fixedYMin,
    required this.fixedYMax,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final titleStyle = theme.textTheme.bodySmall?.copyWith(
      color: theme.hintColor,
      fontWeight: FontWeight.w700,
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Center(child: Text(title, style: titleStyle)),
        const SizedBox(height: 8),
        Expanded(
          child: LayoutBuilder(
            builder: (context, c) {
              final size = Size(c.maxWidth, c.maxHeight);

              const double leftPad = 56;
              const double rightPad = 16;
              const double topPad = 24;
              const double bottomPad = 64;

              final Rect plot = Rect.fromLTWH(
                leftPad,
                topPad,
                size.width - leftPad - rightPad,
                size.height - topPad - bottomPad,
              );

              final labels = labelsBuilder(size);
              final int n = labels.length;

              return Stack(
                children: [
                  Positioned.fill(
                    top: 8,
                    child: CustomPaint(
                      painter: _LineAreaPainter(
                        series: series,
                        yMin: fixedYMin,
                        yMax: fixedYMax,
                      ),
                    ),
                  ),
                  ...List.generate(n, (i) {
                    final double t = n == 1 ? 0 : i / (n - 1);
                    final double x = plot.left + t * plot.width;
                    return Positioned(
                      left: x - 18,
                      bottom: 8,
                      width: 36,
                      child: Center(
                        child: Text(
                          labels[i],
                          style: Theme.of(context)
                              .textTheme
                              .labelSmall
                              ?.copyWith(color: Theme.of(context).hintColor),
                          textAlign: TextAlign.center,
                          maxLines: 1,
                          overflow: TextOverflow.visible,
                        ),
                      ),
                    );
                  }),
                ],
              );
            },
          ),
        ),
      ],
    );
  }
}

class _LineAreaPainter extends CustomPainter {
  final List<double> series;
  final double yMin;
  final double yMax;

  _LineAreaPainter({
    required this.series,
    required this.yMin,
    required this.yMax,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (series.isEmpty) return;

    const double leftPad = 56;
    const double rightPad = 16;
    const double topPad = 24;
    const double bottomPad = 64;

    final plot = Rect.fromLTWH(
      leftPad,
      topPad,
      size.width - leftPad - rightPad,
      size.height - topPad - bottomPad,
    );

    final gridPaint = Paint()
      ..color = const Color(0x1A000000)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;

    for (int i = 0; i <= 4; i++) {
      final y = plot.top + plot.height * (i / 4);
      canvas.drawLine(Offset(plot.left, y), Offset(plot.right, y), gridPaint);
    }

    final span = (yMax - yMin).abs() < 1e-6 ? 1.0 : (yMax - yMin);

    Offset point(int i) {
      final t = i / (series.length - 1);
      final x = plot.left + t * plot.width;
      final y = plot.bottom - ((series[i] - yMin) / span) * plot.height;
      return Offset(x, y);
    }

    final areaPath = Path()..moveTo(plot.left, plot.bottom);
    for (int i = 0; i < series.length; i++) {
      final p = point(i);
      areaPath.lineTo(p.dx, p.dy);
    }
    areaPath.lineTo(plot.right, plot.bottom);
    areaPath.close();

    final fillPaint = Paint()
      ..color = const Color(0xFF22AA52).withOpacity(0.18)
      ..style = PaintingStyle.fill;
    canvas.drawPath(areaPath, fillPaint);

    final linePaint = Paint()
      ..color = const Color(0xFF22AA52)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3
      ..strokeJoin = StrokeJoin.round
      ..strokeCap = StrokeCap.round;

    final linePath = Path()..moveTo(point(0).dx, point(0).dy);
    for (int i = 1; i < series.length; i++) {
      final p = point(i);
      linePath.lineTo(p.dx, p.dy);
    }
    canvas.drawPath(linePath, linePaint);

    final dotPaint = Paint()..color = const Color(0xFF22AA52);
    for (int i = 0; i < series.length; i++) {
      final p = point(i);
      canvas.drawCircle(p, 2.3, dotPaint);
    }

    final TextPainter tp = TextPainter(textDirection: TextDirection.ltr);
    final ticks = [18, 22, 26, 30];
    final spanY = (yMax - yMin).abs() < 1e-6 ? 1.0 : (yMax - yMin);
    for (final t in ticks) {
      final y = plot.bottom - ((t - yMin) / spanY) * plot.height;
      tp.text = TextSpan(
        text: '${t.toStringAsFixed(0)},000',
        style: const TextStyle(fontSize: 11, color: Color(0x99000000)),
      );
      tp.layout();
      tp.paint(canvas, Offset(8, y - tp.height / 2));
    }
  }

  @override
  bool shouldRepaint(covariant _LineAreaPainter oldDelegate) {
    return oldDelegate.series != series ||
        oldDelegate.yMin != yMin ||
        oldDelegate.yMax != yMax;
  }
}

class _DonutCard extends StatelessWidget {
  final double scaling; // 0..1 to adjust visible size
  const _DonutCard({this.scaling = 0.8});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final titleStyle = theme.textTheme.bodySmall?.copyWith(
      color: theme.hintColor,
      fontWeight: FontWeight.w700,
    );

    return Column(
      children: [
        Center(child: Text('Earnings vs Spending', style: titleStyle)),
        const SizedBox(height: 8),
        Expanded(
          child: LayoutBuilder(
            builder: (context, c) {
              final double side =
                  math.min(c.maxWidth, c.maxHeight - 60) * scaling;
              return Center(
                child: SizedBox(
                  width: side,
                  height: side,
                  child: const _DonutChart(
                    earned: 0.88,
                    spent: 0.12,
                    earnedColor: Color(0xFF22AA52),
                    spentColor: Color(0xFFDC3A3A),
                  ),
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 8),
        Wrap(
          alignment: WrapAlignment.center,
          spacing: 24,
          runSpacing: 8,
          children: const [
            _LegendDot(color: Color(0xFF22AA52), label: 'Coins Earned'),
            _LegendDot(color: Color(0xFFDC3A3A), label: 'Coins Spent'),
          ],
        ),
      ],
    );
  }
}

class _DonutChart extends StatelessWidget {
  final double earned;
  final double spent;
  final Color earnedColor;
  final Color spentColor;

  const _DonutChart({
    required this.earned,
    required this.spent,
    required this.earnedColor,
    required this.spentColor,
  });

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: _DonutPainter(
        earned: earned,
        spent: spent,
        earnedColor: earnedColor,
        spentColor: spentColor,
      ),
    );
  }
}

class _DonutPainter extends CustomPainter {
  final double earned;
  final double spent;
  final Color earnedColor;
  final Color spentColor;

  _DonutPainter({
    required this.earned,
    required this.spent,
    required this.earnedColor,
    required this.spentColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = math.min(size.width, size.height) / 2;

    final thickness = radius * 0.35;

    final basePaint = Paint()
      ..color = const Color(0xFFE6E6E6)
      ..style = PaintingStyle.stroke
      ..strokeWidth = thickness;

    final rect = Rect.fromCircle(center: center, radius: radius);
    canvas.drawArc(rect, 0, 2 * math.pi, false, basePaint);

    final arcPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = thickness
      ..strokeCap = StrokeCap.butt;

    double start = -math.pi / 2;
    final earnedSweep = 2 * math.pi * earned;
    final spentSweep = 2 * math.pi * spent;

    arcPaint.color = earnedColor;
    canvas.drawArc(rect, start, earnedSweep, false, arcPaint);
    start += earnedSweep;

    arcPaint.color = spentColor;
    canvas.drawArc(rect, start, spentSweep, false, arcPaint);

    canvas.drawCircle(center, radius * 0.62, Paint()..color = Colors.white);
  }

  @override
  bool shouldRepaint(covariant _DonutPainter oldDelegate) {
    return oldDelegate.earned != earned ||
        oldDelegate.spent != spent ||
        oldDelegate.earnedColor != earnedColor ||
        oldDelegate.spentColor != spentColor;
  }
}

class _LegendDot extends StatelessWidget {
  final Color color;
  final String label;
  const _LegendDot({required this.color, required this.label});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 14,
          height: 14,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 8),
        Text(
          label,
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.hintColor,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}
