import 'package:Marketing_Fruit/components/entertainment_menu_drawer.dart';
import 'package:flutter/material.dart';
import 'package:Marketing_Fruit/screens/entertainment_arc/frame2345.dart';
import '../../components/next_button.dart';
import '../../components/player_details.dart';
import '../../components/text_bubble.dart';

class Frame2344b extends StatefulWidget {
  const Frame2344b({super.key});

  @override
  State<Frame2344b> createState() => _Frame2344bState();
}

class _Frame2344bState extends State<Frame2344b> {
  final List<String> messages = [
    "The collaboration had taken months of negotiation, legal reviews, and cultural decoding. But it was worth it. Partnering with a seasoned European production house unlocked co-financing, cross-border talent, and access to distribution networks that once seemed out of reach.",
    "Your team shifted gears. Writers blended Eastern narrative rhythms with Western pacing. Directors flew back and forth between Mumbai and Berlin. Every frame now carried international polish. Budgets doubled, but so did ambition. The resulting psychological drama was layered, multilingual, and targeted for simultaneous release across five regions.",
    "Critics from both sides of the globe previewed early cuts and raved about the production value. The press called it “the blueprint for modern transnational storytelling.” You secured pre-release distribution deals in three countries. Streaming platforms sent offers. Things had never looked better.Then—an unexpected turn.",
    "The European partner flagged an issue. One of the subplots bore resemblance to an indie short film released a few years ago in France. It hadn’t gone viral but was well-regarded in local circles. Worse, a junior French writer from their team admitted to drawing “creative inspiration” without informing anyone.",
    "The problem: your studio was listed as the primary producer in international agreements.Back home, legal exposure was minimal. But internationally? The French filmmakers threatened to block EU distribution unless credit and compensation were negotiated. Suddenly, your clean image was tangled in a co-creator’s mistake. The international press caught wind of the controversy.",
    "Boardroom discussions turned tense. Should you cut the segment? Push release without Europe? Shift liability to the partner? Or issue a joint statement, risking partial blame but showing unity?The irony was thick—your global leap forward had introduced global risk.",
    "And just like that, what started as a story of expansion had turned into a legal chess game. One move wrong, and the whole board could tip."
  ];

  int currentIndex = 0;
  final playerDetails = PlayerDetails();

  @override
  void initState() {
    super.initState();
    playerDetails.saveProgress('frame2344b', null);
  }

  void _handleNext() {
    setState(() {
      if (currentIndex < messages.length - 1) {
        currentIndex++;
        playerDetails.saveProgress('frame2344b', null);
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
