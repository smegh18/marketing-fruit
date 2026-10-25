import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import 'package:Marketing_Fruit/screens/dashboard/user_event_page.dart';

import '../../components/business_accuracy.dart';
import '../../components/explore_nft.dart';
import '../../components/global_rank.dart';
import '../../components/market_forecast.dart';
import '../../components/seminar_card.dart';
import '../../components/simulator_button.dart';
import '../../components/start_tracking.dart';
import '../../components/streak_calender.dart';
import 'leaderboard_widget.dart';

// Adapt data model for events.
class EventData {
  final String eventId;
  final String bannerUrl;
  final String eventName;
  final DateTime start;
  final String organizer;

  EventData({
    required this.eventId,
    required this.bannerUrl,
    required this.eventName,
    required this.start,
    required this.organizer,
  });

  factory EventData.fromMap(String key, Map<dynamic, dynamic> map) {
    String organizer =
        map['organizer'] ??
            ((map['placeFields'] != null)
                ? "${map['placeFields']['Venue Name'] ?? ''}${map['placeFields']['Area'] != null ? ', ${map['placeFields']['Area']}' : ''}"
                : '');

    return EventData(
      eventId: key,
      bannerUrl: map['bannerUrl'] ?? '',
      eventName: map['eventName'] ?? '',
      start: DateTime.fromMillisecondsSinceEpoch(
        (map['start'] ?? map['createdAt'] ?? 0),
      ),
      organizer: organizer.isNotEmpty ? organizer : 'Unknown',
    );
  }
}

class DashboardScreenMobile extends StatefulWidget {
  final bool showEvents ;
  final bool redirect ;
  final String name ;
  final String userRole;
  const DashboardScreenMobile({super.key,this.showEvents = false, this.redirect = false, this.name = '', required this.userRole});

  @override
  State<DashboardScreenMobile> createState() => _DashboardScreenMobileState();
}

class _DashboardScreenMobileState extends State<DashboardScreenMobile> {
  final PageController _simPageController = PageController(viewportFraction: 0.82);
  int _simPage = 0;
  final PageController _analyticsPageController = PageController(viewportFraction: 0.87);
  int _analyticsPage = 0;

  // Move showAllEvents outside build method so setState works correctly
  late bool showAllEvents;

