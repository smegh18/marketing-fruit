import 'package:flutter/material.dart';
import 'package:Marketing_Fruit/screens/art_arc/frame2337.dart';
import '../../components/next_button.dart';
import '../../components/text_bubble.dart';

class Frame12f extends StatefulWidget {
  const Frame12f({super.key});

  @override
  State<Frame12f> createState() => _Frame12fState();
}

class _Frame12fState extends State<Frame12f> {
  final List<String> messages = [
    "The theme is locked in. The installations are up. Whether it's surreal projections dancing on warehouse walls or local art breathing life into a quiet theatre, the space finally feels alive. You step back and watch the first few walkthroughs—visitors wander slowly, phones out, voices hushed or excited depending on the mood you’ve created.",
    "Now comes the real decision: how do you price this experience?",
    "You know the creative work isn’t enough on its own. The right pricing strategy can shape your entire audience. Too low, and you risk undercutting your value. Too high, and you could lose potential footfall. The location you chose adds weight to the equation—will your visitors see this as a premium event, a casual escape, or something in between?",
    "You run your fingers across the entry signage, blank for now, and take a deep breath. This isn’t just about ticket prices. It’s about how the world will perceive your art studio from day one."
  ];

  int currentIndex = 0;

  void _handleNext() {
    setState(() {
      if (currentIndex < messages.length - 1) {
        currentIndex++;
      } else {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => Frame2337()),
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
              'assets/AA2.png',
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
