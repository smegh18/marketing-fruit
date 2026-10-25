import 'package:flutter/material.dart';

import '../../components/history_section.dart';
import '../../components/industry_chart.dart';
import '../../components/stats_overview.dart';

class BrandDashboardPage extends StatelessWidget {
  final void Function(String role)? onStatCardTap;
  const BrandDashboardPage({super.key, this.onStatCardTap});

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;

    // Use the same side padding as the rest of the page so widths line up.
    final double horizontalPadding =
    screenWidth > 1000 ? screenWidth * 0.009 : 16.0;

    // One height for BOTH cards so they always match.
    const double panelHeight = 320;

    return Scaffold(
      backgroundColor: const Color(0xfff5f6fa),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            StatsOverviewSection(
              onStatCardTap: onStatCardTap,
              userRole: 'brand',
            ),

            // Live Visitors + History in the same row with equal height
            Padding(
              padding: EdgeInsets.symmetric(
                horizontal: horizontalPadding,
                vertical: 16,
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Expanded(
                  //   child: SizedBox(
                  //     height: panelHeight,
                  //     child: const LiveVisitorsChart(),
                  //   ),
                  // ),
                  // const SizedBox(width: 16),
                  Expanded(
                    child: SizedBox(
                      height: panelHeight,
                      child: const HistorySection(),
                    ),
                  ),
                ],
              ),
            ),

            // const SizedBox(height: 16),
            // const UserActivityChart(),
            const SizedBox(height: 16),
            const IndustryChartScreen(),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
}
