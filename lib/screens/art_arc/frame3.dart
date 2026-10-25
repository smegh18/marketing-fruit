import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:Marketing_Fruit/components/all_widgets.dart';
import 'package:Marketing_Fruit/components/player_details.dart';
import '../../components/next_button.dart';
import '../../components/text_bubble.dart';
import 'frame4.dart';

class Frame3 extends StatelessWidget {
  const Frame3({super.key});

  @override
  Widget build(BuildContext context) {
    final isMobile = !kIsWeb && (Platform.isAndroid || Platform.isIOS);
    final TextEditingController nameController = TextEditingController();
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
              "Okay, To start, I will need your name.",
            ),
          ),

          Positioned(
            bottom: isMobile ? screenHeight * 0.02 : screenHeight * 0.10,
            left: isMobile ? screenWidth * 0.23 : screenWidth * 0.5 - 200, // Center the button (200 width / 2)
            child: Padding(padding: isMobile ? EdgeInsets.symmetric(horizontal: MediaQuery.of(context).size.width * 0.1, vertical: MediaQuery.of(context).size.height * 0.1):EdgeInsets.all(0),
              child: AllWidgets.buildTextField(label: '', hint: "Enter your Name", controller: nameController,widthm: 0.4),
            ),
            ),


          Positioned(
            bottom: screenSize.height * 0.05,
            right: screenSize.width * 0.05,
            child: NextButton(
              onTap: () {
                if(nameController.text.toString().isEmpty){
                  showDialog(
                    context: context,
                    builder: (context) => AlertDialog(
                      title: const Text("Empty Name"),
                      content: const Text("Please Enter your Name."),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(context),
                          child: const Text("OK"),
                        ),
                      ],
                    ),
                  );
                  return;
                }
                playerDetails.getName(nameController.text.toString());
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => Frame4(),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
