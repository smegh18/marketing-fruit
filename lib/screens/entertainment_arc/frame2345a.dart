import 'package:Marketing_Fruit/components/entertainment_menu_drawer.dart';
import 'package:flutter/material.dart';
import '../../components/next_button.dart';
import '../../components/player_details.dart';
import '../../components/text_bubble.dart';
import 'frame2345f.dart';

class Frame2345a extends StatefulWidget {
  const Frame2345a({super.key});

  @override
  State<Frame2345a> createState() => _Frame2345aState();
}

class _Frame2345aState extends State<Frame2345a> {
  final List<String> messages = [
    "The office lights burned long into the night. Legal teams assembled in glass conference rooms, pouring over scripts, production notes, emails—anything that proved your content was original. The lawsuit became a talking point in industry circles, and while the headlines weren’t always kind, a growing faction of indie creators silently rooted for you. The court proceedings stretched over months, eating into your reserves.",
    "But then came the ruling.",
    "A judge sided with you, declaring there were no substantial similarities beyond generic themes. The ruling not only restored your credibility—it elevated it. Overnight, platforms that had paused deals resumed talks. Streaming blogs dubbed you “the indie underdog who stood tall.”",
    "You paid a steep price in time and money, but what you earned was worth more—industry respect and brand resilience."
  ];

  int currentIndex = 0;
  final playerDetails = PlayerDetails();

  @override
  void initState() {
    super.initState();
    playerDetails.saveProgress('frame2345a', null);
  }

  void _handleNext() {
    setState(() {
      if (currentIndex < messages.length - 1) {
        currentIndex++;
        playerDetails.saveProgress('frame2345a', null);
      } else {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => Frame2345f()),
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
          SizedBox.expand(
            child: Image.asset(
              'assets/EA14.png',
              fit: BoxFit.cover,
            ),
          ),
          Positioned(
            bottom: screenHeight * 0.18,
            left: screenWidth * 0.05,
            right: screenWidth * 0.05,
            child: TextBubble(
              message: messages[currentIndex],
            ),
          ),
          Positioned(
            bottom: screenSize.height * 0.05,
            right: screenSize.width * 0.05,
            child: NextButton(
              onTap: _handleNext,
            ),
          ),
          EntertainmentMenuDrawer()
        ],
      ),
    );
  }
}
