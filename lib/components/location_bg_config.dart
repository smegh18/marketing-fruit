// // lib/background/location_bg_config.dart
// import 'dart:async';
// import 'package:shared_preferences/shared_preferences.dart';
// import 'package:flutter_background_geolocation/flutter_background_geolocation.dart' as bg;
// import 'location_service.dart';
//
// class LocationBgManager {
//   static const _kLastUploadKey = 'last_upload_iso';
//   static const Duration kUploadInterval = Duration(minutes: 15);
//
//   final String uid;
//   final LocationService _service;
//   DateTime? _lastUpload;
//   StreamSubscription<bg.Location>? _locSub;
//   StreamSubscription<bg.HeartbeatEvent>? _hbSub;
//
//   LocationBgManager(this.uid) : _service = LocationService(uid);
//
//   Future<void> _loadLastUpload() async {
//     final sp = await SharedPreferences.getInstance();
//     final iso = sp.getString(_kLastUploadKey);
//     if (iso != null) _lastUpload = DateTime.tryParse(iso);
//   }
//
//   Future<void> _saveLastUpload(DateTime t) async {
//     final sp = await SharedPreferences.getInstance();
//     await sp.setString(_kLastUploadKey, t.toIso8601String());
//     _lastUpload = t;
//   }
//
//   bool _shouldUploadNow(DateTime now) {
//     if (_lastUpload == null) return true;
//     return now.difference(_lastUpload!) >= kUploadInterval;
//   }
//
//   Future<void> _uploadNow(bg.Location loc) async {
//     final now = DateTime.now();
//     await _service.saveLocation(loc);
//     await _saveLastUpload(now);
//   }
//
//   /// Call this once (e.g., on dashboard init or after login)
//   Future<void> initAndStart() async {
//     await _loadLastUpload();
//
//     // Subscribe to location updates (movement-based)
//     bg.BackgroundGeolocation.onLocation((bg.Location location) async {
//       final now = DateTime.now();
//       if (_shouldUploadNow(now)) {
//         await _uploadNow(location);
//       }
//     });
//
//     // Heartbeat fires when app is in background/stationary at configured interval.
//     bg.BackgroundGeolocation.onHeartbeat((bg.HeartbeatEvent event) async {
//       // Force a single fresh fix and upload if due.
//       if (_shouldUploadNow(DateTime.now())) {
//         try {
//           final loc = await bg.BackgroundGeolocation.getCurrentPosition(
//             samples: 1,
//             persist: false,
//             maximumAge: 0,
//             timeout: 60,
//           );
//           await _uploadNow(loc);
//         } catch (_) {
//           // swallow; will try again next heartbeat
//         }
//       }
//     });
//
//     // One-time config
//     final state = await bg.BackgroundGeolocation.ready(bg.Config(
//       // Accuracy / cadence
//       desiredAccuracy: bg.Config.DESIRED_ACCURACY_HIGH,
//       distanceFilter: 50,                // movement trigger; not critical since heartbeat does hourly
//       stopTimeout: 5,                    // minutes until stationary state
//       // Lifecycle
//       stopOnTerminate: false,
//       startOnBoot: true,
//       enableHeadless: true,
//       // Background behavior
//       foregroundService: true,
//       heartbeatInterval: 15,             // minutes — fires even when stationary
//       pausesLocationUpdatesAutomatically: false,
//       preventSuspend: true,
//       // Logging
//       logLevel: bg.Config.LOG_LEVEL_OFF,
//       // Android notification
//       notification: bg.Notification(
//         title: "Background location enabled",
//         text: "Updating about once per hour",
//       ),
//       // iOS
//       showsBackgroundLocationIndicator: false,
//       allowIdenticalLocations: true,
//     ));
//
//     if (!state.enabled) {
//       await bg.BackgroundGeolocation.start();
//     }
//   }
//
//   Future<void> dispose() async {
//     await _locSub?.cancel();
//     await _hbSub?.cancel();
//   }
// }
