// import 'dart:io' show Platform;
// import 'location_stub_helper.dart'
// if (dart.library.html) 'location_web_helper.dart';
//
// import 'package:firebase_database/firebase_database.dart';
// import 'package:flutter/foundation.dart';
// import 'package:geolocator/geolocator.dart';
// import 'package:device_info_plus/device_info_plus.dart';
// import 'package:intl/intl.dart';
// import 'dart:math';
//
// class LocationService {
//   final DatabaseReference dbRef = FirebaseDatabase.instance.ref();
//   final String userId;
//
//   LocationService(this.userId);
//
//   Future<void> _cleanupOldEntries({int daysToKeep = 7}) async {
//     final cutoffDate = DateTime.now().subtract(Duration(days: daysToKeep));
//     final locationTypes = ['Accurate location', 'approx location'];
//
//     for (final type in locationTypes) {
//       final ref = dbRef.child('users/$userId/location history/$type');
//       final snapshot = await ref.get();
//
//       if (snapshot.exists) {
//         final allDates = Map<String, dynamic>.from(snapshot.value as Map);
//         for (final dateStr in allDates.keys) {
//           final date = DateTime.tryParse(dateStr);
//           if (date != null && date.isBefore(cutoffDate)) {
//             await ref.child(dateStr).remove();
//           }
//         }
//       }
//     }
//   }
//
//
//   Future<void> fetchAndStoreLocation() async {
//     String date = DateFormat('yyyy-MM-dd').format(DateTime.now());
//     String time = DateFormat('HH:mm').format(DateTime.now());
//     Position? currentPosition;
//
//     try {
//       bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
//       if (!serviceEnabled) throw Exception('Location services disabled');
//
//       print(_getLocationType());
//
//       LocationPermission permission = await Geolocator.checkPermission();
//       if (permission == LocationPermission.denied ||
//           permission == LocationPermission.deniedForever) {
//         permission = await Geolocator.requestPermission();
//         if (permission != LocationPermission.always &&
//             permission != LocationPermission.whileInUse) {
//           throw Exception('Location permission not granted');
//         }
//       }
//
//       print(permission);
//
//       currentPosition = await Geolocator.getCurrentPosition(
//         desiredAccuracy: LocationAccuracy.high,
//       );
//
//       print(currentPosition);
//     } catch (e) {
//       // Store blank entry if location fails
//       await dbRef
//           .child('users/$userId/location history/${_getLocationType()}/$date/$time')
//           .set({
//         'latitude': null,
//         'longitude': null,
//       });
//       return;
//     }
//
//     // Compare with last location
//     final lastSnapshot = await dbRef
//         .child('users/$userId/location history/${_getLocationType()}/$date')
//         .orderByKey()
//         .limitToLast(1)
//         .get();
//
//     if (lastSnapshot.exists) {
//       final lastEntry = Map<String, dynamic>.from(lastSnapshot.value as Map);
//       final lastTime = lastEntry.keys.first;
//       final lastData = Map<String, dynamic>.from(lastEntry[lastTime]);
//
//       final double? lastLat = double.tryParse(lastData['latitude'].toString());
//       final double? lastLng = double.tryParse(lastData['longitude'].toString());
//
//       if (lastLat != null && lastLng != null) {
//         final double distance = _calculateDistance(
//             lastLat, lastLng, currentPosition.latitude, currentPosition.longitude);
//         // if (distance < 0.0001) return; // Skip storing if within 1km
//       }
//     }
//
//     // Store new location
//     print(currentPosition.latitude);
//     await dbRef
//         .child('users/$userId/location history/${_getLocationType()}/$date/$time')
//         .set({
//       'latitude': currentPosition.latitude,
//       'longitude': currentPosition.longitude,
//     });
//
//     await _cleanupOldEntries();
//   }
//
//   double _calculateDistance(
//       double lat1, double lon1, double lat2, double lon2) {
//     const double radius = 6371; // Earth radius in km
//     final double dLat = _toRadians(lat2 - lat1);
//     final double dLon = _toRadians(lon2 - lon1);
//     final a = sin(dLat / 2) * sin(dLat / 2) +
//         cos(_toRadians(lat1)) *
//             cos(_toRadians(lat2)) *
//             sin(dLon / 2) *
//             sin(dLon / 2);
//     final c = 2 * atan2(sqrt(a), sqrt(1 - a));
//     return radius * c;
//   }
//
//   double _toRadians(double degree) => degree * pi / 180;
//
//   String _getLocationType() {
//     if (kIsWeb) {
//       final userAgent = getWebUserAgent().toLowerCase();
//       if (userAgent.contains('android') || userAgent.contains('iphone') || userAgent.contains('ipad')) {
//         return 'Accurate Location';
//       } else {
//         return 'Approx Location';
//       }
//     } else {
//       if (Platform.isAndroid || Platform.isIOS) return 'Accurate Location';
//       return 'Approx Location';
//     }
//   }
//
// }

