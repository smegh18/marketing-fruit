import 'package:Marketing_Fruit/components/entertainment_menu_drawer.dart';
import 'package:flutter/material.dart';
import '../../components/next_button.dart';
import '../../components/player_details.dart';
import '../../components/text_bubble.dart';
import 'frame19c3.dart';

class Frame19c2 extends StatefulWidget {
  const Frame19c2({super.key});

  @override
  State<Frame19c2> createState() => _Frame19c2State();
}

class _Frame19c2State extends State<Frame19c2> {
  final playerDetails = PlayerDetails();


  @override
  void initState() {
    super.initState();
    // Save progress when entering this frame
    playerDetails.saveProgress('frame19c2', null);
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
              'assets/EA5.png',
              fit: BoxFit.cover,
            ),
          ),

          // Julian Kelly Cartoon - Responsive Position
          // Positioned(
          //   bottom: screenHeight * 0.07, // 8% from bottom
          //   left: screenWidth * 0.05, // Optional: slight left padding
          //   child: Image.asset(
          //     'assets/julian_kelly.png',
          //     height: screenHeight * 0.80, // 65% of screen height
          //   ),
          // ),

          // Text Bubble - Responsive Position and Width
          Positioned(
            bottom: screenHeight * 0.18, // 23% from bottom
            left: screenWidth * 0.05,
            right: screenWidth * 0.05,
            child: TextBubble(
              message:
              "The upload went live with careful strategy. Thumbnails were tested. Keywords researched. The trailer was posted across social media. Within 48 hours, views began trickling in. By the end of the week, a few thousand. Then tens of thousands. Comments poured in. Algorithms kicked in. Clips started trending. The content — bold, timely, emotional — resonated. It worked.",
            ),
          ),

          Positioned(
            bottom: screenSize.height * 0.05,
            right: screenSize.width * 0.05,
            child: NextButton(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => Frame19c3(),
                  ),
                );
              },
            ),
          ),
          EntertainmentMenuDrawer()
        ],
      ),
    );
  }
}
