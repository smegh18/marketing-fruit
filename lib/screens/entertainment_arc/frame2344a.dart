import 'package:Marketing_Fruit/components/entertainment_menu_drawer.dart';
import 'package:flutter/material.dart';
import 'package:Marketing_Fruit/screens/entertainment_arc/frame2345.dart';
import '../../components/next_button.dart';
import '../../components/player_details.dart';
import '../../components/text_bubble.dart';

class Frame2344a extends StatefulWidget {
  const Frame2344a({super.key});

  @override
  State<Frame2344a> createState() => _Frame2344aState();
}

class _Frame2344aState extends State<Frame2344a> {
  final List<String> messages = [
    "The ribbon-cutting ceremony of the second studio was a quiet, symbolic moment—a nod to how far the production house had come in just a few years.The new facility, located in a bustling mid-tier city, brought access to cheaper talent, tax incentives, and more space for parallel production cycles.Internally, the expansion was hailed as a strategic masterstroke.",
    "With dual teams now operating, production velocity soared. A new sci-fi web series had wrapped up faster than forecasted, with early edits revealing something special—slick pacing, a compelling hook, and visuals that looked twice the budget. The team was confident. The launch campaign was planned to perfection.",
    "But just days before release, a legal notice arrived.",
    "A rival studio claimed that your new series bore substantial resemblance to a title they’d released two years earlier—same genre, similar plot beats, and even overlapping character archetypes. To make matters worse, one of your new hires had previously interned on their project. The rival studio wasn't just accusing; they were preparing to sue.",
    "Your internal Slack channels flooded with concern. Editors scrambled to recheck creative drafts. The second studio, still settling into its rhythm, was rattled. Morale dipped. Investors called for updates. The marketing team hit pause, sponsors hesitated, and distributors pulled back—waiting for clarity.",
    "In just 48 hours, your expansion story turned into a potential PR and financial crisis.You stood at a crossroad—fight the claim, settle quietly, pull the content, or go on the offensive.Each move had its consequences, but one thing was clear: expansion brought not just opportunity, but visibility—and visibility brought scrutiny."
  ];

  int currentIndex = 0;
  final playerDetails = PlayerDetails();

  @override
  void initState() {
    super.initState();
    playerDetails.saveProgress('frame2344a', null);
  }

  void _handleNext() {
    setState(() {
      if (currentIndex < messages.length - 1) {
        currentIndex++;
        playerDetails.saveProgress('frame2344a',null);
      } else {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => Frame2345()),
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
