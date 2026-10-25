import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class BrowseCategoriesMobile extends StatelessWidget {
  BrowseCategoriesMobile({super.key});

  final List<_CategoryData> categories = [
    _CategoryData("Art", 'assets/Assets/paint.png', Icons.brush),
    _CategoryData("Collectibles", 'assets/Assets/bandar.png', Icons.palette),
    _CategoryData("Music", 'assets/Assets/music.png', Icons.music_note),
    _CategoryData("Photography", 'assets/Assets/taklu.png', Icons.camera_alt),
    _CategoryData("Video", 'assets/Assets/paint.png', Icons.videocam),
    _CategoryData("Utility", 'assets/Assets/bandar.png', Icons.auto_fix_high),
    _CategoryData("Sport", 'assets/Assets/music.png', Icons.sports_basketball),
    _CategoryData("Virtual Worlds", 'assets/Assets/taklu.png', Icons.public),
  ];

  @override
  Widget build(BuildContext context) {
    final double width = MediaQuery.of(context).size.width;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Browse Categories',
            style: GoogleFonts.poppins(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 20),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: categories.length,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              mainAxisSpacing: 18,
              crossAxisSpacing: 18,
              childAspectRatio: 0.92,
            ),
            itemBuilder: (context, index) {
              final cat = categories[index];
              return _CategoryCard(
                label: cat.label,
                backgroundPath: cat.bgPath,
                icon: cat.icon,
              );
            },
          ),
        ],
      ),
    );
  }
}

class _CategoryData {
  final String label;
  final String bgPath;
  final IconData icon;
  _CategoryData(this.label, this.bgPath, this.icon);
}

class _CategoryCard extends StatelessWidget {
  final String label;
  final String backgroundPath;
  final IconData icon;

  const _CategoryCard({
    required this.label,
    required this.backgroundPath,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.grey[850],
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        children: [
          // Main upper part: background + icon overlay
          Expanded(
            flex: 4,
            child: ClipRRect(
              borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
              child: Stack(
                fit: StackFit.expand,
                children: [
                  Image.asset(
                    backgroundPath,
                    fit: BoxFit.cover,
                  ),
                  // Center(
                  //   child: Icon(
                  //     icon,
                  //     color: Colors.white,
                  //     size: 40,
                  //   ),
                  // ),
                ],
              ),
            ),
          ),
          // Label area
          Container(
            height: 45,
            alignment: Alignment.center,
            decoration: const BoxDecoration(
              color: Color(0xFF333333),
              borderRadius: BorderRadius.vertical(bottom: Radius.circular(20)),
            ),
            child: Text(
              label,
              style: GoogleFonts.workSans(
                color: Colors.white,
                fontWeight: FontWeight.w600,
                fontSize: 15,
              ),
              textAlign: TextAlign.center,
            ),
          ),
        ],
      ),
    );
  }
}
