import 'package:Marketing_Fruit/components/entertainment_menu_drawer.dart';
import 'package:flutter/material.dart';
import 'package:Marketing_Fruit/screens/entertainment_arc/frame2345f.dart';
import '../../components/next_button.dart';
import '../../components/player_details.dart';
import '../../components/text_bubble.dart';

class Frame2345d extends StatefulWidget {
  const Frame2345d({super.key});

  @override
  State<Frame2345d> createState() => _Frame2345dState();
}

class _Frame2345dState extends State<Frame2345d> {
  final List<String> messages = [
    "You didn’t just respond—you roared. A calculated media blitz painted the rival as gatekeepers scared of innovation. Creators you had supported went public with stories of suppression in the industry. Your brand became a rallying cry for the small, the bold, the original.",
    "But the firestorm was hard to control. Some industry execs appreciated the passion. Others saw it as reckless. Algorithms favored the drama, sending your name trending—but not always in the way you wanted. The controversy boosted engagement, but also made platforms wary.",
    "You emerged with more followers than ever, but also more scrutiny. You’d lit a torch—but whether it guided or burned depended on your next move."
  ];

  int currentIndex = 0;
  final playerDetails = PlayerDetails();

  @override
  void initState() {
    super.initState();
    playerDetails.saveProgress('frame2345d', null);
  }

  void _handleNext() {
    setState(() {
      if (currentIndex < messages.length - 1) {
        currentIndex++;
        playerDetails.saveProgress('frame2345d', null);
      } else {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => Frame2345f()),
        );
      }
    });
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
              'assets/EA14.png',
              fit: BoxFit.cover,
            ),
          ),
          Positioned(
            bottom: screenHeight * 0.18,
            left: screenWidth * 0.05,
            right: screenWidth * 0.05,
            child: TextBubble(
              message: messages[currentIndex],
            ),
          ),
          Positioned(
            bottom: screenSize.height * 0.05,
            right: screenSize.width * 0.05,
            child: NextButton(
              onTap: _handleNext,
            ),
          ),
          EntertainmentMenuDrawer()
        ],
      ),
    );
  }
}
