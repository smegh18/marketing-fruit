
import 'package:flutter/material.dart';
import '../../components/next_button.dart';
import '../../components/player_details.dart';
import '../../components/text_bubble.dart';
import '../../components/entertainment_menu_drawer.dart';
import 'frame6.dart';

class Frame5 extends StatefulWidget {
  const Frame5({super.key});

  @override
  State<Frame5> createState() => _Frame5State();
}

class _Frame5State extends State<Frame5> {
  final playerDetails = PlayerDetails();

  final Color bubbleBackground = Color(0xFFDED08B).withOpacity(0.8);

  @override
  void initState() {
    super.initState();
    // Save progress when entering this frame
    playerDetails.saveProgress('frame5', null);
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
              'assets/EA1.png',
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
              "Here is your welcome gift. We have opened your bank account, and credited \$10,000 amount to initiate your business. Spend wisely and make profits.",
            ),
          ),

          Positioned(
            bottom: screenSize.height * 0.05,
            right: screenSize.width * 0.05,
            child: NextButton(
              onTap: () {
                playerDetails.getWallet();
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => Frame6(),
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
