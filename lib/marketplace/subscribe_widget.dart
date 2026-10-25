import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class SubscribeWidget extends StatelessWidget {
  final TextEditingController _emailController = TextEditingController();

  SubscribeWidget({super.key});

  @override
  Widget build(BuildContext context) {
    final pixelRatio = MediaQuery.of(context).devicePixelRatio;
    final baselinePixelRatio = 1.0;

    double t = ((pixelRatio - baselinePixelRatio) / baselinePixelRatio).clamp(0.0, 1.0);
    double scaleFactor = lerpDouble(1.0, 0.8, t)!;
    double sfg = lerpDouble(1.0, 0.75, t)!;
    if (pixelRatio > baselinePixelRatio) {
      // Clamp the values within a reasonable scaling range
      double ratio = baselinePixelRatio / pixelRatio;

      // Prevent too aggressive scaling at 125%
      if ((pixelRatio - 1.0).abs() < 0.3) {
        scaleFactor = ratio * 1.55; // mild scale
        sfg = ratio * 1.1;
      } else {
        scaleFactor = ratio * 1.7; // regular scale
        sfg = ratio * 1.5;
      }
    }
    return Container(
      padding: EdgeInsets.symmetric(horizontal: MediaQuery.of(context).size.width * 0.06 * scaleFactor, vertical: 30 * scaleFactor),
      decoration: BoxDecoration(
        color: const Color(0xFF3B3B3B),
        borderRadius: BorderRadius.circular(24),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
// Astronaut Image
          ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: Image.asset(
              'assets/Assets/Photo.png',
              height: MediaQuery.of(context).size.height * 0.28 * scaleFactor,
              width: MediaQuery.of(context).size.width * 0.22 * scaleFactor,
              fit: BoxFit.cover,
            ),
          ),
          SizedBox(width: 52 * scaleFactor),
// Text & Input
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Join Our Weekly \nDigest',
                  style: GoogleFonts.poppins(
                    fontSize: 28 * scaleFactor,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  'Get Exclusive Promotions & Updates\nStraight To Your Inbox.',
                  style: GoogleFonts.poppins(
                    fontSize: 22 * scaleFactor,
                    color: Colors.white70,
                    height: 1.5,
                  ),
                ),
                const SizedBox(height: 20),
                Stack(
                  children: [
// Email Input Field
                    Container(
                      height: 50 * scaleFactor,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      padding: EdgeInsets.only(left: 16 * scaleFactor, right: 160 * scaleFactor), // leave space for button
                      child: TextField(
                        controller: _emailController,
                        decoration: const InputDecoration(
                          hintText: "Enter your email here",
                          border: InputBorder.none,
                        ),
                      ),
                    ),
// Positioned Subscribe Button (overlapping right side)
                    Positioned(
                      right: 0,
                      top: 0,
                      bottom: 0,
                      child: Container(
                        height: 50 * scaleFactor,
                        padding: EdgeInsets.symmetric(horizontal: 20 * scaleFactor),
                        decoration: BoxDecoration(
                          color: Color(0xFF9F6BFF),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.email_outlined, color: Colors.white),
                            const SizedBox(width: 8),
                            Text(
                              "Subscribe",
                              style: GoogleFonts.poppins(
                                color: Colors.white,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
