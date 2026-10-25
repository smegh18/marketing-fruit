import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:Marketing_Fruit/components/business_accuracy.dart';
import 'package:Marketing_Fruit/components/message_widget.dart';
import 'package:Marketing_Fruit/components/overallprogress.dart';
import 'package:Marketing_Fruit/components/streak_calender.dart';
import 'package:Marketing_Fruit/ecommerce/industryarcselection.dart';
import 'package:Marketing_Fruit/ecommerce/itemmarketplace.dart';

import '../../components/global_rank.dart';
import '../../components/market_forecast.dart';
import '../../components/player_details.dart';
import '../../components/profile_info.dart';
import '../../components/simulator_button.dart';

class ProfileScreen extends StatefulWidget {
  final String uid;
  final String userRole;

  const ProfileScreen({
    super.key,
    required this.userRole,
    this.onOpenConversation,
    this.uid = '',
  });

  /// NEW: callback to open the Messages tab with a specific peer
  final void Function(String peerUid, {String? peerName, String? peerRole})?
      onOpenConversation;

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  @override
  void initState() {
    super.initState();
    final playerDetails = PlayerDetails();
    final balance = playerDetails.fetchBalance();
  }

  @override
  Widget build(BuildContext context) {
    // Resolve userId safely (avoid null exceptions)
    final String userId = widget.uid.isEmpty
        ? (FirebaseAuth.instance.currentUser?.uid ?? '')
        : widget.uid;

    final playerDetails = PlayerDetails();
    playerDetails.updateStreak();

    final theme = Theme.of(context);
    final size = MediaQuery.of(context).size;
    final screenWidth = size.width;
    final screenHeight = size.height;
    final horizontalPadding = screenWidth * 0.02;
    final verticalPadding = screenHeight * 0.03;
    final spacing = screenHeight * 0.02;

    // ---- Normalize + decide minimal layout roles ---------------------------
    // Trim and lowercase; allow simple plural/typo robustness if needed later.
    final role = widget.userRole.trim().toLowerCase();
    print(role);
    final minimalRoles = {'guardian', 'school', 'brand'};
    final bool isMinimalRole = minimalRoles.contains(role);
    print(isMinimalRole);

    // ========== EARLY-RETURN LAYOUT FOR SCHOOL / BRAND / GUARDIAN ==========
    if (isMinimalRole) {
      return Scaffold(
        backgroundColor: theme.scaffoldBackgroundColor,
        body: SingleChildScrollView(
          padding: EdgeInsets.symmetric(
            horizontal: horizontalPadding,
            vertical: verticalPadding,
          ),
          child: LayoutBuilder(
            builder: (context, constraints) {
              final rowSpacing = constraints.maxWidth * 0.02;
              final itemWidth = (constraints.maxWidth - 2 * rowSpacing) / 2;

              return Row(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(
                    width: itemWidth,
                    child: ProfileInformationSection(
                      width: itemWidth,
                      userId: userId,
                      // role can be passed if your widget benefits from it:
                      // role: widget.userRole,
                    ),
                  ),
                  SizedBox(width: rowSpacing),
                  SizedBox(
                    width: itemWidth,
                    child: MessagesWidget(
                      // height: MediaQuery.of(context).size.height* 2.8,
                      width: itemWidth,
                      onOpenConversation: (peerUid, peerName, peerRole) =>
                          widget.onOpenConversation?.call(
                        peerUid,
                        peerName: peerName,
                        peerRole: peerRole,
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      );
    } else {
      return Scaffold(
        backgroundColor: theme.scaffoldBackgroundColor,
        body: SingleChildScrollView(
          padding: EdgeInsets.symmetric(
            horizontal: horizontalPadding,
            vertical: verticalPadding,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Top row: Profile + Messages
              LayoutBuilder(
                builder: (context, constraints) {
                  final rowSpacing = constraints.maxWidth * 0.02;
                  final itemWidth = (constraints.maxWidth - 2 * rowSpacing) / 2;

                  return Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SizedBox(
                        width: itemWidth,
                        child: ProfileInformationSection(
                          width: itemWidth,
                          userId: userId,
                        ),
                      ),
                      SizedBox(width: rowSpacing),
                      SizedBox(
                        width: itemWidth,
                        child: MessagesWidget(
                          width: itemWidth,
                          onOpenConversation: (peerUid, peerName, peerRole) =>
                              widget.onOpenConversation?.call(
                                peerUid,
                                peerName: peerName,
                                peerRole: peerRole,
                              ),
                        ),
                      ),
                    ],
                  );
                },
              ),

              SizedBox(height: spacing),

              // Marketplace
              LayoutBuilder(
                builder: (context, constraints) {
                  return MarketplaceSection(width: constraints.maxWidth);
                },
              ),

              SizedBox(height: spacing * 1.4),

              // Simulator / Forecast / Global Rank
              LayoutBuilder(
                builder: (context, constraints) {
                  final rowSpacing = constraints.maxWidth * 0.02;
                  final itemWidth = (constraints.maxWidth - 2 * rowSpacing) / 3;

                  return Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SizedBox(width: itemWidth, child: const SimulatorButton()),
                      SizedBox(width: rowSpacing),
                      SizedBox(width: itemWidth, child: const MarketForecastButton()),
                      SizedBox(width: rowSpacing),
                      SizedBox(width: itemWidth, child: const GlobalRankCard()),
                    ],
                  );
                },
              ),

              SizedBox(height: spacing),

              // Analytics Row
              LayoutBuilder(
                builder: (context, constraints) {
                  final rowSpacing = constraints.maxWidth * 0.02;
                  final itemWidth = (constraints.maxWidth - 2 * rowSpacing) / 3;

                  return Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SizedBox(
                        width: itemWidth,
                        child: BusinessAccuracyWidget(width: itemWidth),
                      ),
                      SizedBox(width: rowSpacing),
                      SizedBox(
                        width: itemWidth,
                        child: StreakCalendar(userId: userId, width: itemWidth),
                      ),
                      SizedBox(width: rowSpacing),
                      SizedBox(
                        width: itemWidth,
                        child: OverallProgressWidget(width: itemWidth),
                      ),
                    ],
                  );
                },
              ),

              SizedBox(height: spacing),

              // Industry Arc
              LayoutBuilder(
                builder: (context, constraints) {
                  final availableWidth = constraints.maxWidth;
                  return IndustryArcSection(width: availableWidth);
                },
              ),
            ],
          ),
        ),
      );
    }

    // ========== FULL DASHBOARD LAYOUT (e.g., Student) =======================

  }
}
