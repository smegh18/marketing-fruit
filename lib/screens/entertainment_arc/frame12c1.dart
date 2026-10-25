import 'package:flutter/material.dart';
import '../../components/next_button.dart';
import '../../components/player_details.dart';
import '../../components/text_bubble.dart';
import '../../components/entertainment_menu_drawer.dart';
import 'frame12c2.dart';

class Frame12c1 extends StatefulWidget {
  const Frame12c1({super.key});

  @override
  State<Frame12c1> createState() => _Frame12c1State();
}

class _Frame12c1State extends State<Frame12c1> {
  final playerDetails = PlayerDetails();

  @override
  void initState() {
    super.initState();
    // Save progress when entering this frame
    playerDetails.saveProgress('frame12c1', null);
  }

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;
    final screenHeight = screenSize.height;
    final screenWidth = screenSize.width;
    final playerDetails = PlayerDetails();

    return Scaffold(
      body: Stack(
        children: [
          // Background Image
          SizedBox.expand(
            child: Image.asset(
              'assets/EA5.png',
              fit: BoxFit.cover,
            ),
          ),

          // Julian Kelly Cartoon - Responsive Position
          // Positioned(
          //   bottom: screenHeight * 0.07, // 8% from bottom
          //   left: screenWidth * 0.05, // Optional: slight left padding
          //   child: Image.asset(
          //     'assets/julian_kelly.png',
          //     height: screenHeight * 0.80, // 65% of screen height
          //   ),
          // ),

          // Text Bubble - Responsive Position and Width
          Positioned(
            bottom: screenHeight * 0.18, // 23% from bottom
            left: screenWidth * 0.05,
            right: screenWidth * 0.05,
            child: TextBubble(
              message:
              "AAh, short form content for social media. It is like the wild west of new age shimmered with virality. A 30-second clips for platforms like TikTok, YouTube Shorts, and Instagram Reels, that could launch a brand of carrier overnight.",
            ),
          ),

          Positioned(
            bottom: screenSize.height * 0.05,
            right: screenSize.width * 0.05,
            child: NextButton(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => Frame12c2(),
                  ),
                );
              },
            ),
          ),

          // Menu Drawer
          const EntertainmentMenuDrawer(),
        ],
      ),
    );
  }
}
