import 'dart:ui';
import 'package:flutter/material.dart';

class NewsletterSection extends StatelessWidget {
  /// Portion of the viewport width to occupy when `fullWidth` is false.
  final double widthFactor;

  /// Upper cap when `fullWidth` is false.
  final double maxWidth;

  /// When true, the section expands to the full screen width.
  final bool fullWidth;

  const NewsletterSection({
    super.key,
    this.widthFactor = 0.96,
    this.maxWidth = 1800,
    this.fullWidth = false,
  });

  @override
  Widget build(BuildContext context) {
    final media = MediaQuery.of(context);
    final screenWidth = media.size.width;
    final pixelRatio = media.devicePixelRatio;
    const baselinePixelRatio = 1.0;

    double t = ((pixelRatio - baselinePixelRatio) / baselinePixelRatio).clamp(0.0, 1.0);
    double scaleFactor = lerpDouble(1.0, 0.8, t)!;
    double sfg = lerpDouble(1.0, 0.75, t)!;
    double sfgg = lerpDouble(1.0, 0.75, t)!;
    if (pixelRatio < 2.0 && pixelRatio > baselinePixelRatio) {
      final ratio = baselinePixelRatio / pixelRatio;
      if ((pixelRatio - 1.0).abs() < 0.3) {
        scaleFactor = ratio * 1.05;
        sfg = ratio * 1.1;
        sfgg = ratio * 1.1;
      } else {
        scaleFactor = ratio * 1.1;
        sfg = ratio * 1.4;
        sfgg = ratio * 1.82;
      }
    }

    // Compute width: either full screen, or a controlled width with a cap.
    double sectionWidth;
    if (fullWidth) {
      sectionWidth = screenWidth; // take the entire available width
    } else {
      final rawWidth = screenWidth * widthFactor * sfg;
      sectionWidth = rawWidth > maxWidth ? maxWidth : rawWidth;
      // Never exceed the actual screen width
      if (sectionWidth > screenWidth) sectionWidth = screenWidth;
    }

    return Container(
  width: double.infinity, // take full screen width
  margin: const EdgeInsets.symmetric(vertical: 40), // keep only vertical spacing
  padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 30),
  decoration: BoxDecoration(
    color: Colors.black,
    borderRadius: BorderRadius.circular(24),
    // remove border radius if you want sharp full-width edges
    // borderRadius: BorderRadius.circular(0),
  ),

        child: LayoutBuilder(
          builder: (context, constraints) {
            final isMobile = constraints.maxWidth < 700;

            return Flex(
              direction: isMobile ? Axis.vertical : Axis.horizontal,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Expanded(
                  flex: isMobile ? 0 : 2,
                  child: Container(
                    alignment: isMobile ? Alignment.center : Alignment.centerLeft,
                    margin: EdgeInsets.only(bottom: isMobile ? 20 : 0),
                    child: Text(
                      'STAY UPTO DATE ABOUT\nOUR LATEST OFFERS',
                      style: TextStyle(
                        fontSize: isMobile ? 22 * scaleFactor : 32 * scaleFactor,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                        height: 1.4,
                      ),
                      textAlign: isMobile ? TextAlign.center : TextAlign.left,
                    ),
                  ),
                ),
                const SizedBox(width: 30),
                Expanded(
                  flex: isMobile ? 0 : 3,
                  child: Column(
                    crossAxisAlignment:
                        isMobile ? CrossAxisAlignment.center : CrossAxisAlignment.end,
                    children: [
                      Container(
                        width: isMobile ? double.infinity : 420 * sfg,
                        height: 50,
                        margin: const EdgeInsets.only(bottom: 16),
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(25),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.email_outlined, color: Colors.grey, size: 20),
                            const SizedBox(width: 10),
                            const Expanded(
                              child: TextField(
                                style: TextStyle(fontSize: 15),
                                decoration: InputDecoration(
                                  border: InputBorder.none,
                                  isCollapsed: true,
                                  hintText: 'Enter your email address',
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      SizedBox(
                        width: isMobile ? double.infinity : 420 * sfg,
                        height: 50 * sfg,
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.white,
                            foregroundColor: Colors.black,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(25),
                            ),
                          ),
                          onPressed: () {},
                          child: Text(
                            'Subscribe to Newsletter',
                            style: TextStyle(fontSize: 15 * scaleFactor),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            );
          },
        ),
      
    );
  }
}
