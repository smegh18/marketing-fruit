import 'package:flutter/material.dart';
import 'package:Marketing_Fruit/screens/art_arc/frame2340.dart';
import '../../components/next_button.dart';
import '../../components/text_bubble.dart';

class Frame2340d extends StatefulWidget {
  const Frame2340d({super.key});

  @override
  State<Frame2340d> createState() => _Frame2340dState();
}

class _Frame2340dState extends State<Frame2340d> {
  final List<String> messages = [
    "It begins with a quiet meeting at the City Arts Council office—no branding decks, no hashtags. Just a pot of chai, some historical reference books, and a proposal:“Let’s co-create an exhibit that tells the untold stories of this city.”",
    "You're intrigued.In the weeks that follow, you visit archives. Talk to elders. Interview street performers and heritage custodians. You sketch layouts that blend murals with oral histories, shadow puppetry with projection mapping. Local artists join in. One of them brings their entire art class to help paint.",
    "Opening day is unlike anything you've done before.Families walk through in awe. Elderly visitors nod in recognition at familiar street names. A young woman tears up when she hears her grandmother’s voice played in one of the rooms.",
    "Your visitor count doesn’t explode—but people linger. Some walk the maze twice.This is no longer just your project. It’s the city’s."
  ];

  int currentIndex = 0;

  void _handleNext() {
    setState(() {
      if (currentIndex < messages.length - 1) {
        currentIndex++;
      } else {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => Frame2340()),
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
          // Background Image
          SizedBox.expand(
            child: Image.asset(
              'assets/AA4.png',
              fit: BoxFit.cover,
            ),
          ),

          // Text Bubble
          Positioned(
            bottom: screenHeight * 0.18,
            left: screenWidth * 0.05,
            right: screenWidth * 0.05,
            child: TextBubble(
              message: messages[currentIndex],
            ),
          ),

          // Next Button
          Positioned(
            bottom: screenSize.height * 0.05,
            right: screenSize.width * 0.05,
            child: NextButton(
              onTap: _handleNext,
            ),
          ),
        ],
      ),
    );
  }
}
