import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Glass/macos style popup using normalized constraints for all screens.
class GlassPopupScaffold extends StatelessWidget {
  final String? title;
  final Widget child;
  final double maxWidthFraction;
  final double maxHeightFraction;
  final double minWidth;
  final double minHeight;
  final EdgeInsetsGeometry padding;
  final double blurSigma;
  final double borderRadius;
  final Color backgroundColor;
  final Color borderColor;
  final bool allowSystemBack;

  const GlassPopupScaffold({
    super.key,
    this.title,
    required this.child,
    this.maxWidthFraction = 0.5,
    this.maxHeightFraction = 0.7,
    this.minWidth = 320,
    this.minHeight = 0,
    this.padding = const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
    this.blurSigma = 5,
    this.borderRadius = 40,
    this.backgroundColor = Colors.black,
    this.borderColor = const Color(0xFF888888),
    this.allowSystemBack = true,
  });

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    // Fix for mobile: always normalize constraints!
    final maxAvailableWidth = (size.width * maxWidthFraction).clamp(0.0, size.width);
    final maxAvailableHeight = (size.height * maxHeightFraction).clamp(0.0, size.height);

    // If minWidth > maxAvailableWidth, normalize to maxAvailableWidth.
    final normalizedMinWidth = minWidth.clamp(0.0, maxAvailableWidth);
    final normalizedMinHeight = minHeight.clamp(0.0, maxAvailableHeight);

    final constraints = BoxConstraints(
      minWidth: normalizedMinWidth,
      minHeight: normalizedMinHeight,
      maxWidth: maxAvailableWidth,
      maxHeight: maxAvailableHeight,
    );

    return WillPopScope(
      onWillPop: () async => allowSystemBack,
      child: Material(
        type: MaterialType.transparency,
        child: Center(
          child: ConstrainedBox(
            constraints: constraints,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(borderRadius),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: blurSigma, sigmaY: blurSigma),
                child: Container(
                  padding: padding,
                  decoration: BoxDecoration(
                    color: backgroundColor.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(borderRadius),
                    border: Border.all(
                      color: borderColor.withOpacity(0.5),
                      width: 3,
                    ),
                  ),
                  child: IconTheme.merge(
                    data: const IconThemeData(color: Colors.white),
                    child: DefaultTextStyle.merge(
                      style: GoogleFonts.poppins(
                        color: Colors.white,
                        fontSize: 14,
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
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

/// Helper to show any widget inside the glassmorphic popup (normalized for all screens).
Future<T?> showGlassPopup<T>({
  required BuildContext context,
  String? title,
  required Widget child,
  double maxWidthFraction = 0.5,
  double maxHeightFraction = 0.7,
  double minWidth = 320,
  double minHeight = 0,
  EdgeInsetsGeometry padding = const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
  bool dismissible = true,
  double blurSigma = 5,
  double borderRadius = 40,
  Color backgroundColor = Colors.black,
  Color borderColor = const Color(0xFF888888),
  bool allowSystemBack = true,
  bool useRootNavigator = false,
  Color barrierColor = const Color(0x99000000),
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
            onTap: () {},
            child: GlassPopupScaffold(
              title: title,
              maxWidthFraction: maxWidthFraction,
              maxHeightFraction: maxHeightFraction,
              minWidth: minWidth,
              minHeight: minHeight,
              padding: padding,
              blurSigma: blurSigma,
              borderRadius: borderRadius,
              backgroundColor: backgroundColor,
              borderColor: borderColor,
              allowSystemBack: allowSystemBack,
              child: child,
            ),
          ),
        ),
      );
    },
  );
}
