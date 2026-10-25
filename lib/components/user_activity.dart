import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

class UserActivityChart extends StatefulWidget {
  const UserActivityChart({super.key});

  @override
  State<UserActivityChart> createState() => _UserActivityChartState();
}

class _UserActivityChartState extends State<UserActivityChart> {
  String selectedRole = 'All';

  final List<String> roles = ['All', 'User', 'Brand', 'Guardian', 'School'];

  final Map<String, List<FlSpot>> roleData = {
    'User': [FlSpot(1, 200), FlSpot(2, 300), FlSpot(3, 200), FlSpot(4, 400)],
    'Brand': [FlSpot(1, 300), FlSpot(2, 200), FlSpot(3, 500), FlSpot(4, 300)],
    'Guardian': [FlSpot(1, 100), FlSpot(2, 400), FlSpot(3, 200), FlSpot(4, 500)],
    'School': [FlSpot(1, 400), FlSpot(2, 100), FlSpot(3, 300), FlSpot(4, 400)],
  };

  final Map<String, Color> roleColors = {
    'User': Colors.blue,
    'Brand': Colors.orange,
    'Guardian': Colors.green,
    'School': Colors.purple,
  };

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;

    return Card(
      margin: const EdgeInsets.all(16),
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            // Header with Dropdown
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                DropdownButton<String>(
                  value: selectedRole,
                  items: roles
                      .map((role) =>
                      DropdownMenuItem(value: role, child: Text(role)))
                      .toList(),
                  onChanged: (value) {
                    if (value != null) {
                      setState(() => selectedRole = value);
                    }
                  },
                ),
                const Text(
                  'User Activity',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // Chart
            SizedBox(
              height: screenHeight * 0.45,
              width: screenWidth * 0.75,
              child: LineChart(
                LineChartData(
                  minX: 1,
                  maxX: 4,
                  minY: 0,
                  maxY: 600,
                  gridData: FlGridData(show: true),
                  titlesData: FlTitlesData(
                    leftTitles: AxisTitles(
                      axisNameWidget: const Padding(
                        padding: EdgeInsets.only(right: 8),
                        child: Text("Users"),
                      ),
                      axisNameSize: 28,
                      sideTitles: SideTitles(
                        showTitles: true,
                        interval: 100,
                        reservedSize: 40,
                        getTitlesWidget: (value, meta) {
                          if (value % 100 == 0 && value <= 600) {
                            return Text(value.toInt().toString());
                          }
                          return const SizedBox.shrink();
                        },
                      ),
                    ),
                    bottomTitles: AxisTitles(
                      axisNameWidget: const Padding(
                        padding: EdgeInsets.only(top: 12),
                        child: Text("Sessions"),
                      ),
                      axisNameSize: 28,
                      sideTitles: SideTitles(
                        showTitles: true,
                        interval: 1,
                        reservedSize: 30,
                        getTitlesWidget: (value, meta) {
                          switch (value.toInt()) {
                            case 1:
                              return const Padding(
                                padding: EdgeInsets.only(top: 8),
                                child: Text('S1'),
                              );
                            case 2:
                              return const Padding(
                                padding: EdgeInsets.only(top: 8),
                                child: Text('S2'),
                              );
                            case 3:
                              return const Padding(
                                padding: EdgeInsets.only(top: 8),
                                child: Text('S3'),
                              );
                            case 4:
                              return const Padding(
                                padding: EdgeInsets.only(top: 8),
                                child: Text('S4'),
                              );
                            default:
                              return const SizedBox.shrink();
                          }
                        },
                      ),
                    ),
                    rightTitles:
                    AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    topTitles:
                    AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  ),
                  borderData: FlBorderData(show: true),
                  lineBarsData: selectedRole == 'All'
                      ? roleData.entries.map((entry) {
                    return LineChartBarData(
                      spots: entry.value,
                      isCurved: false,
                      color: roleColors[entry.key],
                      barWidth: 2.5,
                      dotData: FlDotData(show: false),
                      belowBarData: BarAreaData(
                        show: true,
                        gradient: LinearGradient(
                          colors: [
                            roleColors[entry.key]!.withOpacity(0.4),
                            Colors.transparent,
                          ],
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                        ),
                      ),
                    );
                  }).toList()
                      : [
                    LineChartBarData(
                      spots: roleData[selectedRole]!,
                      isCurved: false,
                      color: roleColors[selectedRole],
                      barWidth: 3,
                      dotData: FlDotData(show: true),
                      belowBarData: BarAreaData(
                        show: true,
                        gradient: LinearGradient(
                          colors: [
                            roleColors[selectedRole]!.withOpacity(0.4),
                            Colors.transparent,
                          ],
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
    );
  }
}