import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';
import 'package:intl/intl.dart';
import 'dart:io' show Platform;
import 'location_stub_helper.dart'
if (dart.library.html) 'location_web_helper.dart';

class LocationService {
  final String uid;
  LocationService(this.uid);

  Future<bool> hasPermissions() async {
    final enabled = await Geolocator.isLocationServiceEnabled();
    if (!enabled) return false;

    final perm = await Geolocator.checkPermission();
    return perm == LocationPermission.always || perm == LocationPermission.whileInUse;
  }

  Future<Position?> getPosition() async {
    try {
      Position? pos = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );
      print(pos);
      return pos;
    } catch (_) {
      return null;
    }
  }

  /// Same as getPosition but with a timeout to prevent indefinite hangs
  /// in background service when GPS is slow to lock.
  Future<Position?> getPositionWithTimeout({
    Duration timeout = const Duration(seconds: 15),
  }) async {
    try {
      return await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      ).timeout(timeout);
    } catch (_) {
      return null;
    }
  }

  Future<void> fetchAndStoreLocation() async {
    String date = DateFormat('yyyy-MM-dd').format(DateTime.now());
    String time = DateFormat('HH:mm').format(DateTime.now());
    Position? currentPosition;
    final dbRef = FirebaseDatabase.instance.ref();

    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) throw Exception('Location services disabled');

      print(_getLocationType());

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        permission = await Geolocator.requestPermission();
        if (permission != LocationPermission.always &&
            permission != LocationPermission.whileInUse) {
          throw Exception('Location permission not granted');
        }
      }

      print(permission);

      currentPosition = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      print(currentPosition);
    } catch (e) {
      // Store blank entry if location fails
      await dbRef
          .child('users/$uid/location history/${_getLocationType()}/$date/$time')
          .set({
        'latitude': null,
        'longitude': null,
      });
      return;
    }

    // Compare with last location
    final lastSnapshot = await dbRef
        .child('users/$uid/location history/${_getLocationType()}/$date')
        .orderByKey()
        .limitToLast(1)
        .get();

    if (lastSnapshot.exists) {
      final lastEntry = Map<String, dynamic>.from(lastSnapshot.value as Map);
      final lastTime = lastEntry.keys.first;
      final lastData = Map<String, dynamic>.from(lastEntry[lastTime]);

      final double? lastLat = double.tryParse(lastData['latitude'].toString());
      final double? lastLng = double.tryParse(lastData['longitude'].toString());

      // if (lastLat != null && lastLng != null) {
      //   final double distance = _calculateDistance(
      //       lastLat, lastLng, currentPosition.latitude, currentPosition.longitude);
      //   // if (distance < 0.0001) return; // Skip storing if within 1km
      // }
    }

    // Store new location
    print(currentPosition.latitude);
    await dbRef
        .child('users/$uid/location history/${_getLocationType()}/$date/$time')
        .set({
      'latitude': currentPosition.latitude,
      'longitude': currentPosition.longitude,
    });

    // await _cleanupOldEntries();
  }

  Future<void> saveToFirebase({
    required double? lat,
    required double? lng,
  }) async {
    final db = FirebaseDatabase.instance.ref();
    final now = DateTime.now();
    final date = DateFormat('yyyy-MM-dd').format(now);
    final time = DateFormat('HH:mm:ss').format(now);

    await db.child('users/$uid/location history/${_getLocationType()}/$date/$time').set({
      'latitude': lat,
      'longitude': lng,
      'ts': now.toIso8601String(),
    });
  }

  String _getLocationType() {
    if (kIsWeb) {
      final userAgent = getWebUserAgent().toLowerCase();
      if (userAgent.contains('android') || userAgent.contains('iphone') || userAgent.contains('ipad')) {
        return 'Accurate Location';
      } else {
        return 'Approx Location';
      }
    } else {
      if (Platform.isAndroid || Platform.isIOS) return 'Accurate Location';
      return 'Approx Location';
    }
  }
}



