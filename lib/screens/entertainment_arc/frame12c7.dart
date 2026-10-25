import 'package:flutter/material.dart';
import 'package:Marketing_Fruit/components/player_details.dart';
import 'package:Marketing_Fruit/screens/entertainment_arc/frame54.dart';
import '../../components/answer_bubble.dart';
import '../../components/text_bubble.dart';
import '../../components/entertainment_menu_drawer.dart';
import 'frame12.dart';

class Frame12c7 extends StatefulWidget {
  const Frame12c7({super.key});

  @override
  State<Frame12c7> createState() => _Frame12c7State();
}

class _Frame12c7State extends State<Frame12c7> {
  final playerDetails = PlayerDetails();

  @override
  void initState() {
    super.initState();
    // Save progress when entering this frame
    playerDetails.saveProgress('frame12c7', null);
  }

  @override
  Widget build(BuildContext context) {
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
            bottom: screenHeight * 0.26, // 23% from bottom
            left: screenWidth * 0.05,
            right: screenWidth * 0.05,
            child: TextBubble(
              message:
              "Knowing all the risks and rewards, what is your final call",
            ),
          ),


          Positioned(
              bottom: screenHeight * 0.07,
              left: screenWidth * 0.25 , // Center the button (200 width / 2)
              child: Row(
                spacing: screenWidth * 0.08,
                children: [
                  AnswerBubble(
                    label: 'Let\'s Go \n and Start.',
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => Frame54(background: 'assets/EA5.png',),
                        ),
                      );
                    },
                  ),
                  AnswerBubble(
                    label: 'Rethink Decision on\nselecting type of content',
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => Frame12(),
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

          // Menu Drawer
          const EntertainmentMenuDrawer(),
        ],
      ),
    );
  }
}
