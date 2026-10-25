import 'package:Marketing_Fruit/components/entertainment_menu_drawer.dart';
import 'package:flutter/material.dart';
import '../../components/next_button.dart';
import '../../components/player_details.dart';
import '../../components/text_bubble.dart';
import 'frame1.dart';

class Frame2345f extends StatefulWidget {
  const Frame2345f({super.key});

  @override
  State<Frame2345f> createState() => _Frame2345fState();
}

class _Frame2345fState extends State<Frame2345f> {
  final List<String> messages = [
    "The silence after the storm was almost eerie. Headlines faded. Lawyers stepped back. Your team, once caught in a whirlwind of claims, clauses, and crisis calls, began breathing a little easier.",
    "It wasn’t victory that you celebrated—it was survival.The affected content was either re-edited or credited appropriately. You made a quiet but public-facing gesture: a revised transparency policy, new ethical sourcing practices, and a team session on creative boundaries. Internally, this move didn’t just clear your name—it reinforced your culture.",
    "And the audience noticed.Viewership slowly returned. Subscriptions ticked up—not in spikes, but in confident, consistent steps. Your analytics team shared weekly reports: lower bounce rates, higher retention, longer watch durations. One flagship title—once caught in the legal fog—now found a second life through glowing word-of-mouth and niche influencer reviews.",
    "Partnerships resumed. Regional creators, once hesitant, now sent you pitches directly. You signed two content deals with emerging directors, both eager to collaborate with a studio that had “learned and adapted.”",
    "The second studio resumed its pipeline. Your AI models were retrained with refined datasets and stricter oversight. The international partnership, though scarred, held together—both sides choosing progress over blame.",
    "Revenue steadied. Customer loyalty crept upward. Operations ran leaner, wiser. You weren’t the same studio you were a year ago.You were better.",
    "And though expansion opportunities loomed once again, you now approached them with measured ambition—eyes open, lessons etched deep, and a quiet sense of gratitude for every line of code, every frame, and every viewer who stuck around.The business, once rattled, had found its rhythm again.",
    "Just when you thought everything is normal, a new instance was brewing on the other side of the world. It started like static—small, scattered noise in the distance.Your inbox had a few subject lines you barely noticed: “Novel coronavirus spreads in Wuhan”, “Flights rerouted due to outbreak.” Another health scare, you thought. Nothing that would cross oceans and shut sets.",
    "But then, things began to slip.One crew member backed out of a weekend shoot. A freelance editor asked to work from home. Your location permit got delayed—“just protocol,” they said. A minor hold. A safety measure. Nothing to panic about.",
    "Then came the flood.Vendors canceled deliveries. A critical sequence was postponed—your lead actress was stuck overseas. Your second studio suspended all activity after a technician fell sick. Half your projects hung mid-air, waiting for clarity that wouldn’t come.",
    "And just as you were piecing together a temporary plan, it hit.Nationwide lockdown.No shoots. No travel. No offices. No idea what this virus really was, or how long the freeze would last.All you knew was this: the lights had gone out on your entire industry.cc"
  ];

  int currentIndex = 0;
  final playerDetails = PlayerDetails();

  @override
  void initState() {
    super.initState();
    playerDetails.saveProgress('frame2345f', null);
  }

  void _handleNext() {
    setState(() {
      if (currentIndex < messages.length - 1) {
        currentIndex++;
        playerDetails.saveProgress('frame2345f', null);
      } else {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => Frame1()),
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
              'assets/EA19.png',
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
