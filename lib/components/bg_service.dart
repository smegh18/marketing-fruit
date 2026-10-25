import 'dart:async';
import 'dart:ui';

import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_background_service/flutter_background_service.dart';
import 'package:geolocator/geolocator.dart';
import 'package:firebase_core/firebase_core.dart';

import '../firebase_options.dart';
import 'event_attendance_checker.dart';
import 'location_service.dart';
import 'session_prefs.dart';

const Duration kHeartbeat = Duration(hours: 1);
const Duration kEventPollInterval = Duration(seconds: 30);
const Duration kEventCheckInterval = Duration(minutes: 5);
const LocationSettings kLocationSettings = LocationSettings(
  accuracy: LocationAccuracy.high,
  distanceFilter: 0,
);

Future<void> _ensureFirebase() async {
  try {
    Firebase.app();
  } catch (_) {
    await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  }
}

Future<void> configureBackgroundService() async {
  final service = FlutterBackgroundService();
  await service.configure(
    androidConfiguration: AndroidConfiguration(
      onStart: onServiceStart,
      autoStart: false,
      isForegroundMode: true,
      // Use plugin defaults for channel/id & icon (ic_bg_service_small)
      initialNotificationTitle: 'Event Attendance Service',
      initialNotificationContent: 'Ready to verify your presence at scheduled events',
    ),
    iosConfiguration: IosConfiguration(
      autoStart: false,
      onForeground: onServiceStart,
      onBackground: onIosBackground,
    ),
  );
}

Future<void> startBackgroundService() async {
  final service = FlutterBackgroundService();
  final running = await service.isRunning();
  if (!running) {
    await service.startService();
  } else {
    service.invoke('refresh');
  }
}

@pragma('vm:entry-point')
Future<bool> onIosBackground(ServiceInstance service) async {
  WidgetsFlutterBinding.ensureInitialized();
  await _ensureFirebase();

  final uid = await UserSession.readUid();
  if (uid == null) return true;

  final svc = LocationService(uid);
  if (!await svc.hasPermissions()) return true;

  final pos = await svc.getPosition();
  await svc.saveToFirebase(lat: pos?.latitude, lng: pos?.longitude);

  // Also check event attendance on iOS background wake
  if (pos != null) {
    final checker = EventAttendanceChecker(uid);
    await checker.checkAndMarkAttendance(
      userLat: pos.latitude,
      userLng: pos.longitude,
    );
  }
  return true;
}

@pragma('vm:entry-point')
void onServiceStart(ServiceInstance service) async {
  DartPluginRegistrant.ensureInitialized();
  WidgetsFlutterBinding.ensureInitialized();
  await _ensureFirebase();

  // Give a tiny delay so engine/notification resources are ready
  await Future.delayed(const Duration(milliseconds: 200));

  if (service is AndroidServiceInstance) {
    try {
      service.setAsForegroundService();
      service.setForegroundNotificationInfo(
        title: 'Location tracking',
        content: 'Active',
      );
    } catch (_) {
      // If notification permission missing on Android 13+, this will throw.
    }
  }

  service.on('stopService').listen((_) async {
    await service.stopSelf();
  });

  service.on('refresh').listen((_) async {
    if (service is AndroidServiceInstance) {
      try {
        service.setForegroundNotificationInfo(
          title: 'Location tracking',
          content: 'Active',
        );
      } catch (_) {}
    }
  });

  StreamSubscription<Position>? streamSub;
  Timer? heartbeat;
  DateTime lastWrite = DateTime.fromMillisecondsSinceEpoch(10);

  Future<void> writeIfDue([Position? pos]) async {
    final uid = await UserSession.readUid();
    if (uid == null) return;

    final svc = LocationService(uid);
    if (!await svc.hasPermissions()) return;

    final now = DateTime.now();
    if (pos != null && now.difference(lastWrite) < const Duration(seconds: 10)) return;

    final p = pos ?? await svc.getPosition();
    print(p?.latitude);
    await svc.saveToFirebase(lat: p?.latitude, lng: p?.longitude);
    lastWrite = now;
  }

  try {
    final uid = await UserSession.readUid();
    if (uid != null) {
      final svc = LocationService(uid);
      if (await svc.hasPermissions()) {
        streamSub = Geolocator.getPositionStream(locationSettings: kLocationSettings)
            .listen((p) async {
          try { await writeIfDue(p); } catch (_) {}
        });
      }
    }
  } on PlatformException {
    // user hasn’t granted yet
  } catch (_) {}

  heartbeat = Timer.periodic(kHeartbeat, (_) async {
    try { await writeIfDue(); } catch (_) {}
  });

  // --- Event-aware attendance polling ---
  Timer? eventPollTimer;
  bool isEventMode = false;

  Future<void> evaluateEventMode() async {
    final uid = await UserSession.readUid();
    if (uid == null) return;

    final checker = EventAttendanceChecker(uid);
    final hasActive = await checker.hasActiveEvent();

    if (hasActive && !isEventMode) {
      // Switch to event mode: 30-second GPS polling with geofence check
      isEventMode = true;
      eventPollTimer?.cancel();
      eventPollTimer = Timer.periodic(kEventPollInterval, (_) async {
        try {
          final uid = await UserSession.readUid();
          if (uid == null) return;
          final svc = LocationService(uid);
          if (!await svc.hasPermissions()) return;
          final pos = await svc.getPositionWithTimeout();
          if (pos == null) return;

          await svc.saveToFirebase(lat: pos.latitude, lng: pos.longitude);
          lastWrite = DateTime.now();

          final c = EventAttendanceChecker(uid);
          await c.checkAndMarkAttendance(
            userLat: pos.latitude,
            userLng: pos.longitude,
          );
        } catch (_) {}
      });

      if (service is AndroidServiceInstance) {
        try {
          service.setForegroundNotificationInfo(
            title: 'Event attendance tracking',
            content: 'Monitoring your location for active event',
          );
        } catch (_) {}
      }
    } else if (!hasActive && isEventMode) {
      // Revert to normal mode
      isEventMode = false;
      eventPollTimer?.cancel();
      eventPollTimer = null;

      if (service is AndroidServiceInstance) {
        try {
          service.setForegroundNotificationInfo(
            title: 'Location tracking',
            content: 'Active',
          );
        } catch (_) {}
      }
    }
  }

  // Check for event mode on startup
  try { await evaluateEventMode(); } catch (_) {}

  // Re-evaluate every 5 minutes
  final eventCheckTimer = Timer.periodic(kEventCheckInterval, (_) async {
    try { await evaluateEventMode(); } catch (_) {}
  });

  service.on('dispose').listen((_) async {
    await streamSub?.cancel();
    heartbeat?.cancel();
    eventPollTimer?.cancel();
    eventCheckTimer.cancel();
  });
}
