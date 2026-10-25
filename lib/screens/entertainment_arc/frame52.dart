import 'dart:io';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:Marketing_Fruit/components/player_details.dart';
import 'package:Marketing_Fruit/screens/entertainment_arc/frame54.dart';
import '../../components/answer_bubble.dart';
import '../../components/text_bubble.dart';
import '../../components/entertainment_menu_drawer.dart';

class Frame52 extends StatefulWidget {
  const Frame52({super.key});

  @override
  State<Frame52> createState() => _Frame52State();
}

class _Frame52State extends State<Frame52> {
  final playerDetails = PlayerDetails();

  @override
  void initState() {
    super.initState();
    // Save progress when entering this frame
    playerDetails.saveProgress('frame52', null);
  }

  @override
  Widget build(BuildContext context) {
    final isMobile = !kIsWeb && (Platform.isAndroid || Platform.isIOS);
    final screenSize = MediaQuery.of(context).size;
    final screenHeight = screenSize.height;
    final screenWidth = screenSize.width;
    final userId = FirebaseAuth.instance.currentUser!.uid;

    return Scaffold(
      body: Stack(
        children: [
          // Background Image
          SizedBox.expand(
            child: Image.asset(
              'assets/EA3.png',
              fit: BoxFit.cover,
            ),
          ),

          // Julian Kelly Cartoon - Responsive Position (commented as in original)
          // Positioned(
          //   bottom: screenHeight * 0.07,
          //   left: screenWidth * 0.05,
          //   child: Image.asset(
          //     'assets/julian_kelly.png',
          //     height: screenHeight * 0.80,
          //   ),
          // ),

          // Text Bubble - Responsive Position and Width
          Positioned(
            bottom: isMobile ? screenHeight * 0.45 : screenHeight * 0.38, // 23% from bottom
            left: screenWidth * 0.05,
            right: screenWidth * 0.05,
            child: TextBubble(
              message:
              "Good choice, selecting Web series for streaming platforms. What is the major factor that makes you focus on Web series?",
            ),
          ),

          Positioned(
            bottom: screenHeight * 0.07,
            left: screenWidth * 0.25,
            child: Column(
              // spacing and row spacing are controlled within Rows
              children: [
                Row(
                  children: [
                    AnswerBubble(
                      label: 'Consistent Viewer\n Engagement',
                      onTap: () async {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => Frame54(background: 'assets/EA4.png'),
                          ),
                        );
                      },
                    ),
                    SizedBox(width: screenWidth * 0.10),
                    AnswerBubble(
                      label: 'Scalable IP &\nFranchise Potential',
                      onTap: () async {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => Frame54(background: 'assets/EA4.png'),
                          ),
                        );
                      },
                    ),
                  ],
                ),
                SizedBox(height: isMobile ? screenWidth * 0.01 : screenWidth * 0.03),
                Row(
                  children: [
                    AnswerBubble(
                      label: 'Faster Production,\nLower Risk',
                      onTap: () async {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => Frame54(background: 'assets/EA4.png'),
                          ),
                        );
                      },
                    ),
                    SizedBox(width: screenWidth * 0.10),
                    AnswerBubble(
                      label: 'High Demand from\nStreaming Platforms',
                      onTap: () async {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => Frame54(background: 'assets/EA4.png'),
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Entertainment Menu Drawer
          const EntertainmentMenuDrawer(),
        ],
      ),
    );
  }
}
