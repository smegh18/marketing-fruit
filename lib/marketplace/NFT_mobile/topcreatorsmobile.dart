import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class TopCreatorsMobile extends StatelessWidget {
  final VoidCallback onViewRankings;
  const TopCreatorsMobile({super.key, required this.onViewRankings});

  @override
  Widget build(BuildContext context) {
    final creators = [
      {'name': 'Keepitreal', 'sales': '34.53', 'image': 'assets/Assets/tc3.png'},
      {'name': 'DigiLab', 'sales': '32.13', 'image': 'assets/Assets/tc1.png'},
      {'name': 'GravityOne', 'sales': '28.93', 'image': 'assets/Assets/tc4.png'},
      {'name': 'Juanie', 'sales': '25.30', 'image': 'assets/Assets/tc5.png'},
      {'name': 'BlueWhale', 'sales': '22.22', 'image': 'assets/Assets/tc6.png'},
    ];
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 22),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "Top Creators",
            style: GoogleFonts.poppins(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            "Checkout Top Rated Creators on the NFT Marketplace",
            style: GoogleFonts.poppins(
              fontSize: 14,
              color: Colors.white.withOpacity(0.8),
            ),
          ),
          const SizedBox(height: 20),
          // Creators List
          Column(
            children: List.generate(creators.length, (index) {
              final creator = creators[index];
              return Padding(
                padding: const EdgeInsets.only(bottom: 14.0),
                child: Container(
                  decoration: BoxDecoration(
                    color: const Color(0xFF353535),
                    borderRadius: BorderRadius.circular(18),
                  ),
                  padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                  child: Row(
                    children: [
                      // Stack for avatar + number at top-left
                      Stack(
                        clipBehavior: Clip.none,
                        children: [
                          CircleAvatar(
                            radius: 26,
                            backgroundColor: Colors.white24,
                            backgroundImage: AssetImage(creator['image']!),
                          ),
                          Positioned(
                            top: -7,
                            left: -7,
                            child: Container(
                              width: 26,
                              height: 26,
                              decoration: BoxDecoration(
                                color: const Color(0xFF232323),
                                borderRadius: BorderRadius.circular(13),
                                border: Border.all(color: Colors.white12, width: 2),
                              ),
                              alignment: Alignment.center,
                              child: Text(
                                '${index + 1}',
                                style: GoogleFonts.poppins(
                                  color: Colors.white,
                                  fontSize: 15,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(width: 18),
                      // Name and sales
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              creator['name']!,
                              style: GoogleFonts.poppins(
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                                fontSize: 16,
                              ),
                            ),
                            const SizedBox(height: 3),
                            Row(
                              children: [
                                Text(
                                  'Total Sales: ',
                                  style: GoogleFonts.poppins(
                                    color: Colors.white.withOpacity(0.56),
                                    fontSize: 13,
                                  ),
                                ),
                                Text(
                                  "${creator['sales']} ETH",
                                  style: GoogleFonts.poppins(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 13,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }),
          ),
          const SizedBox(height: 16),
          // View Rankings Button
          Center(
            child: SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: onViewRankings,
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  backgroundColor: Colors.transparent,
                  side: const BorderSide(color: Color(0xFFA259FF), width: 2),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                ),
                icon: Icon(Icons.rocket_launch_rounded, color: Color(0xFFA259FF)),
                label: Text(
                  "View Rankings",
                  style: GoogleFonts.spaceGrotesk(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
