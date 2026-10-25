// // lib/components/background_tasks.dart
// import 'dart:async';
// import 'package:flutter/widgets.dart';
//
// import 'package:firebase_core/firebase_core.dart';
// import 'package:workmanager/workmanager.dart';
//
// import '../firebase_options.dart';
// import 'location_service.dart';
//
// const _kWorkTag = 'hourly_location';
// const _kWorkUnique = 'hourly_location_unique';
//
// /// ANDROID: Workmanager dispatcher (runs in background isolate)
// @pragma('vm:entry-point')
// void workmanagerDispatcher() {
//   Workmanager().executeTask((taskName, inputData) async {
//     WidgetsFlutterBinding.ensureInitialized();
//     await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
//
//     final uid = inputData?['uid'] as String?;
//     if (uid == null) return Future.value(true);
//
//     final svc = LocationService(uid);
//     final hasPerm = await svc.ensurePermissions();
//     if (!hasPerm) return Future.value(true);
//
//     final pos = await svc.getPosition();
//     await svc.saveToFirebase(
//       uid: uid,
//       lat: pos?.latitude,
//       lng: pos?.longitude,
//     );
//
//     return Future.value(true);
//   });
// }
//
// /// Schedule Android periodic work (~hourly)
// Future<void> scheduleAndroidHourly(String uid) async {
//   await Workmanager().initialize(workmanagerDispatcher, isInDebugMode: false);
//   await Workmanager().cancelByUniqueName(_kWorkUnique);
//
//   await Workmanager().registerPeriodicTask(
//     _kWorkUnique,
//     _kWorkTag,
//     frequency: const Duration(minutes: 15),
//     inputData: {'uid': uid},
//     constraints: Constraints(
//       networkType: NetworkType.connected,
//     ),
//     existingWorkPolicy: ExistingPeriodicWorkPolicy.replace,
//     initialDelay: const Duration(seconds: 15),
//     backoffPolicy: BackoffPolicy.exponential,
//     backoffPolicyDelay: const Duration(minutes: 1),
//   );
// }
//
// /// Optional helper to cancel
// Future<void> cancelAndroidHourly() =>
//     Workmanager().cancelByUniqueName(_kWorkUnique);
