import 'package:flutter/material.dart';
import '../../components/next_button.dart';
import '../../components/player_details.dart';
import '../../components/text_bubble.dart';
import '../../components/entertainment_menu_drawer.dart';
import 'frame57b5.dart';

class Frame57b4 extends StatefulWidget {
  const Frame57b4({super.key});

  @override
  State<Frame57b4> createState() => _Frame57b4State();
}

class _Frame57b4State extends State<Frame57b4> {
  final playerDetails = PlayerDetails();

  @override
  void initState() {
    super.initState();
    playerDetails.saveProgress('frame57b4', null);
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
              'assets/EA4.png',
              fit: BoxFit.cover,
            ),
          ),
          // Julian Kelly Cartoon - Responsive Position (commented out as original)
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
            bottom: screenHeight * 0.18,
            left: screenWidth * 0.05,
            right: screenWidth * 0.05,
            child: TextBubble(
              message:
              "Production begins with enthusiasm.Operational costs stay manageable.Profit margin looks promising.Sales? Still uncertain. But your audience senses something real.",
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
                    builder: (context) => Frame57b5(),
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
