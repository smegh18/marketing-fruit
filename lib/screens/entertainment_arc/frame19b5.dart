import 'package:Marketing_Fruit/components/entertainment_menu_drawer.dart';
import 'package:flutter/material.dart';
import 'package:Marketing_Fruit/screens/entertainment_arc/frame19f1.dart';
import '../../components/next_button.dart';
import '../../components/player_details.dart';
import '../../components/text_bubble.dart';

class Frame19b5 extends StatefulWidget {
  const Frame19b5({super.key});

  @override
  State<Frame19b5> createState() => _Frame19b5State();
}

class _Frame19b5State extends State<Frame19b5> {
  final playerDetails = PlayerDetails();


  @override
  void initState() {
    super.initState();
    // Save progress when entering this frame
    playerDetails.saveProgress('frame19b5', null);
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
              "By the end of the quarter, the platform hadn’t gone viral, but it had survived — even grown. It wasn’t the fastest route to success, but it was a foundation. One that could scale. One that couldn’t be taken away. And in the long game of entertainment, ownership was a power most creators never got to hold.",
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
                    builder: (context) => Frame19f1(),
                  ),
                );
              },
            ),
          ),
          EntertainmentMenuDrawer()
        ],
      ),
    );
  }
}
