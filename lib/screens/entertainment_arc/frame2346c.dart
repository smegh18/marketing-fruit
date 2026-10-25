import 'package:Marketing_Fruit/components/entertainment_menu_drawer.dart';
import 'package:flutter/material.dart';
import 'package:Marketing_Fruit/screens/entertainment_arc/frame2345f.dart';
import '../../components/next_button.dart';
import '../../components/player_details.dart';
import '../../components/text_bubble.dart';

class Frame2346c extends StatefulWidget {
  const Frame2346c({super.key});

  @override
  State<Frame2346c> createState() => _Frame2346cState();
}

class _Frame2346cState extends State<Frame2346c> {
  final List<String> messages = [
    "You closed the shutters—literally and figuratively. Every project was paused, every cost line scrutinized. A lean crew stayed on for maintenance, but most were furloughed. Your newsletter issued a heartfelt message. “We’ll be back soon. Stay safe.”",
    "It was quiet.Your balance sheet stabilized. You avoided bleeding money, but the silence came at a cost. Your audience wandered. Competitors stayed visible. The momentum you'd spent years building... slipped.",
    "When lockdowns eventually lifted, you returned to a market that had already moved on.",
    "You have paused the production. The operational cost has gone down, but still we are no where near making any profits. On the contrary the the losses are pilling up.",
    "You see your competitors, and they have moved to other verticals like animation, short form content, and finding some way to survive in this tough times.",
    "It seems that COVID-19 is not going anywhere, and we need to think some new ways to monitize, instead of waiting. But we are too late to start any kind of content creation right now.",
    "The market is flooded with newbie creators who have started their production from home and are selling to the agencies at rock bottom prices. We cannot compete with them if we start the production now.",
    "Instead, lets acquire one of their production, rebrand it to our business and market it. This way, the lag of our production time will be eliminated, and we will be back in the game.",
    "Explore marketplace"
  ];

  int currentIndex = 0;
  final playerDetails = PlayerDetails();

  @override
  void initState() {
    super.initState();
    playerDetails.saveProgress('frame2346c', null);
  }

  void _handleNext() {
    setState(() {
      if (currentIndex < messages.length - 1) {
        currentIndex++;
        playerDetails.saveProgress('frame2346c', null);
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
