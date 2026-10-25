// main.dart
import 'dart:ui';

import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_quill/flutter_quill.dart' show FlutterQuillLocalizations;

import 'firebase_options.dart';
import 'login_screen.dart';
import 'screens/dashboard/theme_provider.dart';
import 'screens/dashboard/user_event_page.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  await dotenv.load(fileName: "assets/.env");

  // Global error boundary for Flutter framework errors
  FlutterError.onError = (FlutterErrorDetails details) {
    FlutterError.presentError(details);
    debugPrint('FlutterError: ${details.exception}');
  };

  // Global error boundary for platform/async errors
  PlatformDispatcher.instance.onError = (error, stack) {
    debugPrint('PlatformError: $error\n$stack');
    return true;
  };

  runApp(
    ChangeNotifierProvider(
      create: (_) => ThemeProvider(),
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});
  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  late final GoRouter _router;
  final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();


  @override
  void initState() {
    super.initState();

    // ---- Bootstrap initial location from the real URL ----
    // Works on web and mobile (Uri.base reflects the current app URL).
    final uri = Uri.base; // e.g., https://host/app/#/events/abc or /?eventId=abc
    // Debug: uncomment if you want to see what the engine thinks
    // // ignore: avoid_print
    // print('Uri.base: $uri');
    // // ignore: avoid_print
    // print('defaultRouteName: ${ui.PlatformDispatcher.instance.defaultRouteName}');

    String? bootstrapEventId;

    // PATH style: /events/<id>
    if (uri.pathSegments.isNotEmpty && uri.pathSegments.first == 'events') {
      if (uri.pathSegments.length >= 2 && uri.pathSegments[1].isNotEmpty) {
        bootstrapEventId = uri.pathSegments[1];
      }
    }

    // QUERY style: ?eventId=<id> or ?id=<id>
    bootstrapEventId ??= uri.queryParameters['eventId'] ?? uri.queryParameters['id'];

    // If we found an eventId in the URL, start there.
    final String? initialLocation =
    (bootstrapEventId != null && bootstrapEventId.isNotEmpty)
        ? '/events/$bootstrapEventId'
        : null;

    _router = GoRouter(
      debugLogDiagnostics: true,
      // If null, GoRouter uses the platform URL; if not null, we force-start there.
      initialLocation: initialLocation,
      routes: [
        // 1) Guardian verification via query: /verify-guardian?childId=XYZ
        GoRoute(
          path: '/verify-guardian',
          builder: (context, state) {
            return FutureBuilder<void>(
              future: _handleGuardianVerification(context, state),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Scaffold(
                    body: Center(child: CircularProgressIndicator()),
                  );
                } else if (snapshot.hasError) {
                  return Scaffold(
                    body: Center(child: Text('Error: ${snapshot.error}')),
                  );
                } else {
                  // We already redirected in _handleGuardianVerification.
                  return const Scaffold(body: Center(child: Text('Redirecting...')));
                }
              },
            );
          },
        ),

        // 2) Optional: /confirm -> /?confirm=true
        GoRoute(
          path: '/confirm',
          redirect: (context, state) => '/?confirm=true',
        ),

        // 3) Events (path param): /events/:eventId
        GoRoute(
          path: '/events/:eventId',
          builder: (context, state) {
            final eventId = state.pathParameters['eventId'];
            if (eventId == null || eventId.isEmpty) {
              return const Scaffold(body: Center(child: Text('Missing event id')));
            }
            return UserEventDashboardPage(
              eventId: eventId,
              userRole: 'Student',
              jk: true,// TODO: make dynamic
            );
          },
        ),

        // 4) Events (query fallback): /events?eventId=... or /events?id=...
        GoRoute(
          path: '/events',
          builder: (context, state) {
            final eventId = state.uri.queryParameters['eventId'] ??
                state.uri.queryParameters['id'];
            if (eventId == null || eventId.isEmpty) {
              return const Scaffold(body: Center(child: Text('Missing event id')));
            }
            return UserEventDashboardPage(
              eventId: eventId,
              userRole: 'Student',
              jk: true,
            );
          },
        ),

        // 5) Root/Login
        GoRoute(
          path: '/',
          builder: (context, state) {
            final role = state.uri.queryParameters['role'] ?? 'Student';
            final register = state.uri.queryParameters['register'] == 'true';
            final confirm = state.uri.queryParameters['confirm'] == 'true';
            return LoginScreen(
              initialRole: role,
              goToRegister: register,
              showConfirm: confirm,
            );
          },
        ),
      ],
      errorBuilder: (context, state) =>
      const Scaffold(body: Center(child: Text('Page not found'))),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<ThemeProvider>(
      builder: (context, themeProvider, _) {
        return MaterialApp.router(
          debugShowCheckedModeBanner: false,
          routerConfig: _router, // stable router; not recreated on rebuild
          theme: ThemeData.light().copyWith(
            scaffoldBackgroundColor: const Color(0xFFF5F5F5),
            cardColor: Colors.white,
            iconTheme: const IconThemeData(color: Colors.black87),
            primaryColor: Colors.blue.shade50,
            hintColor: Colors.black87,
            highlightColor: const Color(0xFFD0E8FF),
          ),
          darkTheme: ThemeData.dark().copyWith(
            scaffoldBackgroundColor: const Color(0xFF1B2531),
            cardColor: const Color(0xFF283142),
            iconTheme: const IconThemeData(color: Colors.white),
            primaryColor: const Color(0xFF283142),
            hintColor: Colors.white,
            highlightColor: const Color(0xFFD0E8FF).withOpacity(0.2),
          ),
          themeMode: themeProvider.currentTheme,
          localizationsDelegates: const [
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
            FlutterQuillLocalizations.delegate,
          ],
          supportedLocales: const [Locale('en')],
        );
      },
    );
  }

  /// /verify-guardian?childId=XYZ
  static Future<void> _handleGuardianVerification(
      BuildContext context, GoRouterState state) async {
    final childId = state.uri.queryParameters['childId'];
    debugPrint('Redirect triggered with childId: $childId');

    if (childId == null || childId.isEmpty) {
      throw Exception("Missing childId in URL");
    }

    try {
      final callable = FirebaseFunctions.instance.httpsCallable('verifyGuardian');
      final result = await callable.call({'childId': childId});

      final data = result.data;
      final bool success = (data is Map && data['success'] == true);
      final String? guardianEmail =
      (data is Map && data['guardian_email'] is String)
          ? data['guardian_email'] as String
          : null;

      debugPrint('verifyGuardian -> success: $success, guardianEmail: $guardianEmail');

      if (success) {
        GoRouter.of(context).go('/?role=Guardian');
        return;
      }

      if (guardianEmail == null || guardianEmail.isEmpty) {
        throw Exception("Guardian email not found");
      }

      final methods =
      await FirebaseAuth.instance.fetchSignInMethodsForEmail(guardianEmail);
      debugPrint('Sign-in methods for $guardianEmail: $methods');

      if (methods.isNotEmpty) {
        GoRouter.of(context).go('/?role=Guardian');
        return;
      } else {
        GoRouter.of(context).go('/?role=Guardian&register=true');
        return;
      }
    } catch (e) {
      debugPrint("Verification error: $e");
      throw Exception("Failed to verify guardian");
    }
  }
}
