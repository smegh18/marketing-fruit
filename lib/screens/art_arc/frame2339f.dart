import 'package:flutter/material.dart';
import 'package:Marketing_Fruit/screens/art_arc/frame2340.dart';
import '../../components/next_button.dart';
import '../../components/text_bubble.dart';

class Frame2339f extends StatefulWidget {
  const Frame2339f({super.key});

  @override
  State<Frame2339f> createState() => _Frame2339fState();
}

class _Frame2339fState extends State<Frame2339f> {
  final List<String> messages = [
    "The second month has barely begun, and already your inbox is filled with invitations—from local schools asking for workshops, to a surprise email with the subject line: Let’s Build Something Bigger — From Marketing Fruit",
    "You open it. They’ve seen your work. Loved the originality. They believe your interactive maze format could scale. Nationwide. Maybe even globally.They want in. But not just as a partner. As a visible collaborator.",
    "You scroll through the pitch deck: funding, promotion, infrastructure support, and more. But there’s branding. Integration. And a creative leash.You lean back in your chair, stare at the maze map on your studio wall. This offer could be everything you need—or the beginning of something you no longer control."
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
