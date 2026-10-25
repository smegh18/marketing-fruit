import 'dart:math';
import 'package:firebase_database/firebase_database.dart';

class EventAttendanceChecker {
  final String uid;
  final DatabaseReference _db = FirebaseDatabase.instance.ref();

  EventAttendanceChecker(this.uid);

  /// Returns list of active events the user is registered for.
  /// Each map contains: eventId, eventLatitude, eventLongitude, start, end.
  Future<List<Map<String, dynamic>>> getActiveRegisteredEvents() async {
    final now = DateTime.now().millisecondsSinceEpoch;
    final eventsSnap = await _db.child('events').get();
    if (!eventsSnap.exists || eventsSnap.value is! Map) return [];

    final allEvents = Map<String, dynamic>.from(eventsSnap.value as Map);
    final List<Map<String, dynamic>> active = [];

    for (final entry in allEvents.entries) {
      final eventId = entry.key;
      if (entry.value is! Map) continue;
      final data = Map<String, dynamic>.from(entry.value as Map);

      // Check if user is registered
      final regUsers = data['registeredUsers'];
      if (regUsers is! Map || !regUsers.containsKey(uid)) continue;

      // Check if event is currently active
      final start = _toInt(data['start']);
      final end = _toInt(data['end']);
      if (start == null || end == null) continue;
      if (now < start || now > end) continue;

      // Check that event has lat/lng
      final lat = _toDouble(data['eventLatitude']);
      final lng = _toDouble(data['eventLongitude']);
      if (lat == null || lng == null) continue;

      active.add({
        'eventId': eventId,
        'eventLatitude': lat,
        'eventLongitude': lng,
        'start': start,
        'end': end,
      });
    }
    return active;
  }

  /// Returns true if user has any currently-active registered event.
  Future<bool> hasActiveEvent() async {
    final events = await getActiveRegisteredEvents();
    return events.isNotEmpty;
  }

  /// Haversine distance in meters between two lat/lng points.
  static double distanceMeters(
      double lat1, double lon1, double lat2, double lon2) {
    const R = 6371000.0; // Earth radius in meters
    final dLat = _toRad(lat2 - lat1);
    final dLon = _toRad(lon2 - lon1);
    final a = sin(dLat / 2) * sin(dLat / 2) +
        cos(_toRad(lat1)) *
            cos(_toRad(lat2)) *
            sin(dLon / 2) *
            sin(dLon / 2);
    final c = 2 * atan2(sqrt(a), sqrt(1 - a));
    return R * c;
  }

  /// Mark attendance for a specific event.
  /// Writes to events/{eventId}/attendance/{uid}.
  /// Idempotent — will not overwrite an existing record.
  Future<void> markAttendance({
    required String eventId,
    required double userLat,
    required double userLng,
  }) async {
    final ref = _db.child('events/$eventId/attendance/$uid');
    final existing = await ref.get();
    if (existing.exists) return;

    await ref.set({
      'markedAt': ServerValue.timestamp,
      'latitude': userLat,
      'longitude': userLng,
    });
  }

  /// For each active registered event, check if user is within 100m.
  /// If so, mark attendance.
  Future<void> checkAndMarkAttendance({
    required double userLat,
    required double userLng,
  }) async {
    final events = await getActiveRegisteredEvents();
    for (final event in events) {
      final dist = distanceMeters(
        userLat,
        userLng,
        event['eventLatitude'] as double,
        event['eventLongitude'] as double,
      );
      if (dist <= 100.0) {
        await markAttendance(
          eventId: event['eventId'] as String,
          userLat: userLat,
          userLng: userLng,
        );
      }
    }
  }

  static double _toRad(double deg) => deg * pi / 180;

  static int? _toInt(dynamic v) {
    if (v is int) return v;
    if (v is String) return int.tryParse(v);
    if (v is double) return v.toInt();
    return null;
  }

  static double? _toDouble(dynamic v) {
    if (v is double) return v;
    if (v is int) return v.toDouble();
    if (v is String) return double.tryParse(v);
    return null;
  }
}
