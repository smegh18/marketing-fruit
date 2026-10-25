import 'package:flutter/material.dart';
import 'package:Marketing_Fruit/screens/art_arc/frame2337f.dart';
import '../../components/next_button.dart';
import '../../components/text_bubble.dart';

class Frame2337a extends StatefulWidget {
  const Frame2337a({super.key});

  @override
  State<Frame2337a> createState() => _Frame2337aState();
}

class _Frame2337aState extends State<Frame2337a> {
  final List<String> messages = [
    "You decided to go all-in—premium pricing to match a premium experience. The signage is elegant, the tone clear: this isn’t just a gallery, it’s a curated journey. Your team tweaks the lighting and sound one last time to make sure everything feels elevated from the first step.",
    "The first few visitors hesitate at the ticket counter, but those who enter leave with wide eyes and long videos posted online. One even whispers, “This feels like a secret museum.” You're not seeing huge crowds—but you are seeing appreciation, engagement, and the kind of buzz that attracts press, not just traffic.",
    "Still, a part of you wonders—will the exclusivity pay off long-term, or are you pricing out the community you're trying to reach?"
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
