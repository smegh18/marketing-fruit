import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Key used to persist whether the user has already accepted
/// the location-disclosure dialog.
const String _kDisclosureAccepted = 'location_disclosure_accepted';

/// Shows a Google-Play-compliant **prominent disclosure** dialog that
/// explains *why* the app collects location data in the background and
/// what it is used for.
///
/// Returns `true` if the user taps "Allow" and `false` if they dismiss
/// the dialog or tap "Deny".
///
/// Once accepted the flag is persisted so the dialog is not shown again.
Future<bool> showLocationDisclosure(BuildContext context) async {
  // If the user already accepted, skip the dialog.
  final prefs = await SharedPreferences.getInstance();
  if (prefs.getBool(_kDisclosureAccepted) ?? false) return true;

  if (!context.mounted) return false;
  final accepted = await showDialog<bool>(
    context: context,
    barrierDismissible: false,
    builder: (ctx) => AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: Row(
        children: [
          Icon(Icons.location_on, color: Colors.blueAccent, size: 28),
          const SizedBox(width: 10),
          const Expanded(
            child: Text(
              'Background Location Access',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
      content: const SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'This app collects your location data to enable the following feature:',
              style: TextStyle(fontSize: 14),
            ),
            SizedBox(height: 12),
            _DisclosureBullet(
              icon: Icons.event_available,
              title: 'Automatic Event Attendance',
              body:
                  'When you are registered for a scheduled event, the app '
                  'uses your location in the background to verify that you '
                  'are physically present at the event venue. Your attendance '
                  'is marked automatically when you are within the event '
                  'location during the event time.',
            ),
            SizedBox(height: 10),
            _DisclosureBullet(
              icon: Icons.battery_saver,
              title: 'Battery-Efficient Tracking',
              body:
                  'Location is only checked frequently (every 30 seconds) '
                  'while a registered event is actively running. Outside of '
                  'event hours, location is checked infrequently (once per '
                  'hour) to maintain your activity history.',
            ),
            SizedBox(height: 10),
            _DisclosureBullet(
              icon: Icons.lock_outline,
              title: 'Your Data is Secure',
              body:
                  'Location data is stored securely and is only used for '
                  'attendance verification and your personal activity history. '
                  'It is never shared with third parties or used for advertising.',
            ),
            SizedBox(height: 16),
            Text(
              'This app requires access to your location in the background '
              'even when you are not using the app, so that your attendance '
              'can be recorded for events happening at their scheduled times.',
              style: TextStyle(fontSize: 13, fontStyle: FontStyle.italic),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(ctx).pop(false),
          child: const Text('Deny'),
        ),
        ElevatedButton(
          onPressed: () => Navigator.of(ctx).pop(true),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.blueAccent,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
          child: const Text('Allow'),
        ),
      ],
    ),
  );

  final result = accepted ?? false;
  if (result) {
    await prefs.setBool(_kDisclosureAccepted, true);
  }
  return result;
}

/// Reusable bullet-point row used inside the disclosure dialog.
class _DisclosureBullet extends StatelessWidget {
  final IconData icon;
  final String title;
  final String body;

  const _DisclosureBullet({
    required this.icon,
    required this.title,
    required this.body,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 20, color: Colors.blueAccent),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title,
                  style: const TextStyle(
                      fontWeight: FontWeight.w600, fontSize: 14)),
              const SizedBox(height: 4),
              Text(body, style: const TextStyle(fontSize: 13)),
            ],
          ),
        ),
      ],
    );
  }
}
