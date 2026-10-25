import 'package:flutter/material.dart';
import 'package:Marketing_Fruit/screens/art_arc/frame2338.dart';
import '../../components/next_button.dart';
import '../../components/text_bubble.dart';

class Frame2337f extends StatefulWidget {
  const Frame2337f({super.key});

  @override
  State<Frame2337f> createState() => _Frame2337fState();
}

class _Frame2337fState extends State<Frame2337f> {
  final List<String> messages = [
    "Now that the pricing is finalised, it is time for grand opening and move this whole business into motion to make it big.",
  ];

  int currentIndex = 0;

  void _handleNext() {
    setState(() {
      if (currentIndex < messages.length - 1) {
        currentIndex++;
      } else {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => Frame2338()),
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
