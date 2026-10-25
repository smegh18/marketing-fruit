import 'package:flutter/material.dart';
import 'package:Marketing_Fruit/screens/art_arc/frame12.dart';
import '../../components/next_button.dart';
import '../../components/text_bubble.dart';

class Frame57d extends StatefulWidget {
  const Frame57d({super.key});

  @override
  State<Frame57d> createState() => _Frame57dState();
}

class _Frame57dState extends State<Frame57d> {
  final List<String> messages = [
    "You took a risk—an old, half-forgotten theatre on the outskirts. The history oozes from the walls, and the rent was a steal. You restored the foyer, cleaned the main hall, and let the age of the building become part of the experience. Visitors called it hauntingly beautiful.",
    "But getting people there is the hard part. Public transport’s spotty, and the location doesn't attract casual drop-ins. You're relying heavily on word of mouth and destination marketing. Now you're considering whether to invest in shuttle partnerships and aggressive promotions—or slowly build a niche cult following and grow organically."
  ];

  int currentIndex = 0;

  void _handleNext() {
    setState(() {
      if (currentIndex < messages.length - 1) {
        currentIndex++;
      } else {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => Frame12()),
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
