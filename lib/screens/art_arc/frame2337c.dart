import 'package:flutter/material.dart';
import 'package:Marketing_Fruit/screens/art_arc/frame2337f.dart';
import '../../components/next_button.dart';
import '../../components/text_bubble.dart';

class Frame2337c extends StatefulWidget {
  const Frame2337c({super.key});

  @override
  State<Frame2337c> createState() => _Frame2337cState();
}

class _Frame2337cState extends State<Frame2337c> {
  final List<String> messages = [
    "You chose balance. Not too high, not too low. Just enough to say “this is valuable” without scaring people away. The reaction is steady—people pay, they enjoy, and many say they’ll bring a friend next time.",
    "No wild swings, no dramatic lines, but no big complaints either. Your accounting sheet is clean, the reviews are warm, and the vibe inside feels... comfortable.",
    "Still, a little voice in your head wonders—have you played it too safe? With so many other experiences fighting for attention, will comfort be enough to make your studio stand out?" 
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
