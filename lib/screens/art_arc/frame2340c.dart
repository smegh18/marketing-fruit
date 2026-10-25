import 'package:flutter/material.dart';
import 'package:Marketing_Fruit/screens/art_arc/frame2340.dart';
import '../../components/next_button.dart';
import '../../components/text_bubble.dart';

class Frame2340c extends StatefulWidget {
  const Frame2340c({super.key});

  @override
  State<Frame2340c> createState() => _Frame2340cState();
}

class _Frame2340cState extends State<Frame2340c> {
  final List<String> messages = [
    "The partnership with Tech startup changes everything.",
    "A team of developers joins your studio. One day it’s a prototype headset. The next, it’s motion-triggered light pulses. Your walls become dynamic. Your floors start reacting to footsteps. The maze isn’t just a space anymore—it’s alive.",
    "You test it at night—alone, headset on, notes in hand. As your virtual twin walks through a neon forest that responds to your breathing, you say aloud:“We’ve made a digital dream.”",
    "When you launch, it’s chaos—in the best way.Tech blogs pick it up. A vlogger calls it “Blade Runner for the brain.” Tickets sell out for two weeks straight. But tech support becomes your full-time job. Devices glitch. Kids drop controllers. And the app update deletes a section’s sound design.",
    "You’ve entered a new world—but now you’re not just an artist. You’re a system manager too."
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
              'assets/AA1.png',
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
