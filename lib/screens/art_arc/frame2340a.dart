import 'package:flutter/material.dart';
import 'package:Marketing_Fruit/screens/art_arc/frame2340.dart';
import '../../components/next_button.dart';
import '../../components/text_bubble.dart';

class Frame2340a extends StatefulWidget {
  const Frame2340a({super.key});

  @override
  State<Frame2340a> createState() => _Frame2340aState();
}

class _Frame2340aState extends State<Frame2340a> {
  final List<String> messages = [
    "You sign the contract with a mix of excitement and hesitation.Two weeks later, the transformation begins.",
    "Technicians arrive. Banners roll out. New lights, digital kiosks, and interactive signage are installed—all bearing the name of company. The maze entrance is now lined with LED panels. There’s a demo booth where visitors can try comapny’s latest VR glasses before entering. The projectors you once rented are replaced with top-tier equipment overnight.",
    "The crowds surge. Influencers post unboxing-style walkthroughs. “Powered by LuxoTech” starts trending. Your revenue graph spikes.But something else spikes too—your inbox.“I miss the raw feel of the first launch.” “Loved it... but it felt a bit too commercial.” One review reads: “Great art, but too many logos.”",
    "You sit in the back office after a long day, holding your old prototype sketch—the one you made with markers and tape. You wonder: was this a win, or just a pivot?"
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
