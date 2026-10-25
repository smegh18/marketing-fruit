import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class SubscribeWidgetMobile extends StatelessWidget {
  final TextEditingController _emailController = TextEditingController();

  SubscribeWidgetMobile({super.key});

  @override
  Widget build(BuildContext context) {
    final double width = MediaQuery.of(context).size.width;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 26),
      child: Container(
        decoration: BoxDecoration(
          color: const Color(0xFF3B3B3B),
          borderRadius: BorderRadius.circular(24),
        ),
        padding: const EdgeInsets.only(top: 20, left: 20, right: 20, bottom: 28),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Top image
            Center(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(18),
                child: Image.asset(
                  'assets/Assets/Photo.png', // update to your asset
                  width: width * 0.75,
                  height: width * 0.48,
                  fit: BoxFit.cover,
                ),
              ),
            ),
            const SizedBox(height: 28),
            // Headline
            Text(
              "Join Our Weekly Digest",
              style: GoogleFonts.poppins(
                fontWeight: FontWeight.bold,
                fontSize: 22,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              "Get exclusive promotions & updates straight to your inbox.",
              style: GoogleFonts.poppins(
                color: Colors.white.withOpacity(0.8),
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 22),
            // Email input
            Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(15),
                color: Colors.white,
              ),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 2),
              child: TextField(
                controller: _emailController,
                style: TextStyle(fontSize: 15),
                decoration: const InputDecoration(
                  border: InputBorder.none,
                  hintText: "Enter Your Email Address",
                  hintStyle: TextStyle(color: Colors.grey),
                ),
              ),
            ),
            const SizedBox(height: 15),
            // Subscribe button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFA259FF),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
                onPressed: () {/* handle subscribe */},
                icon: const Icon(Icons.mail_outline, color: Colors.white),
                label: Text(
                  "Subscribe",
                  style: GoogleFonts.poppins(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                    fontSize: 16,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
