
// newsletter_screen_mobile.dart
import 'package:flutter/material.dart';

class NewsletterScreenMobile extends StatefulWidget {
  /// Optional callback when a valid email is submitted.
  final ValueChanged<String>? onSubscribe;

  const NewsletterScreenMobile({super.key, this.onSubscribe});

  @override
  State<NewsletterScreenMobile> createState() => _NewsletterScreenMobileState();
}

class _NewsletterScreenMobileState extends State<NewsletterScreenMobile> {
  final _formKey = GlobalKey<FormState>();
  final _emailCtrl = TextEditingController();

  @override
  void dispose() {
    _emailCtrl.dispose();
    super.dispose();
  }

  void _submit() {
    if (_formKey.currentState?.validate() ?? false) {
      final email = _emailCtrl.text.trim();
      widget.onSubscribe?.call(email);

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Subscribed! Check your inbox for confirmation.'),
        ),
      );

      _emailCtrl.clear();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a valid email address.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final w = MediaQuery.of(context).size.width;
    final pad = w * 0.06;
    final titleSize = _clamp(w * 0.095, 22, 28);

    // ✅ No Scaffold. Just a container section
    return Container(
      width: double.infinity,
      margin: EdgeInsets.fromLTRB(pad, 18, pad, 24),
      decoration: BoxDecoration(
        color: Colors.black,
        borderRadius: BorderRadius.circular(24),
      ),
      padding: EdgeInsets.fromLTRB(pad, 22, pad, 22),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Big white heading (two lines)
            Text(
              'STAY UPTO DATE\nABOUT OUR\nLATEST OFFERS',
              textAlign: TextAlign.left,
              style: TextStyle(
                color: Colors.white,
                fontSize: titleSize,
                fontWeight: FontWeight.w900,
                height: 1.05,
                letterSpacing: -0.2,
              ),
            ),
            const SizedBox(height: 16),

            // Email field (white pill with mail icon)
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(28),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 14),
              child: Row(
                children: [
                  const Icon(Icons.mail_outline,
                      size: 20, color: Colors.grey),
                  const SizedBox(width: 8),
                  Expanded(
                    child: TextFormField(
                      controller: _emailCtrl,
                      keyboardType: TextInputType.emailAddress,
                      decoration: const InputDecoration(
                        hintText: 'Enter your email address',
                        border: InputBorder.none,
                        isCollapsed: true,
                      ),
                      style: const TextStyle(fontSize: 15),
                      validator: (v) {
                        final s = v?.trim() ?? '';
                        final regex = RegExp(
                          r"^[A-Z0-9._%+-]+@[A-Z0-9.-]+\.[A-Z]{2,}$",
                          caseSensitive: false,
                        );
                        if (s.isEmpty || !regex.hasMatch(s)) {
                          return 'Enter a valid email';
                        }
                        return null;
                      },
                      onFieldSubmitted: (_) => _submit(),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 12),

            // CTA button (white pill)
            SizedBox(
              height: 50,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: Colors.black,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(28),
                  ),
                  elevation: 0,
                ),
                onPressed: _submit,
                child: const Text(
                  'Subscribe to Newsletter',
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 15,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  static double _clamp(double v, double min, double max) {
    if (v < min) return min;
    if (v > max) return max;
    return v;
  }
}
