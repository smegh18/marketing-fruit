import 'package:flutter/material.dart';
import 'package:Marketing_Fruit/screens/art_arc/frame2337f.dart';
import '../../components/next_button.dart';
import '../../components/text_bubble.dart';

class Frame2337b extends StatefulWidget {
  const Frame2337b({super.key});

  @override
  State<Frame2337b> createState() => _Frame2337bState();
}

class _Frame2337bState extends State<Frame2337b> {
  final List<String> messages = [
    "You kept it simple: low pricing, wide access. “Let them come in first, then decide if it’s worth more.” The ticket sign reads like a casual invite. Families come in with kids. College students pay in loose change. The space fills up fast—sometimes too fast.",
    "You’re excited by the energy. Social media tags are climbing. But now you’re noticing wear and tear—literally. Some installations need more maintenance than expected. And while the footfall is great, you find yourself calculating whether volume alone will cover your costs. The buzz is real—but so is the strain.",
    "You start to think: is this sustainable, or just a rush?"
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
