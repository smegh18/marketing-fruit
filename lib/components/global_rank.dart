import 'package:flutter/material.dart';

class GlobalRankCard extends StatelessWidget {
  final bool disabled;
  const GlobalRankCard({super.key, this.disabled = false});

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

            return SizedBox(
              width: width,
              height: width * 0.5 * scale, // Makes it square and ensures bounded height
              child: ClipRRect(
                borderRadius: BorderRadius.circular(24),
                child: Container(
                  decoration: BoxDecoration(
                    color: const Color(0xFFFCD758),
                    borderRadius: BorderRadius.circular(24),
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
                      // Slanted background lines safely wrapped
                      Positioned.fill(
                        child: Image.asset(
                          'assets/line.png',
                          fit: BoxFit.cover,
                        ),
                      ),

                      // Text and content
                      Padding(
                        padding: const EdgeInsets.only(left: 20, top: 20),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              "Global Rank",
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w600,
                                color: Colors.black87,
                              ),
                            ),
                            const SizedBox(height: 12),
                            const Text(
                              "750",
                              style: TextStyle(
                                fontSize: 38,
                                fontWeight: FontWeight.bold,
                                color: Colors.black,
                              ),
                            ),
                            const SizedBox(height: 20),
                            GestureDetector(
                              onTap: () {
                                // TODO: Handle leaderboard navigation
                              },
                              child: const Text.rich(
                                TextSpan(
                                  text: "View",
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: Colors.black87,
                                  ),
                                  children: [
                                    TextSpan(text: "\n"),
                                    TextSpan(
                                      text: "Leaderboard",
                                      style: TextStyle(
                                        decoration: TextDecoration.underline,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),

                      // Icon image, now constrained
                      Positioned(
                        right: 10,
                        bottom: 20,
                        child: SizedBox(
                          width: width * 0.4,
                          height: width * 0.4,
                          child: Image.asset(
                            'assets/paisa.png',
                            fit: BoxFit.contain,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
