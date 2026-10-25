import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'package:Marketing_Fruit/components/business_accuracy.dart';
import 'package:Marketing_Fruit/components/streak_calender.dart';
import 'package:Marketing_Fruit/components/overallprogress.dart';
import 'package:Marketing_Fruit/components/message_widget.dart';
import 'package:Marketing_Fruit/components/profile_info.dart';
import 'package:Marketing_Fruit/components/simulator_button.dart';
import 'package:Marketing_Fruit/components/market_forecast.dart';
import 'package:Marketing_Fruit/components/global_rank.dart';
import 'package:Marketing_Fruit/ecommerce/industryarcselection.dart';
import 'package:Marketing_Fruit/ecommerce/itemmarketplace.dart';

class ProfileScreenMobile extends StatefulWidget {
  final String userRole;
  final String uid;
  final String name;

  const ProfileScreenMobile({
    super.key,
    required this.userRole,
    this.uid = '',
    this.name = '',
    this.onOpenConversation,
  });

  final void Function(String peerUid, {String? peerName, String? peerRole})?
      onOpenConversation;

  @override
  State<ProfileScreenMobile> createState() => _ProfileScreenMobileState();
}

class _ProfileScreenMobileState extends State<ProfileScreenMobile> {
  final PageController _simPageController =
      PageController(viewportFraction: 0.91);
  int _simPage = 0;

  final PageController _analyticsPageController =
      PageController(viewportFraction: 0.91);
  int _analyticsPage = 0;

  @override
  void dispose() {
    _simPageController.dispose();
    _analyticsPageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Resolve userId safely as a non-null String
    final String userId = widget.uid.isEmpty
        ? (FirebaseAuth.instance.currentUser?.uid ?? '')
        : widget.uid;

    final double screenWidth = MediaQuery.of(context).size.width;
    const double horizontalPadding = 18.0;
    const double sectionSpacing = 24.0;

    // Normalize role for robust comparisons
    final String role = widget.userRole.toLowerCase();

    // Simulator scroller widgets
    final List<Widget> simulatorWidgets = const [
      SimulatorButton(),
      MarketForecastButton(),
      GlobalRankCard(),
    ];

    // Analytics scroller widgets
    final List<Widget> analyticsWidgets = [
      BusinessAccuracyWidget(width: screenWidth * 0.82),
      StreakCalendar(userId: userId, width: screenWidth * 0.82),
      OverallProgressWidget(width: screenWidth * 0.82),
    ];

    // Minimal layout for Guardian/School/Brand
    final bool isMinimalRole =
        role == 'guardian' || role == 'school' || role == 'brand';

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: widget.uid.isEmpty
          ? null
          : AppBar(
              backgroundColor: Theme.of(context).scaffoldBackgroundColor,
              elevation: 0,
              leading: IconButton(
                onPressed: () => Navigator.pop(context),
                icon: const Icon(Icons.arrow_back_ios),
              ),
              title: Text(
                "Profile",
                style: Theme.of(context)
                    .textTheme
                    .titleLarge
                    ?.copyWith(fontWeight: FontWeight.bold),
              ),
            ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.symmetric(
              horizontal: horizontalPadding, vertical: 18),
          children: [
            // Profile section (always visible)
            ProfileInformationSection(
              width: screenWidth,
              userId: userId,
            ),

            // ===== Guardian / School / Brand: ONLY Profile + Messages =====
            if (isMinimalRole) ...[
              const SizedBox(height: sectionSpacing * 0.75),
              MessagesWidget(
                width: screenWidth - 2 * horizontalPadding,
                onOpenConversation:
                    (peerUid, peerName, peerRole) => widget.onOpenConversation
                        ?.call(peerUid, peerName: peerName, peerRole: peerRole),
              ),
            ],

            // ===== Student: Full layout =====
            if (!isMinimalRole && role == 'student') ...[
              const SizedBox(height: sectionSpacing * 0.75),

              // Messages
              MessagesWidget(
                width: screenWidth - 2 * horizontalPadding,
                onOpenConversation:
                    (peerUid, peerName, peerRole) => widget.onOpenConversation
                        ?.call(peerUid, peerName: peerName, peerRole: peerRole),
              ),
              const SizedBox(height: sectionSpacing * 0.75),

              // Marketplace
              MarketplaceSection(width: screenWidth - 2 * horizontalPadding),
              const SizedBox(height: sectionSpacing),

              // Simulator section w/ Heading & PageView
              Text(
                "Simulator",
                style: Theme.of(context)
                    .textTheme
                    .titleLarge
                    ?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),
              SizedBox(
                height: 218,
                child: PageView.builder(
                  controller: _simPageController,
                  itemCount: simulatorWidgets.length,
                  onPageChanged: (i) => setState(() => _simPage = i),
                  itemBuilder: (context, idx) => Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 3),
                    child: simulatorWidgets[idx],
                  ),
                ),
              ),
              const SizedBox(height: 6),
              Center(
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: List.generate(
                    simulatorWidgets.length,
                    (idx) => AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      margin: const EdgeInsets.symmetric(horizontal: 4),
                      width: _simPage == idx ? 18 : 7,
                      height: 6,
                      decoration: BoxDecoration(
                        color: _simPage == idx
                            ? Theme.of(context).colorScheme.primary
                            : Colors.grey.shade400,
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: sectionSpacing),

              // Analytics section w/ Heading & PageView
              Text(
                "Analytics",
                style: Theme.of(context)
                    .textTheme
                    .titleLarge
                    ?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),
              SizedBox(
                height: 378,
                child: PageView.builder(
                  controller: _analyticsPageController,
                  itemCount: analyticsWidgets.length,
                  onPageChanged: (i) => setState(() => _analyticsPage = i),
                  itemBuilder: (context, idx) => Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 3),
                    child: analyticsWidgets[idx],
                  ),
                ),
              ),
              const SizedBox(height: 6),
              Center(
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: List.generate(
                    analyticsWidgets.length,
                    (idx) => AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      margin: const EdgeInsets.symmetric(horizontal: 4),
                      width: _analyticsPage == idx ? 18 : 7,
                      height: 6,
                      decoration: BoxDecoration(
                        color: _analyticsPage == idx
                            ? Theme.of(context).colorScheme.primary
                            : Colors.grey.shade400,
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: sectionSpacing),

              // Industry Arc Section
              IndustryArcSection(width: screenWidth),
            ],
          ],
        ),
      ),
    );
  }
}
