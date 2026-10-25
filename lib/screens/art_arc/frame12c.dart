import 'package:flutter/material.dart';
import 'package:Marketing_Fruit/screens/art_arc/frame12f.dart';
import '../../components/next_button.dart';
import '../../components/text_bubble.dart';

class Frame12c extends StatefulWidget {
  const Frame12c({super.key});

  @override
  State<Frame12c> createState() => _Frame12cState();
}

class _Frame12cState extends State<Frame12c> {
  final List<String> messages = [
    "You leaned into nostalgia. The maze featured vintage-style artwork, sepia sketches, faded oil portraits, and pieces echoing your region’s forgotten styles. The lighting was warm and quiet. Visitors moved slowly, taking it all in. Older patrons lingered, sharing stories of childhood and heritage.",
    "While it didn’t go viral, it struck a chord with a niche audience. A city official even approached you about a heritage grant. Now you’re left wondering—should you double down on the cultural angle and apply for funding, or steer your next theme toward something more contemporary and marketable?"
  ];

  int currentIndex = 0;

  void _handleNext() {
    setState(() {
      if (currentIndex < messages.length - 1) {
        currentIndex++;
      } else {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => Frame12f()),
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