// // lib/services/location_service.dart
// import 'package:firebase_database/firebase_database.dart';
// import 'package:intl/intl.dart';
// import 'package:flutter_background_geolocation/flutter_background_geolocation.dart' as bg;
//
// class LocationService {
//   final DatabaseReference db = FirebaseDatabase.instance.ref();
//   final String uid;
//
//   LocationService(this.uid);
//
//   // Save any bg.Location to DB (throttled outside)
//   Future<void> saveLocation(bg.Location loc) async {
//     final now = DateTime.now();
//     final date = DateFormat('yyyy-MM-dd').format(now);
//     final time = DateFormat('HH:mm:ss').format(now);
//     final coords = loc.coords;
//
//     await db.child('users/$uid/location_history/$date/$time').set({
//       'latitude': coords.latitude,
//       'longitude': coords.longitude,
//       'accuracy': coords.accuracy,
//       'speed': coords.speed,
//       'is_moving': loc.isMoving,
//       'battery': loc.battery.level,
//       'activity': loc.activity.type,
//       // 'provider': loc.provider,
//       'ts': now.toIso8601String(),
//     });
//   }
// }


// import 'dart:math';
// import 'package:firebase_database/firebase_database.dart';
// import 'package:geolocator/geolocator.dart';
// import 'package:intl/intl.dart';
//
// class LocationService {
//   final DatabaseReference db = FirebaseDatabase.instance.ref();
//
//   Future<bool> ensurePermissions() async {
//     bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
//     if (!serviceEnabled) return false;
//
//     LocationPermission permission = await Geolocator.checkPermission();
//     if (permission == LocationPermission.denied ||
//         permission == LocationPermission.deniedForever) {
//       permission = await Geolocator.requestPermission();
//     }
//     return permission == LocationPermission.always ||
//         permission == LocationPermission.whileInUse;
//   }
//
//   Future<Position?> getPosition() async {
//     try {
//       return await Geolocator.getCurrentPosition(
//         desiredAccuracy: LocationAccuracy.high,
//       );
//     } catch (_) {
//       return null;
//     }
//   }
//
//   Future<void> saveToFirebase({
//     required String uid,
//     required double? lat,
//     required double? lng,
//   }) async {
//     final now = DateTime.now();
//     final date = DateFormat('yyyy-MM-dd').format(now);
//     final time = DateFormat('HH:mm:ss').format(now);
//     await db.child('users/$uid/location_history/$date/$time').set({
//       'latitude': lat,
//       'longitude': lng,
//       'ts': now.toIso8601String(),
//     });
//   }
// }

// // lib/components/location_service.dart
// import 'package:firebase_database/firebase_database.dart';
// import 'package:geolocator/geolocator.dart';
// import 'package:intl/intl.dart';
//
// class LocationService {
//   final String uid;
//   LocationService(this.uid);
//
//   Future<bool> ensurePermissions() async {
//     final enabled = await Geolocator.isLocationServiceEnabled();
//     if (!enabled) return false;
//
//     var perm = await Geolocator.checkPermission();
//     if (perm == LocationPermission.denied ||
//         perm == LocationPermission.deniedForever) {
//       perm = await Geolocator.requestPermission();
//     }
//     return perm == LocationPermission.always ||
//         perm == LocationPermission.whileInUse;
//   }
//
//   Future<Position?> getPosition() async {
//     try {
//       return await Geolocator.getCurrentPosition(
//         desiredAccuracy: LocationAccuracy.high,
//       );
//     } catch (_) {
//       return null;
//     }
//   }
//
//   Future<void> saveToFirebase({
//     required String uid,
//     required double? lat,
//     required double? lng,
//   }) async {
//     final db = FirebaseDatabase.instance.ref();
//     final now = DateTime.now();
//     final date = DateFormat('yyyy-MM-dd').format(now);
//     final time = DateFormat('HH:mm:ss').format(now);
//
//     await db.child('users/$uid/location_history/$date/$time').set({
//       'latitude': lat,
//       'longitude': lng,
//       'ts': now.toIso8601String(),
//     });
//   }
// }


