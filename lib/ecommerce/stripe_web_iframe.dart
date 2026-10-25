import 'package:flutter/widgets.dart';
import 'dart:html' as html;
import 'dart:ui_web' as ui; // ✅ for web

class StripeWebIframe extends StatelessWidget {
  final String url;
  const StripeWebIframe({super.key, required this.url});

  static void registerIframe(String viewType, String url) {
    // Register only once per viewType
    ui.platformViewRegistry.registerViewFactory(
      viewType,
          (int viewId) {
        final element = html.IFrameElement()
          ..src = url
          ..style.border = 'none'
          ..width = '100%'
          ..height = '100%';
        return element;
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return HtmlElementView(viewType: url);
  }
}
