import 'package:Marketing_Fruit/screens/entertainment_arc/frame11.dart';
import 'package:flutter/material.dart';
import '../../components/next_button.dart';
import '../../components/player_details.dart';
import '../../components/text_bubble.dart';
import '../../components/entertainment_menu_drawer.dart';
import 'frame54a0_2.dart';

class Frame54a0_1 extends StatefulWidget {
  const Frame54a0_1({super.key});

  @override
  State<Frame54a0_1> createState() => _Frame54a0_1State();
}

class _Frame54a0_1State extends State<Frame54a0_1> {
  final playerDetails = PlayerDetails();

  @override
  void initState() {
    super.initState();
    // Save progress when entering this frame
    playerDetails.saveProgress('frame54a0_1', null);
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
              'assets/EA10.png',
              fit: BoxFit.cover,
            ),
          ),

          // Julian Kelly Cartoon - Responsive Position
          Positioned(
            bottom: screenHeight * 0.07, // 8% from bottom
            left: screenWidth * 0.05, // Optional: slight left padding
            child: Image.asset(
              'assets/explaining.gif',
              height: screenHeight * 0.80, // 65% of screen height
            ),
          ),

          Positioned(
            bottom: screenHeight * 0.55,
            left: screenWidth * 0.35,
            child: MessageBubbleWithImage(
              imageAsset: 'assets/messagebubble.png',
              text: "Hey there, hope the previous content was helpful to you, but here is one more blog where you will know how to make sure people read your blogs Go to the podcast (EP7, why someone will read my blog)",
              textStyle: const TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.black,
                fontSize: 18,
              ),
              maxWidth: screenWidth * 0.3, // You can adjust maxWidth
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
            ),
          ),

          // Text Bubble - Responsive Position and Width
          Positioned(
            bottom: screenHeight * 0.18, // 23% from bottom
            left: screenWidth * 0.05,
            right: screenWidth * 0.05,
            child: TextBubble(
              message:
              "Ok, so you decided to go to with movies, but before securing funding, we need to finalise some things like movie name, genre and  script",
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
                    builder: (context) => MovieScriptEditorScreen(),
                  ),
                );
              },
            ),
          ),

          // Entertainment Menu Drawer
          const EntertainmentMenuDrawer(),
        ],
      ),
    );
  }
}
