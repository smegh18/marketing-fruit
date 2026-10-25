import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:Marketing_Fruit/components/all_widgets.dart';
import 'package:Marketing_Fruit/components/player_details.dart';
import '../../components/next_button.dart';
import '../../components/text_bubble.dart';
import '../../components/entertainment_menu_drawer.dart';
import 'frame8.dart';

class Frame7 extends StatefulWidget {
  const Frame7({super.key});

  @override
  State<Frame7> createState() => _Frame7State();
}

class _Frame7State extends State<Frame7> {
  final playerDetails = PlayerDetails();

  final Color bubbleBackground = Color(0xFFDED08B).withOpacity(0.8);

  @override
  void initState() {
    super.initState();
    // Save progress when entering this frame
    playerDetails.saveProgress('frame7', null);
  }


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
              'assets/EA1.png',
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
              "First things first, we need to register your Entertainment & streaming company. Enter the name of your company",
            ),
          ),

          Positioned(
            bottom: isMobile ? screenHeight * 0.02 : screenHeight * 0.10,
            left: isMobile ? screenWidth * 0.23 : screenWidth * 0.5 - 200, // Center the button (200 width / 2)
            child: Padding(padding: isMobile ? EdgeInsets.symmetric(horizontal: MediaQuery.of(context).size.width * 0.1, vertical: MediaQuery.of(context).size.height * 0.1):EdgeInsets.all(0),
              child: AllWidgets.buildTextField(label: '', hint: "Enter your Company Name", controller: nameController,widthm: 0.4),
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
                      title: const Text("Empty Company Name"),
                      content: const Text("Please Enter your Company Name."),
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
                playerDetails.getCompanyName(nameController.text.toString());
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => Frame8(),
                  ),
                );
              },
            ),
          ),
          // Integrated Pill Drawer with Menu Button
          // Menu Drawer (expanded)
         EntertainmentMenuDrawer()
        ],
      ),
    );
  }
}
