import 'package:Marketing_Fruit/components/entertainment_menu_drawer.dart';
import 'package:flutter/material.dart';
import 'package:Marketing_Fruit/screens/entertainment_arc/frame2345f.dart';
import '../../components/next_button.dart';
import '../../components/player_details.dart';
import '../../components/text_bubble.dart';

class Frame2345b extends StatefulWidget {
  const Frame2345b({super.key});

  @override
  State<Frame2345b> createState() => _Frame2345bState();
}

class _Frame2345bState extends State<Frame2345b> {
  final List<String> messages = [
    "You sat down with the rival studio’s lawyers behind closed doors. It was clear they wanted a payout, not a drawn-out court battle. After tense negotiations, a confidential agreement was signed: a substantial sum exchanged for limited usage rights and mutual silence. There was no official admission of fault—just business, plain and clean.",
    "Publicly, your statement was diplomatic. “Creative lines blur in storytelling. We move forward with respect.” Some fans raised eyebrows, but most moved on. Your team quietly resumed content promotion. Investors appreciated your pragmatism. The noise faded. The numbers recovered.",
    "It wasn’t a win, but it was a strategic retreat that protected the long game."
  ];

  int currentIndex = 0;
  final playerDetails = PlayerDetails();

  @override
  void initState() {
    super.initState();
    playerDetails.saveProgress('frame2345b', null);
  }

  void _handleNext() {
    setState(() {
      if (currentIndex < messages.length - 1) {
        currentIndex++;
        playerDetails.saveProgress('frame2345b', null);
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
