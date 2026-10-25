import 'package:flutter/material.dart';
import 'package:Marketing_Fruit/screens/art_arc/frame2338f.dart';
import '../../components/next_button.dart';
import '../../components/text_bubble.dart';

class Frame2338b extends StatefulWidget {
  const Frame2338b({super.key});

  @override
  State<Frame2338b> createState() => _Frame2338bState();
}

class _Frame2338bState extends State<Frame2338b> {
  final List<String> messages = [
    "You fire up the ad dashboard. Facebook, Instagram, Google—your targeting is sharp: young professionals, tourists, art lovers, families. You set a modest budget but run smart A/B tests with bold visuals from your theme.",
    "Within days, traffic to your website triples. Ticket pre-bookings begin trickling in. People start mentioning you in community Facebook groups and neighborhood WhatsApp chats. You even overhear someone at a café say, “Oh, that art maze thing? Yeah, I saw an ad.”",
    "The buzz isn’t explosive, but it’s consistent. Your grand opening night sees a well-paced turnout—curious minds, clicking cameras, and honest questions. It’s not a frenzy, but it’s the start of something solid. You're now thinking: should I reinvest profits into retargeting, or focus on in-person loyalty?"
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
