import 'dart:io';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:Marketing_Fruit/components/player_details.dart';
import 'package:Marketing_Fruit/screens/entertainment_arc/frame54.dart';
import '../../components/answer_bubble.dart';
import '../../components/text_bubble.dart';
import '../../components/entertainment_menu_drawer.dart';

class Frame53 extends StatefulWidget {
  const Frame53({super.key});

  @override
  State<Frame53> createState() => _Frame53State();
}

class _Frame53State extends State<Frame53> {
  final playerDetails = PlayerDetails();

  @override
  void initState() {
    super.initState();
    // Save progress when entering this frame
    playerDetails.saveProgress('frame53', null);
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
              'assets/EA6.png',
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
              "Good choice, selecting Documentaries and investigative journalism. What is the major factor that makes you focus on Documentaries & Investigative Journalism?",
            ),
          ),

          Positioned(
            bottom: screenHeight * 0.07,
            left: screenWidth * 0.25,
            child: Column(
              children: [
                Row(
                  children: [
                    AnswerBubble(
                      label: 'Rising Global Demand for \n real and impactful content',
                      onTap: () async {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => Frame54(background: 'assets/EA6.png'),
                          ),
                        );
                      },
                    ),
                    SizedBox(width: screenWidth * 0.10),
                    AnswerBubble(
                      label: 'Low Production Costs,\nHigh ROI',
                      onTap: () async {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => Frame54(background: 'assets/EA6.png'),
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
                      label: 'Evergreen & Shareable \n Content',
                      onTap: () async {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => Frame54(background: 'assets/EA6.png'),
                          ),
                        );
                      },
                    ),
                    SizedBox(width: screenWidth * 0.10),
                    AnswerBubble(
                      label: 'Multiple Distribution \n Channels',
                      onTap: () async {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => Frame54(background: 'assets/EA6.png'),
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
