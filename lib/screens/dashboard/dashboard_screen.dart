import 'dart:async';
import 'dart:io';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:Marketing_Fruit/components/business_accuracy.dart';
import 'package:Marketing_Fruit/components/explore_content.dart';
import 'package:Marketing_Fruit/components/explore_nft.dart';
import 'package:Marketing_Fruit/components/seminar_card.dart';
import 'package:Marketing_Fruit/components/streak_calender.dart';
import 'package:Marketing_Fruit/screens/dashboard/leaderboard_widget.dart';
import '../../components/global_rank.dart';
import '../../components/location_service.dart';
import '../../components/market_forecast.dart';
import '../../components/player_details.dart';
import '../../components/session_prefs.dart';
import '../../components/simulator_button.dart';
import 'package:intl/intl.dart';

import '../../components/start_tracking.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  Timer? _locationTimer;
  // LocationBgManager? _bgManager;

  @override
  void initState() {
    super.initState();

    final playerDetails = PlayerDetails();
    final balance = playerDetails.fetchBalance();
    final userId = FirebaseAuth.instance.currentUser!.uid;

    if(kIsWeb){
      LocationService(userId).fetchAndStoreLocation();
    } else {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        startTrackingAfterLogin(context);
      });
    }

    // initLiveLocationService(context);


    //
    // if (!kIsWeb && (Platform.isAndroid || Platform.isIOS)) {
    //   _locationTimer = Timer.periodic(Duration(minutes: 15), (_) {
    //     LocationService(userId).fetchAndStoreLocation();
    //   });
    // }
    //
    // // ✅ Register background task only on mobile (not web)
    // if (!kIsWeb && (Platform.isAndroid || Platform.isIOS)) {
    //   Workmanager().registerPeriodicTask(
    //     "locationFetchTask",
    //     "locationFetchTask",
    //     frequency: const Duration(minutes: 16),
    //     inputData: {'userId': userId},
    //     constraints: Constraints(
    //       networkType: NetworkType.connected,
    //     ),
    //   );
    // }

    // ✅ Safe to call on both Web and Mobile
  }



  // Future<void> _initBackground() async {
  //   final user = FirebaseAuth.instance.currentUser;
  //   if (user == null) return;
  //
  //   if (Platform.isAndroid) {
  //     await scheduleAndroidHourly(user.uid);
  //   }
  //   // iOS: no background_fetch in this build — updates only when app is open.
  // }


  @override
  void dispose() {
    // _bgManager?.dispose();
    _locationTimer?.cancel();
    super.dispose();
  }



// Helper to save location with timestamp
  Future<void> saveLocationToFirebase(String userId, double latitude, double longitude) async {
    final dbRef = FirebaseDatabase.instance.ref();
    final now = DateTime.now();
    final date = DateFormat('yyyy-MM-dd').format(now);
    final time = DateFormat('HH:mm:ss').format(now);

    await dbRef
        .child('users/$userId/location history/$date/$time')
        .set({'latitude': latitude, 'longitude': longitude});
  }

