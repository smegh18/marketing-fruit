import 'package:flutter/material.dart';
import 'package:Marketing_Fruit/screens/art_arc/frame12f.dart';
import '../../components/next_button.dart';
import '../../components/text_bubble.dart';

class Frame12d extends StatefulWidget {
  const Frame12d({super.key});

  @override
  State<Frame12d> createState() => _Frame12dState();
}

class _Frame12dState extends State<Frame12d> {
  final List<String> messages = [
    "You went bold. Abstract forms, oversized pop-art installations, glowing neon signs with meme quotes, and a giant QR code wall that linked to curated internet chaos. It was loud, weird, and made to be shared. And it worked. The maze went viral among younger crowds. TikTok clips blew up. People lined up just to snap a selfie under the 'Cereal of the Void'sculpture.",
    "Your merch table sold out in hours. But not everyone was impressed. Critics called it shallow. Some older patrons walked out shaking their heads. Now you’re faced with a decision: capitalize on the hype and build a brand around this style—or evolve before the buzz fades."
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
