import 'package:flutter/material.dart';
import 'package:Marketing_Fruit/screens/art_arc/frame2338f.dart';
import '../../components/next_button.dart';
import '../../components/text_bubble.dart';

class Frame2338c extends StatefulWidget {
  const Frame2338c({super.key});

  @override
  State<Frame2338c> createState() => _Frame2338cState();
}

class _Frame2338cState extends State<Frame2338c> {
  final List<String> messages = [
    "Instead of blasting the internet, you go local. You speak at an art school. You walk into nearby cafes and pin posters. You host a free preview for community artists and invite them to contribute installations in the future.",
    "Word spreads slowly but sincerely. The night before your launch, an entire college art class walks in just to “see how it's done.” Parents text each other in WhatsApp groups. By opening day, you see a line forming—not of influencers, but of neighbors, teachers, and local creatives.",
    "It’s a softer opening, more personal. Some even bring food. The experience feels less like a spectacle and more like a movement. But in the back of your mind, you wonder—will this kind of loyalty scale?"
  ];

  int currentIndex = 0;

  void _handleNext() {
    setState(() {
      if (currentIndex < messages.length - 1) {
        currentIndex++;
      } else {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => Frame2338f()),
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
              'assets/AA5.png',
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
