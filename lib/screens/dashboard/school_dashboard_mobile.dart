import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../../components/activity_rate.dart';
import '../../components/seminar_card.dart';
import '../../components/total_student_button.dart';
import '../../components/player_details.dart';
import 'leaderboard_widget.dart';
import 'package:smooth_page_indicator/smooth_page_indicator.dart';

class SchoolDashboardMobileScreen extends StatefulWidget {
  final VoidCallback? onViewAllStudents;
  final bool redirect;
  final String name;
  const SchoolDashboardMobileScreen({super.key, this.onViewAllStudents,  this.redirect = false, this.name = ''});

  @override
  State<SchoolDashboardMobileScreen> createState() => _SchoolDashboardMobileScreenState();
}

class _SchoolDashboardMobileScreenState extends State<SchoolDashboardMobileScreen> {
  @override
  void initState() {
    super.initState();
    final playerDetails = PlayerDetails();
    final balance = playerDetails.fetchBalance();
    playerDetails.updateStreak();
  }

  @override
  Widget build(BuildContext context) {
    final String userId = FirebaseAuth.instance.currentUser?.uid ?? '';
    final double screenWidth = MediaQuery.of(context).size.width;
    final double spacing = 20.0;
    final double cardHeight = 120.0;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: widget.redirect ? AppBar(
        elevation: 0,
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, size: 32),
          onPressed: () {
            Navigator.pop(context);
          },
          tooltip: "Back",
        ),
        title: Text(
          '${widget.name}\'s Dashboard',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w600),
        ),
      ) : null,
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.symmetric(vertical: 20),
          children: [
            // Section: Quick Actions - Scroller Row
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14),
              child: Text(
                "Quick Actions",
                style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
              ),
            ),
            SizedBox(height: 8),
            QuickActionsScroller(onViewAllStudents: widget.onViewAllStudents),
            SizedBox(height: spacing),

            // Section: Events Carousel
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14),
              child: Text(
                "Events",
                style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
              ),
            ),
            SizedBox(height: 8),
            EventCarousel(width: 0.92),
            SizedBox(height: spacing),

            // Section: Leaderboard
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14),
              child: Text(
                "Leaderboard",
                style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
              ),
            ),
            SizedBox(height: 8),
            LeaderboardWidget(width: screenWidth - 28),
            SizedBox(height: spacing),
          ],
        ),
      ),
    );
  }
}


class QuickActionsScroller extends StatefulWidget {
  final VoidCallback? onViewAllStudents;
  const QuickActionsScroller({super.key, this.onViewAllStudents});

  @override
  State<QuickActionsScroller> createState() => _QuickActionsScrollerState();
}

class _QuickActionsScrollerState extends State<QuickActionsScroller> {
  final PageController _pageController = PageController(viewportFraction: 0.82);
  int _currentPage = 0;

  final List<Widget> _quickActionWidgets = [];

  @override
  void initState() {
    super.initState();
    _quickActionWidgets.addAll([
      StudentCountButton(onViewAll: widget.onViewAllStudents),
      ActivityRateButton(),
      // Add more widgets here if needed
    ]);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final double cardHeight = 185.0;
    return SizedBox(
      height: cardHeight + 24,
      width: MediaQuery.of(context).size.width * 0.8,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            height: cardHeight,
            child: PageView.builder(
              controller: _pageController,
              itemCount: _quickActionWidgets.length,
              onPageChanged: (i) => setState(() => _currentPage = i),
              itemBuilder: (context, idx) => Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4),
                child: _quickActionWidgets[idx],
              ),
            ),
          ),
          const SizedBox(height: 8),
          SmoothPageIndicator(
            controller: _pageController,
            count: _quickActionWidgets.length,
            effect: WormEffect(
                dotHeight: 10,
                dotWidth: 10,
                spacing: 12,
                dotColor: Colors.grey.shade400,
                activeDotColor: Theme.of(context).colorScheme.primary),
          ),
        ],
      ),
    );
  }
}

