import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class BrowseCategoriesSection extends StatelessWidget {
  final ScrollController _scrollController = ScrollController();

  final List<Map<String, String>> categories = [
    {'label': 'Art', 'bg': 'assets/Assets/paint.png'},
    {'label': 'Collectibles', 'bg': 'assets/Assets/bandar.png'},
    {'label': 'Music', 'bg': 'assets/Assets/music.png'},
    {'label': 'Photography', 'bg': 'assets/Assets/taklu.png'},
    {'label': 'Gaming', 'bg': 'assets/Assets/paint.png'},
    {'label': 'Virtual Worlds', 'bg': 'assets/Assets/bandar.png'},
    {'label': 'Domain Names', 'bg': 'assets/Assets/music.png'},
    {'label': 'Memes', 'bg': 'assets/Assets/taklu.png'},
  ];

  BrowseCategoriesSection({super.key});

  @override
  Widget build(BuildContext context) {
    final pixelRatio = MediaQuery.of(context).devicePixelRatio;
    final baselinePixelRatio = 1.0;

    double t = ((pixelRatio - baselinePixelRatio) / baselinePixelRatio).clamp(0.0, 1.0);
    double scaleFactor = lerpDouble(1.0, 0.8, t)!;
    double sfg = lerpDouble(1.0, 0.75, t)!;
    if (pixelRatio < 2.0 ) {
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
    }
    return Padding(
      padding: EdgeInsets.symmetric(
        horizontal: MediaQuery.of(context).size.width * 0.065 * scaleFactor,
        vertical: 40 * scaleFactor,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Browse Categories',
            style: GoogleFonts.poppins(
              fontSize: 28 * scaleFactor,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          SizedBox(height: 30 * scaleFactor),
          SizedBox(
            height: MediaQuery.of(context).size.height * 0.32 * scaleFactor,
            child: Scrollbar(
              controller: _scrollController,
              thumbVisibility: true,
              trackVisibility: true,
              thickness: 6,
              radius: const Radius.circular(4),
              child: SingleChildScrollView(
                controller: _scrollController,
                scrollDirection: Axis.horizontal,
                child: Padding(
                  padding: const EdgeInsets.only(bottom: 30.0), // space between cards and scrollbar
                  child: Row(
                    children: categories.map((category) {
                      return Padding(
                        padding: const EdgeInsets.only(right: 30),
                        child: _CategoryCard(
                          label: category['label']!,
                          backgroundPath: category['bg']!,
                        ),
                      );
                    }).toList(),
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

class _CategoryCard extends StatefulWidget {
  final String label;
  final String backgroundPath;

  const _CategoryCard({
    required this.label,
    required this.backgroundPath,
  });

  @override
  State<_CategoryCard> createState() => _CategoryCardState();
}

class _CategoryCardState extends State<_CategoryCard> {
  bool isHovered = false;


  @override
  Widget build(BuildContext context) {
    final pixelRatio = MediaQuery.of(context).devicePixelRatio;
    final baselinePixelRatio = 1.0;

    final bool isMacOS = Theme.of(context).platform == TargetPlatform.macOS;
    double t = ((pixelRatio - baselinePixelRatio) / baselinePixelRatio).clamp(0.0, 1.0);
    double scaleFactor = lerpDouble(1.0, 0.8, t)!;
    double sfg = lerpDouble(1.0, 0.75, t)!;
    if (pixelRatio < 2.0 ) {
      if (pixelRatio > baselinePixelRatio) {
        // Clamp the values within a reasonable scaling range
        double ratio = baselinePixelRatio / pixelRatio;

        // Prevent too aggressive scaling at 125%
        if ((pixelRatio - 1.0).abs() < 0.3) {
          scaleFactor = ratio * 1.05; // mild scale
          sfg = ratio * 1.1;
        } else {
          scaleFactor = ratio * 1.3; // regular scale
          sfg = ratio * 1.5;
        }
      }
    }
    double cardBaseWidthMultiplier = 0.14;
    return MouseRegion(
      onEnter: (_) => setState(() => isHovered = true),
      onExit: (_) => setState(() => isHovered = false),
      child: AnimatedScale(
        scale: isHovered ? 0.95 : 1.0,
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOut,
        child: Container(
          width: isMacOS ? MediaQuery.of(context).size.width * cardBaseWidthMultiplier * 0.85 : MediaQuery.of(context).size.width * cardBaseWidthMultiplier * sfg,
          height: MediaQuery.of(context).size.height * 0.30 * sfg,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            color: Colors.grey[850],
          ),
          child: Column(
            children: [
              Expanded(
                flex: 1,
                child: ClipRRect(
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      Image.asset(
                        widget.backgroundPath,
                        fit: BoxFit.fill,
                      ),
                      // Center(
                      //   child: Image.asset(
                      //     widget.iconPath,
                      //     color: Colors.white,
                      //     width: 40,
                      //     height: 40,
                      //   ),
                      // ),
                    ],
                  ),
                ),
              ),
              Container(
                height: 70 * scaleFactor,
                alignment: Alignment.center,
                decoration: const BoxDecoration(
                  color: Color(0xFF333333),
                  borderRadius: BorderRadius.vertical(bottom: Radius.circular(20)),
                ),
                child: Text(
                  widget.label,
                  style: GoogleFonts.workSans(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                    fontSize: 22 * scaleFactor,
                  ),
                  textAlign: TextAlign.start,
                  textDirection: TextDirection.ltr,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
