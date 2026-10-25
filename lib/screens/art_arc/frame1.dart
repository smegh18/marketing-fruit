import 'package:flutter/material.dart';
import '../../components/next_button.dart';
import '../../components/player_details.dart';
import '../../components/text_bubble.dart';
import 'frame2.dart';

class Frame1 extends StatelessWidget {
  const Frame1({super.key});

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
              'assets/AA1.png',
              fit: BoxFit.cover,
            ),
          ),

          // Julian Kelly Cartoon - Responsive Position
          Positioned(
            bottom: screenHeight * 0.07, // 8% from bottom
            left: screenWidth * 0.05, // Optional: slight left padding
            child: Image.asset(
              'assets/julian_kelly.png',
              height: screenHeight * 0.80, // 65% of screen height
            ),
          ),

          // Text Bubble - Responsive Position and Width
          Positioned(
            bottom: screenHeight * 0.18, // 23% from bottom
            left: screenWidth * 0.05,
            right: screenWidth * 0.05,
            child: TextBubble(
              message:
              "Greetings, my name is Julian Kelly, and I am your virtual business consultant. I will guide you throughout this simulator and help you navigate through bottle necks.",
            ),
          ),

          Positioned(
            bottom: screenSize.height * 0.05,
            right: screenSize.width * 0.05,
            child: NextButton(
              onTap: () {
                playerDetails.getArc("Art");
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => Frame2(),
                  ),
                );
              },
            ),
          ),

        ],
      ),
    );
  }
}
