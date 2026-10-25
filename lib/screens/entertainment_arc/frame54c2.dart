import 'package:flutter/material.dart';
import '../../components/player_details.dart';
import '../../components/text_bubble.dart';
import '../../components/entertainment_menu_drawer.dart';
import 'frame54c3.dart';

class Frame54c2 extends StatefulWidget {
  const Frame54c2({super.key});

  @override
  State<Frame54c2> createState() => _Frame54c2State();
}

class _Frame54c2State extends State<Frame54c2> {
  final playerDetails = PlayerDetails();

  @override
  void initState() {
    super.initState();
    // Save progress when entering this frame
    playerDetails.saveProgress('frame54c2', null);
  }

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;
    final screenHeight = screenSize.height;
    final screenWidth = screenSize.width;

    return Scaffold(
      body: Stack(
        children: [
          // Background Image
          SizedBox.expand(
            child: Image.asset(
              'assets/EA12.png',
              fit: BoxFit.cover,
            ),
          ),

          // Julian Kelly Cartoon - Responsive Position (Commented out as in original)
          // Positioned(
          //   bottom: screenHeight * 0.07,
          //   left: screenWidth * 0.05,
          //   child: Image.asset(
          //     'assets/julian_kelly.png',
          //     height: screenHeight * 0.80,
          //   ),
          // ),

          // Text Bubble - Responsive Position and Width
          Positioned(
            bottom: screenHeight * 0.18,
            left: screenWidth * 0.05,
            right: screenWidth * 0.05,
            child: TextBubble(
              message:
              "This route was powered by community: It created buzz early and gave you moral obligation to deliver. While funding trickled in slower than expected, the emotional support and audience engagement were priceless.",
            ),
          ),

          Positioned(
            bottom: screenSize.height * 0.05,
            right: screenSize.width * 0.05,
            child: GestureDetector(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => Frame54c3(),
                  ),
                );
              },
              child: Image.asset(
                'assets/next_Button.png',
                height: screenSize.height * 0.08,
              ),
            ),
          ),

          // Entertainment Menu Drawer
          const EntertainmentMenuDrawer(),
        ],
      ),
    );
  }
}
