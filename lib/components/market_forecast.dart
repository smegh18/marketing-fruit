import 'package:flutter/material.dart';

class MarketForecastButton extends StatelessWidget {
  final bool disabled;

  const MarketForecastButton({super.key, this.disabled = false});

  @override
  Widget build(BuildContext context) {
    final dpi = MediaQueryData.fromView(WidgetsBinding.instance.window).devicePixelRatio;
    double scale = 1.0;
    if (dpi > 1.0 && dpi < 2.0) {
      scale = 1.16;
    } else if (dpi >= 2.0)
      scale = 1.3;
    else
      scale = 1.1;
    return IgnorePointer(
      ignoring: disabled,
      child: Opacity(
        opacity: disabled ? 0.85 : 1.0,
        child: LayoutBuilder(
          builder: (context, constraints) {
            final width = constraints.maxWidth;
            final height = width * 0.5 * scale;

            return SizedBox(
              width: width,
              height: height ,
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  // Background with clip for rounded corners
                  ClipRRect(
                    borderRadius: BorderRadius.circular(20),
                    child: Container(
                      decoration: BoxDecoration(
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.5),
                            blurRadius: 8,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Stack(
                        children: [
                          Positioned.fill(
                            child: Image.asset(
                              'assets/pink.png',
                              fit: BoxFit.cover,
                            ),
                          ),
                          Positioned.fill(
                            child: Image.asset(
                              'assets/line.png',
                              fit: BoxFit.cover,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  // Text & percentage
                  Padding(
                    padding: const EdgeInsets.only(top: 20, left: 20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          "Market Forecast",
                          style: TextStyle(
                            fontSize: 20,
                            color: Colors.black87,
                          ),
                        ),
                        const SizedBox(height: 10),
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Stack(
                              children: [
                                Text(
                                  "27%",
                                  style: TextStyle(
                                    fontSize: 68,
                                    fontWeight: FontWeight.bold,
                                    foreground: Paint()
                                      ..style = PaintingStyle.stroke
                                      ..strokeWidth = 4
                                      ..color = Colors.white,
                                  ),
                                ),
                                const Text(
                                  "27%",
                                  style: TextStyle(
                                    fontSize: 68,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.green,
                                    shadows: [
                                      Shadow(
                                        offset: Offset(2, 2),
                                        blurRadius: 4,
                                        color: Colors.black38,
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  // Floating character (outside box)
                  Positioned(
                    right: -10,
                    top: -20,
                    child: SizedBox(
                      height: height + 20,
                      child: Image.asset(
                        'assets/character.png',
                        fit: BoxFit.contain,
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}
