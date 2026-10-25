// // lib/background/location_headless.dart
// import 'package:flutter_background_geolocation/flutter_background_geolocation.dart' as bg;
// import 'package:shared_preferences/shared_preferences.dart';
// import 'location_service.dart';
//
// Future<String?> _readUid() async {
//   final sp = await SharedPreferences.getInstance();
//   return sp.getString('persisted_uid');
// }
//
// Future<void> _writeUid(String uid) async {
//   final sp = await SharedPreferences.getInstance();
//   await sp.setString('persisted_uid', uid);
// }
//
// /// Call this *from the foreground* once user is known.
// Future<void> persistUidForHeadless(String uid) => _writeUid(uid);
//
// // The headless entry-point:
// @pragma('vm:entry-point')
// void backgroundGeolocationHeadlessTask(bg.HeadlessEvent headlessEvent) async {
//   final uid = await _readUid();
//   if (uid == null) return;
//
//   final svc = LocationService(uid);
//
//   switch (headlessEvent.name) {
//     case bg.Event.HEARTBEAT:
//       try {
//         final loc = await bg.BackgroundGeolocation.getCurrentPosition(
//           samples: 1, persist: false, maximumAge: 0, timeout: 60,
//         );
//         await svc.saveLocation(loc);
//       } catch (_) {}
//       break;
//
//     case bg.Event.LOCATION:
//       final loc = headlessEvent.event as bg.Location;
//       // Optional: we could throttle here too, but heartbeat already guarantees ~1/hr
//       await svc.saveLocation(loc);
//       break;
//
//     default:
//     // ignore other events
//       break;
//   }
// }
