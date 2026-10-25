import 'package:flutter/widgets.dart';

class StripeWebIframe extends StatelessWidget {
  final String url;
  const StripeWebIframe({super.key, required this.url});

  static void registerIframe(String url,String title) {}

  @override
  Widget build(BuildContext context) => const SizedBox.shrink();
}