// Stores last upload time
  DateTime? lastUpload;

  // void initLiveLocationService(BuildContext context) async {
  //   final user = FirebaseAuth.instance.currentUser;
  //   if (user == null) return;
  //
  //   // Listen for location events from plugin
  //   bg.BackgroundGeolocation.onLocation((bg.Location location) async {
  //     final now = DateTime.now();
  //     // Only upload if it's been 10 minutes since last upload
  //     if (lastUpload == null || now.difference(lastUpload!) >= Duration(minutes: 15)) {
  //       final coords = location.coords;
  //       await saveLocationToFirebase(user.uid, coords.latitude, coords.longitude);
  //       lastUpload = now;
  //     }
  //   });
  //
  //   bg.BackgroundGeolocation.ready(bg.Config(
  //     desiredAccuracy: bg.Config.DESIRED_ACCURACY_HIGH,
  //     distanceFilter: 100, // meters, location will be checked but only uploaded every 10 min
  //     stopOnTerminate: false,
  //     startOnBoot: true,
  //     foregroundService: true,
  //     logLevel: bg.Config.LOG_LEVEL_OFF,
  //     notification: bg.Notification(
  //       title: "Live Location Tracking",
  //       text: "Location updated every 10 minutes",
  //     ),
  //     enableHeadless: true,
  //   )).then((bg.State state) {
  //     if (!state.enabled) {
  //       bg.BackgroundGeolocation.start();
  //     }
  //   });
  //
  //   // Ask for permissions if needed (use only on Android)
  //   if (Theme.of(context).platform == TargetPlatform.android) {
  //     await bg.BackgroundGeolocation.requestPermission();
  //   }
  // }





  @override
  Widget build(BuildContext context) {
    final userId = FirebaseAuth.instance.currentUser!.uid;
    final playerDetails = PlayerDetails();
    playerDetails.updateStreak();

    final theme = Theme.of(context);
    final screenHeight = MediaQuery.of(context).size.height;
    final verticalPadding = screenHeight * 0.03;
    final spacing = screenHeight * 0.02;

    // Detect macOS to scale down for Retina displays
    final bool isMacOS = Theme.of(context).platform == TargetPlatform.macOS;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: Transform.scale(
        scale: isMacOS ? 0.96 : 1.0,
        alignment: Alignment.topCenter,
        child: SingleChildScrollView(
          padding: EdgeInsets.symmetric(horizontal: 24, vertical: verticalPadding),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // First Row
              LayoutBuilder(
                builder: (context, constraints) {
                  double rowSpacing = constraints.maxWidth * 0.02;
                  double itemWidth = (constraints.maxWidth - 2 * rowSpacing) / 3;

                  return Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SizedBox(width: itemWidth, child: SimulatorButton()),
                      SizedBox(width: rowSpacing),
                      SizedBox(width: itemWidth, child: MarketForecastButton()),
                      SizedBox(width: rowSpacing),
                      SizedBox(width: itemWidth, child: GlobalRankCard()),
                    ],
                  );
                },
              ),
              SizedBox(height: spacing),

              // Second Row
              LayoutBuilder(
                builder: (context, constraints) {
                  double rowSpacing = constraints.maxWidth * 0.02;
                  double itemWidth = (constraints.maxWidth - 2 * rowSpacing) / 3;

                  return Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SizedBox(width: itemWidth * 1.3, child: EventCarousel(width: 1.0)),
                      SizedBox(width: rowSpacing),
                      SizedBox(width: itemWidth * 0.7, child: BusinessAccuracyWidget(width: itemWidth)),
                      SizedBox(width: rowSpacing),
                      SizedBox(width: itemWidth, child: StreakCalendar(userId: userId, width: itemWidth)),
                    ],
                  );
                },
              ),
              SizedBox(height: spacing),

              // Explore Content
              LayoutBuilder(
                builder: (context, constraints) {
                  return ExploreContentSection(width: constraints.maxWidth);
                },
              ),
              SizedBox(height: spacing),

              // NFT Section
              LayoutBuilder(
                builder: (context, constraints) {
                  return ExploreNFTSection(width: constraints.maxWidth);
                },
              ),
              SizedBox(height: spacing),

              // Leaderboard Section
              LayoutBuilder(
                builder: (context, constraints) {
                  return LeaderboardWidget(width: constraints.maxWidth);
                },
              ),

            ],
          ),
        ),
      ),
    );
  }

  Future<void> onUserSignedIn() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;

    // Persist uid so the background isolate can write while app is closed
    await UserSession.saveUid(uid);

    // Ask for permissions (do this from foreground UI)
    LocationPermission perm = await Geolocator.checkPermission();
    if (perm == LocationPermission.denied || perm == LocationPermission.deniedForever) {
      perm = await Geolocator.requestPermission();
    }

    if (Platform.isAndroid) {
      // On Android 10+ you likely need "Allow all the time" for true background tracking
      // Guide the user to settings if needed:
      if (perm != LocationPermission.always && perm != LocationPermission.whileInUse) {
        await Geolocator.openAppSettings();
        await Geolocator.openLocationSettings();
      }
    }
}}
