
import 'package:flutter/material.dart';
import '../../components/next_button.dart';
import '../../components/player_details.dart';
import '../../components/text_bubble.dart';
import '../../components/entertainment_menu_drawer.dart';
import 'frame2.dart';

class Frame1 extends StatefulWidget {
  const Frame1({super.key});

  @override
  State<Frame1> createState() => _Frame1State();
}

class _Frame1State extends State<Frame1> {
  final playerDetails = PlayerDetails();


  @override
  void initState() {
    super.initState();
    // Save progress when entering this frame
    playerDetails.saveProgress('frame1', null);
  }

  final Color bubbleBackground = Color(0xFFDED08B).withOpacity(0.8);

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
              'assets/EA1.png',
              fit: BoxFit.cover,
            ),
          ),

          // Julian Kelly Cartoon
          Positioned(
            bottom: screenHeight * 0.07,
            left: screenWidth * 0.05,
            child: Image.asset(
              'assets/julian_kelly.png',
              height: screenHeight * 0.80,
            ),
          ),

          // Text Bubble
          Positioned(
            bottom: screenHeight * 0.18,
            left: screenWidth * 0.05,
            right: screenWidth * 0.05,
            child: TextBubble(
              message:
              "Greetings, my name is Julian Kelly, and I am your virtual business consultant. I will guide you throughout this simulator and help you navigate through bottle necks.",
            ),
          ),

          // Next Button
          Positioned(
            bottom: screenHeight * 0.05,
            right: screenWidth * 0.05,
            child: NextButton(
              onTap: () {
                playerDetails.getArc("Entertainment");
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => Frame2()),
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
