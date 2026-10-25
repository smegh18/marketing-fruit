import 'package:flutter/material.dart';
import 'package:Marketing_Fruit/screens/art_arc/frame12f.dart';
import '../../components/next_button.dart';
import '../../components/text_bubble.dart';

class Frame12a extends StatefulWidget {
  const Frame12a({super.key});

  @override
  State<Frame12a> createState() => _Frame12aState();
}

class _Frame12aState extends State<Frame12a> {
  final List<String> messages = [
    "You wanted to make a statement—something unforgettable for your studio’s launch. So you went all in with Surreal Dreams. Projection mapping, immersive sound design, reactive lighting—it transformed your space into a surreal, otherworldly experience. Giant blinking eyes, floating staircases made of light, and ambient sounds that made people feel like they were drifting through a dream.",
    "The buzz was immediate. Tickets sold out. Social media lit up with videos and rave reviews. But now you're staring at your budget, realizing the tech and setup costs ate through your launch capital fast. You’re at a crossroads: do you scale back future installations to preserve cash flow, or chase sponsorships and partnerships to maintain this ambitious vision?"
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
