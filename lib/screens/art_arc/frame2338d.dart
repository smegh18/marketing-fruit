import 'package:flutter/material.dart';
import 'package:Marketing_Fruit/screens/art_arc/frame2338f.dart';
import '../../components/next_button.dart';
import '../../components/text_bubble.dart';

class Frame2338d extends StatefulWidget {
  const Frame2338d({super.key});

  @override
  State<Frame2338d> createState() => _Frame2338dState();
}

class _Frame2338dState extends State<Frame2338d> {
  final List<String> messages = [
    "You decide to trust the work. No ads, no PR stunts. Just a signboard out front, a simple website, and a whisper in the wind. You do a few soft invites—friends, fellow artists, old colleagues. “Let them experience it. If it’s good, they’ll talk.”",
    "Opening day arrives. It’s quiet. A few curious faces peek in, unsure of what’s inside. Some stay. Some leave with thoughtful smiles. No lines. No clicks. But the feedback is glowing. People say it feels “pure.”",
    "It’s a slow burn, and you’re okay with that—for now. You feel calm, but also cautious. If momentum doesn’t build soon, your cash runway might run out before your story even gets off the ground."
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
