import 'dart:math' as math;
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';

class IndustryChartScreen extends StatefulWidget {
  const IndustryChartScreen({super.key});

  @override
  State<IndustryChartScreen> createState() => _IndustryChartScreenState();
}

class _IndustryChartScreenState extends State<IndustryChartScreen> {
  final ScrollController _hCtrl = ScrollController();

  @override
  void dispose() {
    _hCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final screenW = MediaQuery.of(context).size.width;

    return LayoutBuilder(
      builder: (context, constraints) {
        final double maxW = constraints.maxWidth;
        final bool isMobile = maxW < 560;
        final bool isTablet = maxW >= 560 && maxW < 1024;
        final bool isDesktop = maxW >= 1024;

        final double cardRadius = isDesktop ? 18 : 16;
        final double cardPad = isDesktop ? 24 : 20;
        final double titleSize = isDesktop ? 22 : (isTablet ? 18 : 16);

        final double boxMaxWidth = isDesktop
            ? math.min(screenW * 0.85, 1200)
            : isTablet
                ? math.min(screenW * 0.92, 900)
                : math.min(screenW * 0.95, 720);

        final double baseChartHeight = isDesktop ? 360 : (isTablet ? 320 : 260);
        final double axisFont = isDesktop ? 13 : (isTablet ? 12 : 11);

        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 20),
          child: Center(
            child: ConstrainedBox(
              constraints: BoxConstraints(maxWidth: boxMaxWidth),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 250),
                curve: Curves.easeInOut,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(cardRadius),
                  boxShadow: const [
                    BoxShadow(
                      color: Colors.black12,
                      blurRadius: 10,
                      spreadRadius: 2,
                      offset: Offset(2, 4),
                    ),
                  ],
                ),
                padding: EdgeInsets.all(cardPad),
                child: StreamBuilder<DatabaseEvent>(
                  stream: FirebaseDatabase.instance.ref('users').onValue,
                  builder: (context, snap) {
                    final counts = _dynamicArcCounts(snap.data?.snapshot);

                    // order arcs by count desc then name
                    final titles = counts.keys.toList()
                      ..sort((a, b) {
                        final byCount = counts[b]!.compareTo(counts[a]!);
                        return byCount != 0 ? byCount : a.compareTo(b);
                      });

                    final int n = titles.length;

                    // responsive spacing/width
                    final double groupsSpaceBase =
                        isDesktop ? 36 : (isTablet ? 28 : 18);
                    final double groupsSpace =
                        n <= 6 ? groupsSpaceBase : math.max(10, groupsSpaceBase - (n - 6) * 2);

                    double barWidth = (boxMaxWidth / math.max(1, n * 4));
                    barWidth = _clampDouble(barWidth, 8, 28);

                    // build bars AFTER width is known
                    final bars = <BarChartGroupData>[
                      for (int i = 0; i < n; i++)
                        _bar(i, counts[titles[i]]!, _colorForIndex(i), barWidth),
                    ];

                    final int maxCount = bars.isEmpty
                        ? 0
                        : bars.map((g) => g.barRods.first.toY.round()).reduce(math.max);
                    final double maxY =
                        (maxCount == 0 ? 10 : maxCount + 2).toDouble();
                    final double interval = _niceInterval(maxY);
                    final bool noData = maxCount == 0;

                    // total content width for horizontal scroll
                    final double estimatedWidth =
                        n * (barWidth + groupsSpace) + 80; // padding
                    // Always allow horizontal scroll on mobile; on larger screens only if needed
                    final bool allowHScroll =
                        isMobile || estimatedWidth > boxMaxWidth;
                    final double chartWidth =
                        allowHScroll ? math.max(estimatedWidth, boxMaxWidth) : boxMaxWidth;

                    final double bottomReserved = isMobile ? 48 : 32;

                    // disable chart touches on mobile so vertical page scroll works
                    final bool touchesEnabled = !isMobile;

                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Total Students by Industry Division',
                          style: TextStyle(
                            fontSize: titleSize,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 16),

                        if (noData)
                          _EmptyState(height: baseChartHeight)
                        else
                          Scrollbar(
                            controller: _hCtrl,
                            thumbVisibility: isMobile && allowHScroll, // <-- visible thumb on mobile
                            trackVisibility: false,
                            interactive: true,
                            thickness: isMobile ? 6 : null,
                            radius: const Radius.circular(999),
                            notificationPredicate: (_) => true,
                            child: SingleChildScrollView(
                              controller: _hCtrl,
                              scrollDirection: Axis.horizontal,
                              primary: false,
                              physics: allowHScroll
                                  ? const BouncingScrollPhysics()
                                  : const ClampingScrollPhysics(),
                              child: SizedBox(
                                height: baseChartHeight,
                                width: chartWidth,
                                child: BarChart(
                                  BarChartData(
                                    alignment: BarChartAlignment.spaceAround,
                                    maxY: maxY,
                                    gridData: FlGridData(
                                      show: true,
                                      drawVerticalLine: false,
                                      horizontalInterval: interval,
                                      getDrawingHorizontalLine: (value) => FlLine(
                                        color: Colors.black12,
                                        strokeWidth: 1,
                                      ),
                                    ),
                                    borderData: FlBorderData(show: false),
                                    titlesData: FlTitlesData(
                                      topTitles: const AxisTitles(
                                        sideTitles: SideTitles(showTitles: false),
                                      ),
                                      rightTitles: const AxisTitles(
                                        sideTitles: SideTitles(showTitles: false),
                                      ),
                                      leftTitles: AxisTitles(
                                        sideTitles: SideTitles(
                                          showTitles: true,
                                          reservedSize: isMobile ? 28 : 36,
                                          interval: interval,
                                          getTitlesWidget: (value, meta) => Padding(
                                            padding: const EdgeInsets.only(right: 6),
                                            child: Text(
                                              value.toInt().toString(),
                                              style: TextStyle(fontSize: axisFont),
                                            ),
                                          ),
                                        ),
                                      ),
                                      bottomTitles: AxisTitles(
                                        sideTitles: SideTitles(
                                          showTitles: true,
                                          reservedSize: bottomReserved,
                                          getTitlesWidget: (value, meta) {
                                            final i = value.toInt();
                                            if (i < 0 || i >= titles.length) {
                                              return const SizedBox.shrink();
                                            }
                                            final label = titles[i];
                                            return Padding(
                                              padding: const EdgeInsets.only(top: 8),
                                              child: _ArcLabel(
                                                label: label,
                                                isMobile: isMobile,
                                                fontSize: axisFont,
                                              ),
                                            );
                                          },
                                        ),
                                      ),
                                    ),
                                    barTouchData: BarTouchData(
                                      enabled: touchesEnabled,
                                      touchTooltipData: BarTouchTooltipData(
                                        tooltipBgColor: Colors.black87,
                                        getTooltipItem:
                                            (group, groupIndex, rod, rodIndex) {
                                          final label = titles[group.x.toInt()];
                                          final value = rod.toY.toInt();
                                          return BarTooltipItem(
                                            '$label\n',
                                            const TextStyle(
                                              color: Colors.white70,
                                              fontWeight: FontWeight.w400,
                                            ),
                                            children: [
                                              TextSpan(
                                                text: '$value students',
                                                style: const TextStyle(
                                                  color: Colors.white,
                                                  fontWeight: FontWeight.w700,
                                                ),
                                              ),
                                            ],
                                          );
                                        },
                                      ),
                                    ),
                                    barGroups: bars,
                                    groupsSpace: groupsSpace,
                                  ),
                                  swapAnimationDuration:
                                      const Duration(milliseconds: 250),
                                  swapAnimationCurve: Curves.easeInOut,
                                ),
                              ),
                            ),
                          ),
                      ],
                    );
                  },
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  // ------- data + helpers -------
  Map<String, int> _dynamicArcCounts(DataSnapshot? snapshot) {
    final Map<String, int> counts = {};
    final raw = snapshot?.value;
    if (raw is! Map) return counts;

    raw.forEach((_, v) {
      if (v is! Map) return;
      final role = (v['role'] ?? '').toString().trim().toLowerCase();
      if (role != 'student') return;

      final arcRaw =
          (v['playerDetails']?['arc'] ?? '').toString().trim().toLowerCase();
      final normalized = _normalizeArc(arcRaw);
      counts[normalized] = (counts[normalized] ?? 0) + 1;
    });

    return counts;
  }

  String _normalizeArc(String arc) {
    if (arc.isEmpty || arc.contains('not')) return 'Not Started';
    if (arc.contains('entertain')) return 'Entertainment Arc';
    if (arc.contains('recycl')) return 'Recycle Arc';
    if (arc.contains('art')) return 'Art Arc';

    final words = arc
        .split(RegExp(r'\s+'))
        .where((w) => w.isNotEmpty)
        .map((w) => w[0].toUpperCase() + (w.length > 1 ? w.substring(1) : ''))
        .join(' ');
    return words.isEmpty ? 'Not Started' : '$words Arc';
  }

  BarChartGroupData _bar(int x, int value, Color color, double barWidth) {
    return BarChartGroupData(
      x: x,
      barRods: [
        BarChartRodData(
          toY: value.toDouble(),
          width: barWidth,
          color: color,
          borderRadius: BorderRadius.circular(6),
        ),
      ],
    );
  }

  Color _colorForIndex(int i) {
    const palette = [
      Colors.blueAccent,
      Colors.orangeAccent,
      Colors.purpleAccent,
      Colors.teal,
      Colors.redAccent,
      Colors.indigoAccent,
      Colors.cyan,
      Colors.deepOrangeAccent,
      Colors.pinkAccent,
      Colors.amber,
      Colors.lightGreen,
      Colors.deepPurpleAccent,
    ];
    if (i < palette.length) return palette[i];
    final hue = (i * 37) % 360;
    return HSLColor.fromAHSL(1, hue.toDouble(), 0.65, 0.55).toColor();
  }
}

class _ArcLabel extends StatelessWidget {
  final String label;
  final bool isMobile;
  final double fontSize;

