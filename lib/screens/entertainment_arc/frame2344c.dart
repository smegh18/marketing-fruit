import 'package:Marketing_Fruit/components/entertainment_menu_drawer.dart';
import 'package:flutter/material.dart';
import 'package:Marketing_Fruit/screens/entertainment_arc/frame2345.dart';
import '../../components/next_button.dart';
import '../../components/player_details.dart';
import '../../components/text_bubble.dart';

class Frame2344c extends StatefulWidget {
  const Frame2344c({super.key});

  @override
  State<Frame2344c> createState() => _Frame2344cState();
}

class _Frame2344cState extends State<Frame2344c> {
  final List<String> messages = [
    "The production house transitioned rapidly. Scripts were now pre-drafted by language models trained on thousands of hours of genre-specific content. AI tools storyboarded scenes, generated rough visual edits, and even handled early-stage animation. Operational costs dropped by nearly 20%. Turnaround time was slashed in half. You didn’t need more people—you needed smarter systems.",
    "The flagship project born from this new AI-first pipeline was an animated thriller series—tight, eerie, and eerily relevant. Early test audiences responded well. Some even compared its thematic structure to mainstream classics.",
    "The marketing strategy played up the novelty: “A show born from machine creativity.” Tech blogs ate it up. Investors doubled down. You were no longer just a production house—you were now a tech-enabled media disruptor.",
    "And then the email arrived.A major studio alleged that your series had scenes and narrative arcs suspiciously close to one of their past works. They suggested that your AI might have inhaled copyrighted patterns from public data, leading to unintentional plagiarism. What made it more complex—your AI training data sources were vague, a combination of open datasets and purchased libraries, some of which lacked clear provenance.",
    "Suddenly, the tech that gave you a leap now became a liability.Critics raised questions: Was this truly original content, or derivative work masked by code? Legal advisors urged caution. Platform partners paused release. Brand trust, once your hallmark, now hung in the balance.",
    "The story had shifted again.The AI had worked—until it worked too well.Now the decision wasn’t about scaling or innovating. It was about survival: Do you defend your creation? Rework the content? Disclose your AI methods fully? Or quietly absorb the blow and reconfigure your process?Because in this brave new world, originality wasn’t just about ideas—it was about data."
  ];

  int currentIndex = 0;
  final playerDetails = PlayerDetails();

  @override
  void initState() {
    super.initState();
    playerDetails.saveProgress('frame2344c', null);
  }

  void _handleNext() {
    setState(() {
      if (currentIndex < messages.length - 1) {
        currentIndex++;
        playerDetails.saveProgress('frame2344c', null);
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
              'assets/EA15.png',
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
