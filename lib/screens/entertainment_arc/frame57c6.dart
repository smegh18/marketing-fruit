import 'package:flutter/material.dart';
import '../../components/player_details.dart';
import '../../components/text_bubble.dart';
import '../../components/entertainment_menu_drawer.dart';
import 'frame57c7.dart';

class Frame57c6 extends StatefulWidget {
  const Frame57c6({super.key});

  @override
  State<Frame57c6> createState() => _Frame57c6State();
}

class _Frame57c6State extends State<Frame57c6> {
  final playerDetails = PlayerDetails();

  @override
  void initState() {
    super.initState();
    playerDetails.saveProgress('frame57c6', null);
  }

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;
    final screenHeight = screenSize.height;
    final screenWidth = screenSize.width;

    return Scaffold(
      body: Stack(
        children: [
          SizedBox.expand(
            child: Image.asset(
              'assets/EA11.png',
              fit: BoxFit.cover,
            ),
          ),
          // Julian Kelly Cartoon - Responsive Position (commented out as original)
          // Positioned(
          //   bottom: screenHeight * 0.07,
          //   left: screenWidth * 0.05,
          //   child: Image.asset(
          //     'assets/julian_kelly.png',
          //     height: screenHeight * 0.80,
          //   ),
          // ),
          Positioned(
            bottom: screenHeight * 0.18,
            left: screenWidth * 0.05,
            right: screenWidth * 0.05,
            child: TextBubble(
              message:
              "AI writes the scripts based on trending topics and sentiment analysis. You feed prompts and themes, and within seconds, full episodes are generated — complete with dialogue, character arcs, and even visual storyboards.",
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
                    builder: (context) => Frame57c7(),
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
