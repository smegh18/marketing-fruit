import 'package:Marketing_Fruit/components/entertainment_menu_drawer.dart';
import 'package:flutter/material.dart';
import 'package:Marketing_Fruit/screens/entertainment_arc/frame19d4.dart';
import '../../components/next_button.dart';
import '../../components/player_details.dart';
import '../../components/text_bubble.dart';

class Frame19d3 extends StatefulWidget {
  const Frame19d3({super.key});

  @override
  State<Frame19d3> createState() => _Frame19d3State();
}

class _Frame19d3State extends State<Frame19d3> {
  final playerDetails = PlayerDetails();


  @override
  void initState() {
    super.initState();
    // Save progress when entering this frame
    playerDetails.saveProgress('frame19d3', null);
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
                "The payment arrived soon after. It wasn’t life-changing money, but it covered production costs and left a respectable margin. From a business standpoint, it was clean: moderate sales, decent profit margin, very low operational cost. But there was a quiet tradeoff — once the rights were sold, customer loyalty no longer belonged to the creator. The audience engaged with the network, not the individual behind the content."
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
                    builder: (context) => Frame19d4(),
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
