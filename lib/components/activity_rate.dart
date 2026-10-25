import 'dart:ui';
import 'package:flutter/material.dart';

class ActivityRateButton extends StatelessWidget {
  final bool disabled;
  final VoidCallback? onViewAll;

  const ActivityRateButton({
    super.key,
    this.disabled = false,
    this.onViewAll,
  });

  @override
  Widget build(BuildContext context) {
    final pixelRatio = MediaQuery.of(context).devicePixelRatio;
    final baselinePixelRatio = 1.0;

    double t = ((pixelRatio - baselinePixelRatio) / baselinePixelRatio).clamp(0.0, 1.0);
    double scaleFactor = lerpDouble(1.0, 0.8, t)!;
    double sfg = lerpDouble(1.0, 0.75, t)!;

    if (pixelRatio > baselinePixelRatio) {
      double ratio = baselinePixelRatio / pixelRatio;
      if ((pixelRatio - 1.0).abs() < 0.3) {
        scaleFactor = ratio * 1.05;
        sfg = ratio * 1.1;
      } else {
        scaleFactor = ratio * 1.2;
        sfg = ratio * 1.5;
      }
    }

    double buttonWidth = MediaQuery.of(context).size.width * 0.35 * sfg;
    double buttonHeight = MediaQuery.of(context).size.height * 0.3 * sfg;

    return IgnorePointer(
      ignoring: disabled,
      child: Opacity(
        opacity: disabled ? 0.85 : 1.0,
        child: SizedBox( // ✅ FIX: Constrain size for layout
          width: buttonWidth,
          height: buttonHeight,
          child: LayoutBuilder(
            builder: (context, constraints) {
              double width = constraints.maxWidth;
              double height = constraints.maxHeight;

              return Stack(
                clipBehavior: Clip.none,
                children: [
                  // Background with base and pattern
                  Container(
                    width: width,
                    height: height,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(26),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.5),
                          blurRadius: 18,
                          offset: const Offset(0, 0.4),
                        ),
                      ],
                    ),
                    child: Stack(
                      children: [
                        Image.asset(
                          'assets/pink.png',
                          width: width,
                          height: height,
                          fit: BoxFit.fill,
                        ),
                        Image.asset(
                          'assets/line.png',
                          width: width,
                          height: height,
                          fit: BoxFit.fill,
                        ),
                      ],
                    ),
                  ),

                  // Foreground content
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Padding(
                        padding: const EdgeInsets.only(top: 20, left: 30),
                        child: Text(
                          "Overall Activity Rate",
                          style: TextStyle(
                            fontSize: 20 * scaleFactor,
                            color: Colors.black87,
                          ),
                        ),
                      ),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Padding(
                            padding: const EdgeInsets.only(left: 30, top: 20),
                            child: Stack(
                              children: [
                                // Stroke
                                Text(
                                  "73%",
                                  style: TextStyle(
                                    fontSize: 68 * scaleFactor,
                                    fontWeight: FontWeight.bold,
                                    foreground: Paint()
                                      ..style = PaintingStyle.stroke
                                      ..strokeWidth = 4
                                      ..color = Colors.white,
                                  ),
                                ),
                                // Fill
                                Text(
                                  "73%",
                                  style: TextStyle(
                                    fontSize: 68 * scaleFactor,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.green.shade600,
                                    shadows: [
                                      Shadow(
                                        offset: Offset(2, 2),
                                        blurRadius: 4,
                                        color: Colors.black.withOpacity(0.4),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                          SizedBox(
                            width: 56 * sfg,
                            height: 56 * sfg,
                            child: Stack(
                              clipBehavior: Clip.none,
                              children: [
                                Positioned(
                                  top: 6 * sfg,
                                  left: 20 * sfg,
                                  child: Image.asset(
                                    'assets/arrow_up.png',
                                    height: (height - 60) * sfg,
                                    width: 80 * sfg,
                                    fit: BoxFit.fill,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const Spacer(),
                      Padding(
                        padding: const EdgeInsets.only(left: 30.0, bottom: 14),
                        child: GestureDetector(
                          onTap: onViewAll,
                          child: Text(
                            "View All Activity",
                            style: TextStyle(
                              fontSize: 16 * scaleFactor,
                              color: Colors.black87,
                              decoration: TextDecoration.underline,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),

                  // Floating character
                  Positioned(
                    right: -10 * sfg,
                    top: -20 * sfg,
                    child: Image.asset(
                      'assets/character.png',
                      height: height + 20,
                      fit: BoxFit.contain,
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}
