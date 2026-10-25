import 'package:flutter/material.dart';
import 'package:Marketing_Fruit/screens/art_arc/frame2338f.dart';
import '../../components/next_button.dart';
import '../../components/text_bubble.dart';

class Frame2338a extends StatefulWidget {
  const Frame2338a({super.key});

  @override
  State<Frame2338a> createState() => _Frame2338aState();
}

class _Frame2338aState extends State<Frame2338a> {
  final List<String> messages = [
    "You scroll through your inbox, then pause on a DM from a local influencer with a huge following in the city’s creative scene. Their aesthetic is loud, dramatic, and trendy—exactly the kind of energy your theme oozes. You reach out, propose a private walkthrough before the opening, and in return, they post exclusive reels and behind-the-scenes content.",
    "Within 48 hours, your notifications explode. “Where is this?!” “Tagging my crew!” Pre-sales spike. The good news? People are excited. The challenge? They’re coming with expectations built around hype.",
    "Your opening night turns into a scene—selfies, reels, flashes—and your art becomes a backdrop for content. The energy is electric, but you're already thinking about your next move: how do you keep them coming back, not just clicking “like”?"
  ];

  int currentIndex = 0;

  void _handleNext() {
    setState(() {
      if (currentIndex < messages.length - 1) {
        currentIndex++;
      } else {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => Frame2338f()),
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
