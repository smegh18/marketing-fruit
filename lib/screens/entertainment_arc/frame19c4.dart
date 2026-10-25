import 'package:Marketing_Fruit/components/entertainment_menu_drawer.dart';
import 'package:flutter/material.dart';
import '../../components/next_button.dart';
import '../../components/player_details.dart';
import '../../components/text_bubble.dart';
import 'frame19c5.dart';

class Frame19c4 extends StatefulWidget {
  const Frame19c4({super.key});

  @override
  State<Frame19c4> createState() => _Frame19c4State();
}

class _Frame19c4State extends State<Frame19c4> {
  final playerDetails = PlayerDetails();


  @override
  void initState() {
    super.initState();
    // Save progress when entering this frame
    playerDetails.saveProgress('frame19c4', null);
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
                "Still, there was an upside. The cost of operations was incredibly low. No server costs, no dev team, no support infrastructure. Just content, consistently delivered. More importantly, customer loyalty skyrocketed. Fans followed across platforms, joined mailing lists, and some even started supporting via Patreon, merch sales, and direct donations. The creator’s brand grew faster than it ever could have under a studio deal."
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
                    builder: (context) => Frame19c5(),
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
