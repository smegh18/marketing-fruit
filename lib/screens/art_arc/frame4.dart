import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:Marketing_Fruit/components/player_details.dart';
import 'frame5.dart';
import '../../components/answer_bubble.dart';
import '../../components/text_bubble.dart';

class Frame4 extends StatelessWidget {
  const Frame4({super.key});

  @override
  Widget build(BuildContext context) {
    final isMobile = !kIsWeb && (Platform.isAndroid || Platform.isIOS);
    final screenSize = MediaQuery.of(context).size;
    final screenHeight = screenSize.height;
    final screenWidth = screenSize.width;
    final playerDetails = PlayerDetails();

    return Scaffold(
      body: Stack(
        children: [
          // Background Image
          SizedBox.expand(
            child: Image.asset(
              'assets/AA1.png',
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
            bottom: isMobile ? screenHeight * 0.26 : screenHeight * 0.2, // 23% from bottom
            left: screenWidth * 0.05,
            right: screenWidth * 0.05,
            child: TextBubble(
              message:
              "Choose Your Gender",
            ),
          ),


          Positioned(
              bottom: screenHeight * 0.07,
              left: screenWidth * 0.10 , // Center the button (200 width / 2)
              child: Row(
                spacing: screenWidth * 0.10,
                children: [
                  AnswerBubble(
                    label: 'Male',
                    onTap: () {
                      playerDetails.getSex('Male');
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => Frame5(),
                        ),
                      );
                    },
                  ),
                  AnswerBubble(
                    label: 'Female',
                    onTap: () {
                      playerDetails.getSex('Female');
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => Frame5(),
                        ),
                      );
                    },
                  ),
                  AnswerBubble(
                    label: 'Not to disclose',
                    onTap: () {
                      playerDetails.getSex('NA');
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => Frame5(),
                        ),
                      );
                    },
                  ),
                ],
              )),

          // Row(
          //   children: [
          //     Positioned(
          //       bottom: screenHeight * 0.05,
          //       left: screenWidth * 0.5 - 200, // Center the button (200 width / 2)
          //       child: AnswerBubble(
          //         label: 'Male',
          //         onTap: () {
          //           Navigator.push(
          //             context,
          //             MaterialPageRoute(
          //               builder: (context) => Frame1(),
          //             ),
          //           );
          //         },
          //       ),
          //     ),
              // Positioned(
              //   bottom: screenHeight * 0.05,
              //   left: screenWidth * 0.5 - 200, // Center the button (200 width / 2)
              //   child: AnswerBubble(
              //     label: 'Female',
              //     onTap: () {
              //       Navigator.push(
              //         context,
              //         MaterialPageRoute(
              //           builder: (context) => Frame1(),
              //         ),
              //       );
              //     },
              //   ),
              // ),
              // Positioned(
              //   bottom: screenHeight * 0.05,
              //   left: screenWidth * 0.5 - 100, // Center the button (200 width / 2)
              //   child: AnswerBubble(
              //     label: 'Not to disclose',
              //     onTap: () {
              //       Navigator.push(
              //         context,
              //         MaterialPageRoute(
              //           builder: (context) => Frame1(),
              //         ),
              //       );
              //     },
              //   ),
              // )
          //   ],
          // )


          // Positioned(
          //   bottom: screenSize.height * 0.05,
          //   right: screenSize.width * 0.05,
          //   child: GestureDetector(
          //     onTap: () {
          //       Navigator.push(
          //         context,
          //         MaterialPageRoute(
          //           builder: (context) => Frame2(),
          //         ),
          //       );
          //     },
          //     child: Image.asset(
          //       'assets/next_Button.png', // Make sure this matches the file name
          //       height: screenSize.height * 0.08,
          //     ),
          //   ),
          // ),
        ],
      ),
    );
  }
}
