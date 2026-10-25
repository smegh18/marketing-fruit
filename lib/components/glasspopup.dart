import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// macOS-style glass popup with black translucent background that
/// auto-sizes to its content (within max width/height bounds).
class GlassPopupScaffold extends StatelessWidget {
  final String? title;
  final Widget child;

  /// Max fractions of the screen this popup is allowed to occupy.
  final double maxWidthFraction;
  final double maxHeightFraction;

  /// Optional minimum size to keep the popup from getting too tiny.
  final double minWidth;
  final double minHeight;

  final EdgeInsetsGeometry padding;
  final double blurSigma;
  final bool allowSystemBack;

  const GlassPopupScaffold({
    super.key,
    this.title,
    required this.child,
    this.maxWidthFraction = 0.5,  // up to 50% of screen width
    this.maxHeightFraction = 0.7, // up to 70% of screen height
    this.minWidth = 320,
    this.minHeight = 0, // let height shrink if content is tiny
    this.padding = const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
    this.blurSigma = 20,
    this.allowSystemBack = true,
  });

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    final maxW = (size.width * maxWidthFraction).clamp(0.0, size.width);
    final maxH = (size.height * maxHeightFraction).clamp(0.0, size.height);

    return WillPopScope(
      onWillPop: () async => allowSystemBack,
      child: Material( // transparent material to ensure proper elevation/taps
        type: MaterialType.transparency,
        child: Center(
          child: ConstrainedBox(
            constraints: BoxConstraints(
              minWidth: minWidth,
              minHeight: minHeight,
              maxWidth: maxW,
              maxHeight: maxH,
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: blurSigma, sigmaY: blurSigma),
                child: Container(
                  // No fixed width/height — constraints + content will size it.
                  padding: padding,
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.50), // black translucent
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: Colors.white.withOpacity(0.20),
                      width: 1,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.35),
                        blurRadius: 24,
                        offset: const Offset(0, 12),
                      ),
                    ],
                  ),
                  child: IconTheme.merge(
                    data: const IconThemeData(color: Colors.white),
                    child: DefaultTextStyle.merge(
                      style: GoogleFonts.poppins(
                        color: Colors.white,
                        fontSize: 14,
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min, // shrink to fit content
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (title != null)
                            Padding(
                              padding: const EdgeInsets.only(bottom: 12),
                              child: Text(
                                title!,
                                style: GoogleFonts.poppins(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          // If content is small, popup stays small.
                          // If content is tall, it scrolls inside the max height.
                          Flexible(
                            fit: FlexFit.loose,
                            child: SingleChildScrollView(
                              physics: const BouncingScrollPhysics(),
                              child: child,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Helper to show any widget inside the macOS-style popup.
/// Auto-sizes to content up to maxWidthFraction/maxHeightFraction.
///
/// NOTE: `useRootNavigator` defaults to **false** so that in apps with
/// nested Navigators (e.g., tabbed MainLayout), the dialog appears in the
/// correct overlay *above* the current tab.
Future<T?> showGlassPopup<T>({
  required BuildContext context,
  String? title,
  required Widget child,

  /// Max fractions of screen size (caps).
  double maxWidthFraction = 0.5,
  double maxHeightFraction = 0.7,

  /// Optional minimums (helps aesthetics with tiny content).
  double minWidth = 320,
  double minHeight = 0,

  EdgeInsetsGeometry padding =
      const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
  bool dismissible = true,
  double blurSigma = 20,
  bool allowSystemBack = true,

  /// IMPORTANT: Defaults to false for nested Navigators.
  bool useRootNavigator = false,

  /// In case you want to dim more/less or make it transparent.
  Color barrierColor = const Color(0x99000000), // black with ~60% opacity
}) {
  return showDialog<T>(
    context: context,
    useRootNavigator: useRootNavigator,
    barrierDismissible: dismissible,
    barrierColor: barrierColor,
    builder: (ctx) {
      return GestureDetector(
        onTap: dismissible ? () => Navigator.of(ctx).maybePop() : null,
        behavior: HitTestBehavior.opaque,
        child: Center(
          child: GestureDetector(
            onTap: () {}, // absorb taps inside
            child: GlassPopupScaffold(
              title: title,
              maxWidthFraction: maxWidthFraction,
              maxHeightFraction: maxHeightFraction,
              minWidth: minWidth,
              minHeight: minHeight,
              padding: padding,
              blurSigma: blurSigma,
              allowSystemBack: allowSystemBack,
              child: child,
            ),
          ),
        ),
      );
    },
  );
}
