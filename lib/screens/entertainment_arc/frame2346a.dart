import 'package:Marketing_Fruit/components/entertainment_menu_drawer.dart';
import 'package:flutter/material.dart';
import 'package:Marketing_Fruit/screens/entertainment_arc/frame2345f.dart';
import '../../components/next_button.dart';
import '../../components/player_details.dart';
import '../../components/text_bubble.dart';

class Frame2346a extends StatefulWidget {
  const Frame2346a({super.key});

  @override
  State<Frame2346a> createState() => _Frame2346aState();
}

class _Frame2346aState extends State<Frame2346a> {
  final List<String> messages = [
    "It wasn’t the path you imagined—replacing camera rigs and on-set chaos with green screens, render farms, and Zoom storyboarding—but it was the only one that made sense.",
    "Your team regrouped digitally. Voice actors recorded from makeshift home booths, animators shared files across time zones, and AI tools filled the gaps in production continuity. The process was clunky at first, slower than live shoots, but the results surprised even your harshest critics.",
    "Your animated sci-fi miniseries—built entirely in lockdown—quietly became a sleeper hit. Not explosive, but consistent. It kept subscribers engaged, the brand alive, and most importantly, proved you could adapt.",
    "You didn’t grow, but you didn’t fall apart either."
  ];

  int currentIndex = 0;
  final playerDetails = PlayerDetails();

  @override
  void initState() {
    super.initState();
    playerDetails.saveProgress('frame2346a', null);
  }

  void _handleNext() {
    setState(() {
      if (currentIndex < messages.length - 1) {
        currentIndex++;
        playerDetails.saveProgress('frame2346a', null);
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
