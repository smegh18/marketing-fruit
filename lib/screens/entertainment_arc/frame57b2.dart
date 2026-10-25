import 'package:flutter/material.dart';
import '../../components/next_button.dart';
import '../../components/player_details.dart';
import '../../components/text_bubble.dart';
import '../../components/entertainment_menu_drawer.dart';
import 'frame57b3.dart';

class Frame57b2 extends StatefulWidget {
  const Frame57b2({super.key});

  @override
  State<Frame57b2> createState() => _Frame57b2State();
}

class _Frame57b2State extends State<Frame57b2> {
  final playerDetails = PlayerDetails();

  @override
  void initState() {
    super.initState();
    playerDetails.saveProgress('frame57b2', null);
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
              'assets/EA4.png',
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

          // Text Bubble - Responsive Position and Width
          Positioned(
            bottom: screenHeight * 0.18,
            left: screenWidth * 0.05,
            right: screenWidth * 0.05,
            child: TextBubble(
              message:
              "You skip the big names and ignore the AI hype. Instead, you place your bets on hungry, undiscovered talent — young actors, freelance directors, indie writers, and passionate crew members who’ve never had their big break.",
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
                    builder: (context) => Frame57b3(),
                  ),
                );
              },
            ),
          ),

          // Entertainment Menu Drawer
          const EntertainmentMenuDrawer(),
        ],
      ),
    );
  }
}
