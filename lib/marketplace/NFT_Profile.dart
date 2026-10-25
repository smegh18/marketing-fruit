import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:Marketing_Fruit/marketplace/NFT_grid.dart';
import 'package:Marketing_Fruit/marketplace/subscribe_widget.dart';


class NftProfileScreen extends StatefulWidget {
  const NftProfileScreen({super.key});

  @override
  _NftProfileScreenState createState() => _NftProfileScreenState();
}

class _NftProfileScreenState extends State<NftProfileScreen> {

  int _selectedIndex = 6;

  void _onSidebarItemSelected(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    final screenWidth = MediaQuery.of(context).size.width;
    final pixelRatio = MediaQuery.of(context).devicePixelRatio;
    final baselinePixelRatio = 1.0;

    double t = ((pixelRatio - baselinePixelRatio) / baselinePixelRatio).clamp(0.0, 1.0);
    double scaleFactor = lerpDouble(1.0, 0.8, t)!;
    double sfg = lerpDouble(1.0, 0.75, t)!;
    double sfgg = lerpDouble(1.0, 0.75, t)!;
    if (pixelRatio < 2.0) {
      if (pixelRatio > baselinePixelRatio) {
        // Clamp the values within a reasonable scaling range
        double ratio = baselinePixelRatio / pixelRatio;

        // Prevent too aggressive scaling at 125%
        if ((pixelRatio - 1.0).abs() < 0.3) {
          scaleFactor = ratio * 1.05; // mild scale
          sfg = ratio * 1.1;
          sfgg = ratio * 1.1;
        } else {
          scaleFactor = ratio * 1.1; // regular scale
          sfg = ratio * 1.4;
          sfgg = ratio * 1.82;
        }
      }
    } else{
      scaleFactor = 1.0;
      sfg = 1.0;
      sfgg = 0.65;
    }
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        color: const Color(0xFF2B2B2B),
      ),
      child: Row(
        children: [
          // SidebarWidget(onItemSelected: _onSidebarItemSelected, selectedIndex: 100,), // Add your custom sidebar here
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                children: [
                  // Top Banner and Avatar
                  Stack(
                    clipBehavior: Clip.none,
                    children: [
                     Container(
                       decoration: BoxDecoration(
                         borderRadius: BorderRadius.circular(20),
                       ),
                       child:  Image.asset(
                         'assets/Assets/banner.png',
                         width: double.infinity,
                         height: screenHeight * 0.25 * sfg,
                         fit: BoxFit.cover,
                       ),
                     ),
                      Positioned(
                        top: screenHeight * 0.25 - 50,
                        left: screenWidth * 0.1,
                        child: Container(
                          padding: const EdgeInsets.all(3),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(16),
                            child: Image.asset(
                              'assets/Assets/chokor.png',
                              width: 100 * scaleFactor,
                              height: 100 * scaleFactor,
                              fit: BoxFit.cover,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),

                  // Profile Content
                  Padding(
                    padding: EdgeInsets.symmetric(
                      horizontal: screenWidth * 0.065 * scaleFactor,
                      vertical: screenHeight * 0.1 * scaleFactor,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Name and Follow Button
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Animakid',
                              style: GoogleFonts.poppins(
                                fontSize: 28 * scaleFactor,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                            ElevatedButton.icon(
                              style: ElevatedButton.styleFrom(
                                side: const BorderSide(color: Color(0xFF8E44F7), width: 1.5),
                                foregroundColor: Colors.white,
                                backgroundColor: Color(0xFF2B2B2B),
                                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                                fixedSize: Size(screenHeight * 0.23 * scaleFactor, screenHeight * 0.05 * scaleFactor),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16),
                                ),
                              ),
                              onPressed: () {},
                              icon: const Icon(Icons.add),
                              label: const Text('Follow'),
                            ),
                          ],
                        ),
                        SizedBox(height: 16 * scaleFactor),

                        // Stats
                        Row(
                          mainAxisAlignment: MainAxisAlignment.start,
                          children: [
                            _StatItem(title: 'Volume', value: '250k+'),
                            SizedBox(width: 50 * scaleFactor),
                            _StatItem(title: 'Nfts Sold', value: '50+'),
                            SizedBox(width: 50 * scaleFactor),
                            _StatItem(title: 'Followers', value: '3000+'),
                          ],
                        ),
                        SizedBox(height: 24 * scaleFactor),

                        // Bio
                        Text(
                          'Bio',
                          style: GoogleFonts.poppins(fontSize: 22 * scaleFactor, fontWeight: FontWeight.bold, color: Colors.white70),
                        ),
                        SizedBox(height: 8 * scaleFactor),
                        Text(
                          'The Internet\'s Friendliest Designer Kid.',
                          style: GoogleFonts.poppins(color: Colors.white, fontSize: 22 * scaleFactor),
                        ),
                        SizedBox(height: 24 * scaleFactor),

                        // Links
                        Text(
                          'Links',
                          style: GoogleFonts.poppins(fontSize: 22 * scaleFactor, fontWeight: FontWeight.bold, color: Colors.white70),
                        ),
                        SizedBox(height: 8 * scaleFactor),
                        Row(
                          children: [
                            Icon(Icons.language, color: Colors.white70),
                            SizedBox(width: 16 ),
                            Icon(Icons.discord, color: Colors.white70),
                            SizedBox(width: 16),
                            Icon(Icons.play_arrow_sharp, color: Colors.white70),
                            SizedBox(width: 16),
                            Icon(Icons.tiktok, color: Colors.white70),
                            SizedBox(width: 16),
                            Icon(Icons.add_a_photo_outlined, color: Colors.white70),
                          ],
                        ),
                        SizedBox(height: 24 * scaleFactor),

                        _buildCategoryBar(),
                      ],
                    ),
                  ),

                  // NFT Grid
                  SizedBox(height: MediaQuery.of(context).size.height * 1.6 * sfgg, child: NFTGrid()),

                  // Subscribe Section
                  SizedBox(height: 20 * scaleFactor),
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: screenWidth * 0.06 * scaleFactor),
                    child: SubscribeWidget(),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }



  Widget _buildCategoryBar() {
    final pixelRatio = MediaQuery.of(context).devicePixelRatio;
    final baselinePixelRatio = 1.0;

    double t = ((pixelRatio - baselinePixelRatio) / baselinePixelRatio).clamp(0.0, 1.0);
    double scaleFactor = lerpDouble(1.0, 0.8, t)!;
    double sfg = lerpDouble(1.0, 0.75, t)!;
    double sfgg = lerpDouble(1.0, 0.75, t)!;
    if (pixelRatio < 2.0) {
      if (pixelRatio > baselinePixelRatio) {
        // Clamp the values within a reasonable scaling range
        double ratio = baselinePixelRatio / pixelRatio;

        // Prevent too aggressive scaling at 125%
        if ((pixelRatio - 1.0).abs() < 0.3) {
          scaleFactor = ratio * 1.05; // mild scale
          sfg = ratio * 1.1;
          sfgg = ratio * 1.1;
        } else {
          scaleFactor = ratio * 1.1; // regular scale
          sfg = ratio * 1.4;
          sfgg = ratio * 1.8;
        }
      }
    } else
      {
      scaleFactor = 1.0;
      sfg = 1.0;
      sfgg = 0.65;
    }
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 12),
      child: Container(
        decoration: BoxDecoration(
          border: Border(
            bottom: BorderSide(color: Colors.white24, width: 1),
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              'Created',
              style: GoogleFonts.poppins(
                fontWeight: FontWeight.bold,
                color: Colors.white,
                fontSize: 22 * scaleFactor,
                letterSpacing: 0.5,
              ),
            ),
            SizedBox(width: 8),
            Container(
              padding: EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.white24,
                borderRadius: BorderRadius.circular(18),
              ),
              child: Text(
                '302',
                style: GoogleFonts.spaceMono(
                  color: Colors.white70,
                  fontSize: 16 * scaleFactor,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StatItem extends StatelessWidget {
  final String title;
  final String value;

  const _StatItem({required this.title, required this.value});

  @override
  Widget build(BuildContext context) {
    final pixelRatio = MediaQuery.of(context).devicePixelRatio;
    final baselinePixelRatio = 1.0;

    double t = ((pixelRatio - baselinePixelRatio) / baselinePixelRatio).clamp(0.0, 1.0);
    double scaleFactor = lerpDouble(1.0, 0.8, t)!;
    double sfg = lerpDouble(1.0, 0.75, t)!;
    double sfgg = lerpDouble(1.0, 0.75, t)!;
    if (pixelRatio > baselinePixelRatio) {
      // Clamp the values within a reasonable scaling range
      double ratio = baselinePixelRatio / pixelRatio;

      // Prevent too aggressive scaling at 125%
      if ((pixelRatio - 1.0).abs() < 0.3) {
        scaleFactor = ratio * 1.05; // mild scale
        sfg = ratio * 1.1;
        sfgg = ratio * 1.1;
      } else {
        scaleFactor = ratio * 1.1; // regular scale
        sfg = ratio * 1.4;
        sfgg = ratio * 1.8;
      }
    }
    return Column(
      children: [
        Text(
          value,
          style: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 28 * scaleFactor, color: Colors.white),
        ),
        const SizedBox(height: 4),
        Text(
          title,
          style: GoogleFonts.poppins(fontSize: 22 * scaleFactor,color: Colors.white70),
        ),
      ],
    );
  }
}
