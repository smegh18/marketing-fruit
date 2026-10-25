import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:Marketing_Fruit/components/activity_rate.dart';
import 'package:Marketing_Fruit/components/seminar_card.dart';
import 'package:Marketing_Fruit/components/total_student_button.dart';
import 'package:Marketing_Fruit/screens/dashboard/leaderboard_widget.dart';

import '../../components/player_details.dart';

class SchoolDashboardScreen extends StatefulWidget {
  final VoidCallback? onViewAllStudents;

  const SchoolDashboardScreen({super.key, this.onViewAllStudents});

  @override
  State<SchoolDashboardScreen> createState() => _SchoolDashboardScreenState();
}

class _SchoolDashboardScreenState extends State<SchoolDashboardScreen> {
  @override
  void initState() {
    super.initState();
    final playerDetails = PlayerDetails();
    final balance = playerDetails.fetchBalance();
  }

  @override
  Widget build(BuildContext context) {
    final userId = FirebaseAuth.instance.currentUser!.uid;
    final playerDetails = PlayerDetails();
    playerDetails.updateStreak();

    final theme = Theme.of(context);
    final screenHeight = MediaQuery.of(context).size.height;
    final verticalPadding = screenHeight * 0.03;
    final spacing = screenHeight * 0.02;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: SingleChildScrollView(
        padding: EdgeInsets.only(
          top: verticalPadding,
          bottom: verticalPadding,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            /// --- White container for both buttons (full width, no side gap) ---
            Container(
              width: double.infinity,
              color: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
              child: Row(
                children: [
                  Expanded(
                    child: StudentCountButton(
                      onViewAll: widget.onViewAllStudents,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: ActivityRateButton(),
                  ),
                ],
              ),
            ),

            SizedBox(height: spacing),

            LayoutBuilder(
              builder: (context, constraints) {
                return EventCarousel(width: 1.0);
              },
            ),
            SizedBox(height: spacing),
            Padding(
              padding: const EdgeInsets.only(left: 0),
              child: LayoutBuilder(
                builder: (context, constraints) {
                  return LeaderboardWidget(width: constraints.maxWidth);
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