  @override
  void initState() {
    super.initState();
    showAllEvents = widget.showEvents;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      startTrackingAfterLogin(context);
    });
  }

  @override
  void dispose() {
    _simPageController.dispose();
    _analyticsPageController.dispose();
    super.dispose();
  }

  Stream<List<EventData>> eventsStream() {
    final DatabaseReference eventsRef = FirebaseDatabase.instance.ref('events');
    return eventsRef.onValue.map((DatabaseEvent event) {
      final data = event.snapshot.value;

      if (data == null || (data is Map && data.isEmpty)) {
        return <EventData>[];
      }

      final eventsMap = Map<String, dynamic>.from(data as Map);
      final eventsList = eventsMap.entries.map((e) {
        final key = e.key;
        final value = Map<dynamic, dynamic>.from(e.value as Map);
        return EventData.fromMap(key, value);
      }).toList();

      eventsList.sort((a, b) => a.start.compareTo(b.start));
      return eventsList;
    });
  }

  @override
  Widget build(BuildContext context) {
    final String userId = FirebaseAuth.instance.currentUser?.uid ?? '';
    final double screenWidth = MediaQuery.of(context).size.width;
    const double horizontalPadding = 20.0;

    final dashboardView = ListView(
      padding: const EdgeInsets.symmetric(vertical: 20),
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: horizontalPadding),
          child: Text(
            "Simulator",
            style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
          ),
        ),
        const SizedBox(height: 14),
        SizedBox(
          height: 218,
          child: PageView.builder(
            controller: _simPageController,
            itemCount: 3,
            onPageChanged: (i) => setState(() => _simPage = i),
            itemBuilder: (context, idx) => Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: [SimulatorButton(), MarketForecastButton(), GlobalRankCard()][idx],
            ),
          ),
        ),
        const SizedBox(height: 8),
        Center(
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: List.generate(
              3,
                  (idx) => AnimatedContainer(
                duration: const Duration(milliseconds: 250),
                margin: const EdgeInsets.symmetric(horizontal: 4),
                width: _simPage == idx ? 20 : 6,
                height: 6,
                decoration: BoxDecoration(
                  color: _simPage == idx ? Theme.of(context).colorScheme.primary : Colors.grey.shade400,
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 32),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: horizontalPadding),
          child: Text(
            "Analytics",
            style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
          ),
        ),
        const SizedBox(height: 14),
        SizedBox(
          height: 378,
          child: PageView.builder(
            controller: _analyticsPageController,
            itemCount: 2,
            onPageChanged: (i) => setState(() => _analyticsPage = i),
            itemBuilder: (context, idx) => Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: [BusinessAccuracyWidget(width: screenWidth * 0.8), StreakCalendar(userId: userId, width: screenWidth * 0.8)][idx],
            ),
          ),
        ),
        const SizedBox(height: 8),
        Center(
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: List.generate(
              2,
                  (idx) => AnimatedContainer(
                duration: const Duration(milliseconds: 250),
                margin: const EdgeInsets.symmetric(horizontal: 4),
                width: _analyticsPage == idx ? 20 : 6,
                height: 6,
                decoration: BoxDecoration(
                  color: _analyticsPage == idx ? Theme.of(context).colorScheme.primary : Colors.grey.shade400,
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 32),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: horizontalPadding),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  "Events",
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                ),
              ),
              TextButton(
                onPressed: () {
                  setState(() { showAllEvents = true; });
                  print(showAllEvents);
                },
                child: const Text("View all events"),
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        EventCarousel(width: 0.9),
        const SizedBox(height: 32),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 1),
          child: ExploreNFTSection(width: screenWidth),
        ),
        const SizedBox(height: 32),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: horizontalPadding),
          child: LeaderboardWidget(width: screenWidth - 2 * horizontalPadding),
        ),
      ],
    );

    final allEventsView = StreamBuilder<List<EventData>>(
      stream: eventsStream(),
      builder: (context, snapshot) {
        final events = snapshot.data ?? [];
        return Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const SizedBox(height: 30),
            Center(
              child: Text(
                "Events",
                style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
              ),
            ),
            const SizedBox(height: 18),
            if (snapshot.connectionState == ConnectionState.waiting)
              const Center(child: CircularProgressIndicator())
            else if (events.isEmpty)
              const Center(child: Text("No events found")),
            ...events.map((event) => Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              child: InkWell(
                borderRadius: BorderRadius.circular(18),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => UserEventDashboardPage(eventId: event.eventId, userRole: widget.userRole)),
                  );
                },
                child: Card(
                  elevation: 5,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
                  clipBehavior: Clip.antiAlias,
                  child: Stack(
                    children: [
                      SizedBox(
                        height: 160,
                        width: double.infinity,
                        child: ColorFiltered(
                          colorFilter: ColorFilter.mode(
                              Colors.black.withOpacity(0.5), BlendMode.darken),
                          child: Image.network(
                            event.bannerUrl,
                            fit: BoxFit.cover,
                            color: Colors.black.withOpacity(0.5),
                            colorBlendMode: BlendMode.darken,
                          ),
                        ),
                      ),
                      Positioned.fill(
                        child: Container(
                          alignment: Alignment.center,
                          padding: const EdgeInsets.all(24),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.center,
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                event.eventName,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 22,
                                  shadows: [
                                    Shadow(offset: Offset(0, 2), blurRadius: 6, color: Colors.black38)
                                  ],
                                ),
                                textAlign: TextAlign.center,
                              ),
                              const SizedBox(height: 10),
                              Text(
                                DateFormat('dd MMM yyyy, hh:mm a').format(event.start),
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 16,
                                  shadows: [
                                    Shadow(offset: Offset(0, 1), blurRadius: 5, color: Colors.black38)
                                  ],
                                ),
                              ),
                              const SizedBox(height: 10),
                              Text(
                                "Organized by: ${event.organizer}",
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 15,
                                  fontWeight: FontWeight.w500,
                                  shadows: [
                                    Shadow(offset: Offset(0, 1), blurRadius: 5, color: Colors.black45)
                                  ],
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            )),
          ],
        );
      },
    );

    // AnimatedSwitcher for smooth transition, provide a key tied to showAllEvents state
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
        child: AnimatedSwitcher(
          duration: const Duration(milliseconds: 550),
          switchInCurve: Curves.easeIn,
          switchOutCurve: Curves.easeOut,
          child: showAllEvents
              ? SingleChildScrollView(
              key: const ValueKey('allEventsView'), // key makes AnimatedSwitcher recognize widget change
              child: allEventsView)
              : dashboardView, // consider adding a different ValueKey here if smoother transition needed
        ),
      ),
    );
  }
}
