import 'dart:async';
import 'dart:math' as math;
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';

class LiveVisitorsChart extends StatefulWidget {
  const LiveVisitorsChart({super.key, this.height = 320});
  final double height;

  @override
  State<LiveVisitorsChart> createState() => _LiveVisitorsChartState();
}

class _LiveVisitorsChartState extends State<LiveVisitorsChart> {
  final DatabaseReference _presenceRef =
  FirebaseDatabase.instance.ref('presence/users');

  StreamSubscription<DatabaseEvent>? _sub;
  Timer? _ticker;

  final List<FlSpot> _points = <FlSpot>[];
  double _x = 0;
  int _currentOnline = 0;

  static const int _maxPoints = 60;
  static const Duration _sampleEvery = Duration(seconds: 2);

  @override
  void initState() {
    super.initState();

    _sub = _presenceRef.onValue.listen((event) {
      int count = 0;
      final v = event.snapshot.value;
      if (v is Map) {
        count = v.length;
      } else if (v is List) {
        count = v.where((e) => e != null).length;
      } else {
        count = 0;
      }
      setState(() => _currentOnline = count);
    });

    _ticker = Timer.periodic(_sampleEvery, (_) {
      setState(() {
        _points.add(FlSpot(_x, _currentOnline.toDouble()));
        _x += 1;
        if (_points.length > _maxPoints) {
          _points.removeAt(0);
        }
      });
    });
  }

  @override
  void dispose() {
    _sub?.cancel();
    _ticker?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final spots = _points.isEmpty ? [const FlSpot(0, 0)] : _points;
    final maxYVal = spots.fold<double>(0, (m, s) => math.max(m, s.y));
    final maxY = (maxYVal <= 5 ? 5 : maxYVal + 1).toDouble();

    return SizedBox(
      height: widget.height,
      child: Card(
        elevation: 3,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: const [
                      Icon(Icons.show_chart, color: Colors.green),
                      SizedBox(width: 8),
                      Text(
                        "Live Visitors",
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                  Row(
                    children: [
                      const Icon(Icons.people, size: 16, color: Colors.grey),
                      const SizedBox(width: 6),
                      Text(
                        'Online: $_currentOnline',
                        style: const TextStyle(color: Colors.grey),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Expanded(
                child: LineChart(
                  LineChartData(
                    maxY: maxY,
                    minY: 0,
                    gridData: FlGridData(show: true),
                    titlesData: const FlTitlesData(
                      topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                      rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                      bottomTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                      leftTitles: AxisTitles(
                        sideTitles: SideTitles(showTitles: true, reservedSize: 28),
                      ),
                    ),
                    borderData: FlBorderData(show: false),
                    lineBarsData: [
                      LineChartBarData(
                        spots: spots,
                        isCurved: true,
                        barWidth: 2,
                        color: Colors.green,
                        dotData: FlDotData(show: false),
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
