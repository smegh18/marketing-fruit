import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class OverallProgressWidget extends StatefulWidget {
  final double width;
  final bool disabled;
  const OverallProgressWidget({
    super.key,
    required this.width,
    this.disabled = false,
  });

  @override
  State<OverallProgressWidget> createState() => _OverallProgressWidgetState();
}

class _OverallProgressWidgetState extends State<OverallProgressWidget> {
  int? touchedIndex;
  double progressPercent = 75.0;

  List<PieChartSectionData> showingSections() {
    return [
      PieChartSectionData(
        color: Colors.orange,
        value: progressPercent,
        title: "${progressPercent.toInt()}%",
        radius: touchedIndex == 0 ? 50 : 45,
        titleStyle: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
        borderSide: touchedIndex == 0
            ? BorderSide(color: Colors.white.withOpacity(0.7), width: 6)
            : BorderSide.none,
      ),
      PieChartSectionData(
        color: Colors.grey.shade300,
        value: 100 - progressPercent,
        title: '',
        radius: touchedIndex == 1 ? 50 : 45,
        borderSide: BorderSide.none,
      ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final dpi = MediaQueryData.fromView(WidgetsBinding.instance.window).devicePixelRatio;
    double scale = 1.0;
    if (dpi > 1.0 && dpi < 2.0) {
      scale = 1.16;
    } else if (dpi >= 2.0)
      scale = 0.9;

    return IgnorePointer(
      ignoring: widget.disabled,
      child: Opacity(
        opacity: widget.disabled ? 0.85 : 1.0,
        child: LayoutBuilder(
          builder: (context, constraints) {
            final fullWidth = MediaQuery.of(context).size.width;
            final width = fullWidth * widget.width;
            final height = 400.0 * scale;

            return SizedBox(
              width: width,
              height: height,
              child: Container(
                decoration: BoxDecoration(
                  color: theme.cardColor,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.5),
                      blurRadius: 8,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: [
                    Text(
                      'Overall Progress',
                      style: GoogleFonts.poppins(
                        color: theme.hintColor,
                        fontWeight: FontWeight.bold,
                        fontSize: 22,
                      ),
                    ),
                    const SizedBox(height: 20),
                    Expanded(
                      child: PieChart(
                        PieChartData(
                          centerSpaceRadius: 40,
                          sectionsSpace: 1.5,
                          startDegreeOffset: -90,
                          pieTouchData: PieTouchData(
                            touchCallback: (event, response) {
                              setState(() {
                                if (!event.isInterestedForInteractions ||
                                    response == null ||
                                    response.touchedSection == null) {
                                  touchedIndex = null;
                                } else {
                                  touchedIndex =
                                      response.touchedSection!.touchedSectionIndex;
                                }
                              });
                            },
                          ),
                          sections: showingSections(),
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    LegendItems(
                      color1: Colors.orange,
                      label1: 'Progress',
                      color2: Colors.grey.shade300,
                      label2: 'Remaining',
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

class LegendItems extends StatelessWidget {
  final Color color1;
  final String label1;
  final Color color2;
  final String label2;

  const LegendItems({
    super.key,
    required this.color1,
    required this.label1,
    required this.color2,
    required this.label2,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final dpi = MediaQueryData.fromView(WidgetsBinding.instance.window).devicePixelRatio;
    double scale = 1.0;
    if (dpi > 1.0) {
      scale = 0.4;
    } else if (dpi >= 2.0)
      scale = 1.0;

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(Icons.circle, color: color1, size: 16),
        const SizedBox(width: 8),
        Text(label1, style: TextStyle(color: theme.hintColor)),
        SizedBox(width: 24 * scale),
        Icon(Icons.circle, color: color2, size: 16),
        const SizedBox(width: 8),
        Text(label2, style: TextStyle(color: theme.hintColor)),
      ],
    );
  }
}
