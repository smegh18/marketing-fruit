import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

class LibSyncViewsChart extends StatefulWidget {
  const LibSyncViewsChart({super.key});

  @override
  State<LibSyncViewsChart> createState() => _LibSyncViewsChartState();
}

class _LibSyncViewsChartState extends State<LibSyncViewsChart> {
  String selectedMonth = 'August';

  final List<String> months = ['August', 'July', 'June'];

  final List<FlSpot> libSyncViewData = [
    FlSpot(1, 300),
    FlSpot(2, 450),
    FlSpot(3, 380),
    FlSpot(4, 600),
  ];

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;

    return Center(
      child: Card(
        margin: const EdgeInsets.all(16),
        elevation: 4,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Header with dropdown
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Marketing Fruit LibSync Views Analysis',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  DropdownButton<String>(
                    value: selectedMonth,
                    items: months
                        .map((month) =>
                        DropdownMenuItem(value: month, child: Text(month)))
                        .toList(),
                    onChanged: (value) {
                      if (value != null) {
                        setState(() => selectedMonth = value);
                      }
                    },
                  ),
                ],
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: screenWidth * 0.85,
                height: 300,
                child: LineChart(
                  LineChartData(
                    minY: 0,
                    maxY: 600,
                    gridData: FlGridData(show: true),
                    titlesData: FlTitlesData(
                      leftTitles: AxisTitles(
                        axisNameWidget: const Text("Views"),
                        axisNameSize: 28,
                        sideTitles: SideTitles(
                          showTitles: true,
                          reservedSize: 40,
                          interval: 100,
                          getTitlesWidget: (value, meta) {
                            if (value % 100 == 0) {
                              return Text(value.toInt().toString());
                            }
                            return const SizedBox.shrink();
                          },
                        ),
                      ),
                      bottomTitles: AxisTitles(
                        axisNameWidget: const Text("Week"),
                        axisNameSize: 28,
                        sideTitles: SideTitles(
                          showTitles: true,
                          getTitlesWidget: (value, meta) {
                            switch (value.toInt()) {
                              case 1:
                                return const Text('1');
                              case 2:
                                return const Text('2');
                              case 3:
                                return const Text('3');
                              case 4:
                                return const Text('4');
                              default:
                                return const Text('');
                            }
                          },
                        ),
                      ),
                      rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                      topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    ),
                    borderData: FlBorderData(show: true),
                    lineBarsData: [
                      LineChartBarData(
                        spots: libSyncViewData,
                        isCurved: false,
                        color: Colors.blueAccent,
                        barWidth: 3,
                        dotData: FlDotData(show: true),
                        belowBarData: BarAreaData(
                          show: true,
                          gradient: LinearGradient(
                            colors: [Colors.blueAccent.withOpacity(0.3), Colors.transparent],
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                          ),
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
