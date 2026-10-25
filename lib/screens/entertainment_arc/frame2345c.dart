import 'package:Marketing_Fruit/components/entertainment_menu_drawer.dart';
import 'package:flutter/material.dart';
import 'package:Marketing_Fruit/screens/entertainment_arc/frame2345f.dart';
import '../../components/next_button.dart';
import '../../components/player_details.dart';
import '../../components/text_bubble.dart';

class Frame2345c extends StatefulWidget {
  const Frame2345c({super.key});

  @override
  State<Frame2345c> createState() => _Frame2345cState();
}

class _Frame2345cState extends State<Frame2345c> {
  final List<String> messages = [
    "You watched the views climb, the comments pour in, the buzz swell—then you killed the feed. With a heavy heart, you announced that the series would be withdrawn due to a potential overlap with existing IP. Your statement emphasized values: “Originality matters, and we choose integrity over profit.”",
    "The decision split your audience. While some mourned the content, others respected the stand. Brand analysts noted a drop in revenue but a rise in trust. You shifted gears, fast-tracking a new project and even bringing in external creative consultants to ensure complete originality.",
    "You’d sacrificed a show, but built credibility that would pay off in the next cycle."
  ];

  int currentIndex = 0;
  final playerDetails = PlayerDetails();

  @override
  void initState() {
    super.initState();
    playerDetails.saveProgress('frame2345c', null);
  }

  void _handleNext() {
    setState(() {
      if (currentIndex < messages.length - 1) {
        currentIndex++;
        playerDetails.saveProgress('frame2345c', null);
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
