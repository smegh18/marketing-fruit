import 'dart:io';
import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:geolocator/geolocator.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'location_disclosure.dart';
import 'session_prefs.dart';
import 'bg_service.dart';

/// Starts background location tracking after the user logs in.
///
/// A [BuildContext] is required so that the Google-Play-compliant
/// prominent-disclosure dialog can be shown before requesting
/// location permissions.
Future<void> startTrackingAfterLogin(BuildContext context) async {
  final user = FirebaseAuth.instance.currentUser;
  if (user == null) return;

  await UserSession.saveUid(user.uid);

  // ── 1. Prominent disclosure (Google Play requirement) ──
  // Must be shown BEFORE the system permission dialog.
  if (!context.mounted) return;
  final userAccepted = await showLocationDisclosure(context);
  if (!userAccepted) return;

  // ── 2. Notification permission (Android 13+) ──
  if (Platform.isAndroid) {
    final notif = await Permission.notification.status;
    if (!notif.isGranted) {
      final result = await Permission.notification.request();
      if (!result.isGranted) return;
    }
  }

  // ── 3. Foreground location permission ──
  var perm = await Geolocator.checkPermission();
  if (perm == LocationPermission.denied || perm == LocationPermission.deniedForever) {
    perm = await Geolocator.requestPermission();
  }

  // ── 4. Background location permission (Android only) ──
  // On Android 10+ we need "Allow all the time" for the background service.
  if (Platform.isAndroid) {
    if (perm == LocationPermission.whileInUse) {
      // The user granted foreground-only. Now request background.
      final bgStatus = await Permission.locationAlways.status;
      if (!bgStatus.isGranted) {
        final bgResult = await Permission.locationAlways.request();
        if (!bgResult.isGranted) {
          // Still start with foreground-only; background polling will fail
          // gracefully but the service notification will still be visible.
        }
      }
    }
  }

  // ── 5. Start the background service ──
  await configureBackgroundService();
  await startBackgroundService();
}
