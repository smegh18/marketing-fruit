import 'package:flutter/material.dart';
import 'frame3.dart';
import '../../components/next_button.dart';
import '../../components/text_bubble.dart';

class Frame2 extends StatelessWidget {
  const Frame2({super.key});

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
            bottom: screenHeight * 0.18, // 23% from bottom
            left: screenWidth * 0.05,
            right: screenWidth * 0.05,
            child: TextBubble(
              message:
              "Are you ready to embark business journey of your life?",
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
                    builder: (context) => Frame3(),
                  ),
                );
              },
            ),
          ),


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