  const _ArcLabel({
    required this.label,
    required this.isMobile,
    required this.fontSize,
  });

  @override
  Widget build(BuildContext context) {
    String text = label;
    if (isMobile && label.toLowerCase().endsWith(' arc')) {
      final base = label.substring(0, label.length - 4);
      text = '$base\nArc';
    }
    return Text(
      text,
      textAlign: TextAlign.center,
      maxLines: isMobile ? 2 : 1,
      overflow: TextOverflow.ellipsis,
      style: TextStyle(fontSize: fontSize, fontWeight: FontWeight.w600),
    );
  }
}

class _EmptyState extends StatelessWidget {
  final double height;
  const _EmptyState({required this.height});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: height,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: const Color(0xFFF7F7F7),
        borderRadius: BorderRadius.circular(12),
      ),
      child: const Text(
        'No student data yet',
        style: TextStyle(color: Colors.black54),
      ),
    );
  }
}

double _niceInterval(double maxY) {
  final candidates = [1, 2, 5, 10, 20, 25, 50, 100];
  final target = (maxY / 6).clamp(1, double.infinity);
  for (final c in candidates) {
    if (c >= target) return c.toDouble();
  }
  return 100;
}

double _clampDouble(double v, double min, double max) {
  if (v < min) return min;
  if (v > max) return max;
  return v;
}
