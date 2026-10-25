import 'package:flutter/material.dart';
import 'package:Marketing_Fruit/screens/art_arc/frame2340.dart';
import '../../components/next_button.dart';
import '../../components/text_bubble.dart';

class Frame2340b extends StatefulWidget {
  const Frame2340b({super.key});

  @override
  State<Frame2340b> createState() => _Frame2340bState();
}

class _Frame2340bState extends State<Frame2340b> {
  final List<String> messages = [
    "You re-read the brand offer once more. Then delete it.Instead, you send out a heartfelt newsletter to your mailing list:",
    "“This space is yours—not for sale. Instead, we’re building the next maze with you.”You launch a crowdfunding campaign. You host a local fundraiser with live performances. Former visitors chip in with small donations and even volunteer time.",
    "You keep your budget lean. You redesign using found materials and hand-painted banners. The tech is minimal—but the soul is intact.Opening night is smaller . No PR , no press kits.",
    "But it’s real.A woman places her hand on a mural and whispers, “This reminds me of my childhood home.” A boy asks if he can help you paint next time. Someone starts clapping after the final room.You realize—this isn’t a product. It’s a movement."
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
