import 'package:flutter/material.dart';
import 'package:Marketing_Fruit/components/libsync_graph.dart';
import 'package:Marketing_Fruit/components/youtube_graph.dart';

class AdminContentScreen extends StatelessWidget {

  const AdminContentScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final horizontalPadding = screenWidth > 1000 ? screenWidth * 0.05 : 16.0;

    return Scaffold(
      backgroundColor: const Color(0xfff5f6fa),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            YouTubeViewsChart(),
            const SizedBox(height: 16),
            LibSyncViewsChart(),
          ],
        ),
      ),

    );
  }
}
