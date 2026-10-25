import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class TopCreatorsScreen extends StatefulWidget {
  final VoidCallback onCreatorTap;
  final double padding;
  const TopCreatorsScreen({super.key, required this.padding, required this.onCreatorTap});

  @override
  State<TopCreatorsScreen> createState() => _TopCreatorsScreenState();
}

class _TopCreatorsScreenState extends State<TopCreatorsScreen> {
  bool isHovered = false;

  @override
  Widget build(BuildContext context) {
    final creators = [
      {'name': 'Keepitreal', 'sales': '34.53', 'image': 'assets/Assets/tc3.png'},
      {'name': 'Digilab', 'sales': '34.53', 'image': 'assets/Assets/tc1.png'},
      {'name': 'Gravityone', 'sales': '34.53', 'image': 'assets/Assets/tc4.png'},
      {'name': 'Juanie', 'sales': '34.53', 'image': 'assets/Assets/tc5.png'},
      {'name': 'Bluewhale', 'sales': '34.53', 'image': 'assets/Assets/tc6.png'},
      {'name': 'Mr Fox', 'sales': '34.53', 'image': 'assets/Assets/tc7.png'},
      {'name': 'Shroomie', 'sales': '34.53', 'image': 'assets/Assets/tc8.png'},
      {'name': 'Robotica', 'sales': '34.53', 'image': 'assets/Assets/tc9.png'},
      {'name': 'Rustyrobot', 'sales': '34.53', 'image': 'assets/Assets/tc2.png'},
      {'name': 'Animakid', 'sales': '34.53', 'image': 'assets/Assets/hero_image.png'},
      {'name': 'Dotgu', 'sales': '34.53', 'image': 'assets/Assets/tc10.png'},
      {'name': 'Ghiblier', 'sales': '34.53', 'image': 'assets/Assets/tc11.png'},
    ];

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
        scaleFactor = ratio * 1.35; // mild scale
        sfg = ratio * 1.1;
      } else {
        scaleFactor = ratio * 1.5; // regular scale
        sfg = ratio * 1.5;
      }
    }
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: MediaQuery.of(context).size.width * 0.065 * scaleFactor),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Top Brands & Creators',
                    style: GoogleFonts.poppins(
                      fontSize: 28 * scaleFactor,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Checkout Top Rated Creators On The Nft Marketplace',
                    style: GoogleFonts.poppins(color: Colors.white70, fontSize: 22 * scaleFactor,fontWeight: FontWeight.normal),
                  ),
                ],
              ),
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  fixedSize: Size(245 * scaleFactor, 60 * scaleFactor),
                  backgroundColor: Color(0xFF2B2B2B),
                  side: BorderSide(color: Colors.purple.shade700,width: 2.0),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.all(Radius.circular(16))),
                ),
                onPressed: () {
                },
                icon: Icon(Icons.search,color: Colors.purple,),
                label: Text(
                  'Search',
                  style: GoogleFonts.workSans(color: Colors.white,fontSize: 16 * scaleFactor,fontWeight: FontWeight.w600),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          // Grid
          // Grid
          GridView.builder(
              padding: EdgeInsets.symmetric(horizontal: 30 * scaleFactor,vertical: 20 * scaleFactor),
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: creators.length,
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3 ,
                crossAxisSpacing: 38 * scaleFactor,
                mainAxisSpacing: 38 * scaleFactor,
                childAspectRatio: 1, // Makes each item square
              ),
              itemBuilder: (context, index) {
                final creator = creators[index];
                return StatefulBuilder(
                  builder: (context, setState) {

                    return MouseRegion(
                      onEnter: (_) => setState(() => isHovered = true),
                      onExit: (_) => setState(() => isHovered = false),
                      child: GestureDetector(
                        onTap: () {
                          widget.onCreatorTap();
                        },
                        child: AnimatedScale(
                          scale: isHovered ? 0.95 : 1.0,
                          duration: const Duration(milliseconds: 200),
                          curve: Curves.easeOut,
                          child: Container(
                            height: MediaQuery.of(context).size.height * 0.1 * scaleFactor,
                            width: MediaQuery.of(context).size.width * 0.1 * scaleFactor,
                            decoration: BoxDecoration(
                              color: Colors.grey[800],
                              borderRadius: BorderRadius.circular(20),
                            ),
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Align(
                                  alignment: Alignment.topLeft,
                                  child: CircleAvatar(
                                    radius: 14 * scaleFactor,
                                    backgroundColor: Colors.black26,
                                    child: Text(
                                      '${index + 1}',
                                      style: TextStyle(
                                        color: Colors.grey,
                                        fontSize: 14 * scaleFactor,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                ),
                                Align(
                                  alignment: Alignment.topCenter,
                                  child: CircleAvatar(
                                    radius: 60 * scaleFactor,
                                    backgroundImage: AssetImage(creator['image']!),
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  creator['name']!,
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                    fontSize: 22 * scaleFactor,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text.rich(
                                  TextSpan(
                                    children: [
                                      TextSpan(
                                        text: 'Sales: ',
                                        style: TextStyle(color: Colors.white70, fontSize: 16 * scaleFactor),
                                      ),
                                      TextSpan(
                                        text: '${creator['sales']} ETH',
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontWeight: FontWeight.bold,
                                          fontSize: 16 * scaleFactor,
                                        ),
                                      ),
                                    ],
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                );
              }

          ),

        ],
      ),
    );
  }
}
