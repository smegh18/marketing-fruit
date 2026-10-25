import 'package:Marketing_Fruit/components/entertainment_menu_drawer.dart';
import 'package:flutter/material.dart';
import 'package:Marketing_Fruit/screens/entertainment_arc/frame2345f.dart';
import '../../components/next_button.dart';
import '../../components/player_details.dart';
import '../../components/text_bubble.dart';

class Frame2346b extends StatefulWidget {
  const Frame2346b({super.key});

  @override
  State<Frame2346b> createState() => _Frame2346bState();
}

class _Frame2346bState extends State<Frame2346b> {
  final List<String> messages = [
    "While the industry paused, you lit a match in the dark.",
    "You launched an open campaign: “#YourStoryMatters.” Fans, creators, even people stuck in studio apartments began uploading skits, monologues, and homemade shorts under your label. Your job shifted from producer to curator. No shoots, no flights—just clever editing, branding, and giving a platform to everyday creators.",
    "The results? Explosive.Your channel traffic skyrocketed. Engagement broke records. Advertisers, looking for positive noise, started calling. You weren’t producing big-budget content—but you were creating something more valuable: community."
  ];

  int currentIndex = 0;
  final playerDetails = PlayerDetails();

  @override
  void initState() {
    super.initState();
    playerDetails.saveProgress('frame2346b', null);
  }

  void _handleNext() {
    setState(() {
      if (currentIndex < messages.length - 1) {
        currentIndex++;
        playerDetails.saveProgress('frame2346b', null);
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
