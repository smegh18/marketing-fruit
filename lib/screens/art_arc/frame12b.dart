import 'package:flutter/material.dart';
import 'package:Marketing_Fruit/screens/art_arc/frame12f.dart';
import '../../components/next_button.dart';
import '../../components/text_bubble.dart';

class Frame12b extends StatefulWidget {
  const Frame12b({super.key});

  @override
  State<Frame12b> createState() => _Frame12bState();
}

class _Frame12bState extends State<Frame12b> {
  final List<String> messages = [
    "You decided to keep things grounded. Instead of going big, you opened your maze with a local artist showcase. The setup was simple—no fancy tech, just honest creativity. Abstract murals, found-object sculptures, and raw expression filled the space. The crowd that came through wasn’t influencers—it was the community. Teachers, neighbors, families. It felt genuine.",
    "The event didn’t make waves online, but it built something else: trust and goodwill. Local schools asked about partnerships. Community boards want to list your studio in their directories. Still, part of you wonders—can this model sustain your business, or do you need something with broader appeal and higher margins?"
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
