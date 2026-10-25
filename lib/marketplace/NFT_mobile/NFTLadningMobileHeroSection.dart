import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class NFTMobileHeroSection extends StatefulWidget {
  final VoidCallback onGetStarted;

  const NFTMobileHeroSection({super.key, required this.onGetStarted});

  @override
  State<NFTMobileHeroSection> createState() => _NFTMobileHeroSectionState();
}

class _NFTMobileHeroSectionState extends State<NFTMobileHeroSection> {
  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Title
          Text(
            "Discover Digital Art &\nCollect NFTs",
            style: GoogleFonts.spaceGrotesk(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: Colors.white,
              height: 1.22,
            ),
          ),
          const SizedBox(height: 12),
          // Subtitle/Description
          Text(
            "NFT marketplace UI created with Anima for Figma. "
                "Collect, buy and sell art from more than 20k NFT artists.",
            style: GoogleFonts.spaceGrotesk(
              fontSize: 14,
              fontWeight: FontWeight.w400,
              color: Colors.white.withOpacity(0.8),
            ),
          ),
          const SizedBox(height: 22),
          // Hero Image
          Center(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(18),
              child: Image.asset(
                'assets/heroanimation.gif', // Replace with your asset path
                width: width * 0.8,
                height: 400,
                fit: BoxFit.cover,
              ),
            ),
          ),
          const SizedBox(height: 24),
          // Get Started Button
          Center(
            child: ElevatedButton.icon(
              onPressed: widget.onGetStarted,
              icon: const Icon(Icons.rocket_launch_rounded, size: 18, color: Colors.white),
              label: Text(
                "Get Started",
                style: GoogleFonts.spaceGrotesk(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFA259FF),
                minimumSize: const Size.fromHeight(46),
                padding: const EdgeInsets.symmetric(horizontal: 24),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
            ),
          ),
          const SizedBox(height: 30),
          // Stats
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: const [
              _StatColumn(count: '240k+', label: 'Total Sale'),
              _StatColumn(count: '100k+', label: 'Auctions'),
              _StatColumn(count: '240k+', label: 'Artists'),
            ],
          ),
        ],
      ),
    );
  }
}

class _StatColumn extends StatelessWidget {
  final String count;
  final String label;

  const _StatColumn({required this.count, required this.label});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          count,
          style: GoogleFonts.spaceGrotesk(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: GoogleFonts.spaceGrotesk(
            fontSize: 12,
            color: Colors.white.withOpacity(0.7),
          ),
        ),
      ],
    );
  }
}
