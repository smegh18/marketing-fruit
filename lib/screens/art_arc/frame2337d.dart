import 'package:flutter/material.dart';
import 'package:Marketing_Fruit/screens/art_arc/frame2337f.dart';
import '../../components/next_button.dart';
import '../../components/text_bubble.dart';

class Frame2337d extends StatefulWidget {
  const Frame2337d({super.key});

  @override
  State<Frame2337d> createState() => _Frame2337dState();
}

class _Frame2337dState extends State<Frame2337d> {
  final List<String> messages = [
    "You broke it down: general entry at a base price, with special sections available for a little extra. “Let them choose how deep they want to go,” you figured. At first, visitors are intrigued. Some go straight for the full experience, others just explore the free zones.",
    "You’ve created a layered flow—casual visitors drift through the public zones, while more curious guests linger, swipe cards, and unlock hidden rooms or interactive pieces. But it’s not all smooth. Some guests get confused. Others grumble about being “nickel and dimed.”",
    "You wonder: is this clever customization—or just a friction-filled funnel?"
  ];

  int currentIndex = 0;

  void _handleNext() {
    setState(() {
      if (currentIndex < messages.length - 1) {
        currentIndex++;
      } else {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => Frame2337f()),
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
              'assets/AA3.png',
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
