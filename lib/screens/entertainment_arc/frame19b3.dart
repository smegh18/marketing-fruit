import 'package:Marketing_Fruit/components/entertainment_menu_drawer.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import '../../components/next_button.dart';
import '../../components/player_details.dart';
import '../../components/text_bubble.dart';
import 'frame19b4.dart';
import 'frame19bsd1.dart';

class Frame19b3 extends StatefulWidget {
  const Frame19b3({super.key});

  @override
  State<Frame19b3> createState() => _Frame19b3State();
}

class _Frame19b3State extends State<Frame19b3> {
  final playerDetails = PlayerDetails();


  @override
  void initState() {
    super.initState();
    // Save progress when entering this frame
    playerDetails.saveProgress('frame19b3', null);
  }

  @override
  Widget build(BuildContext context) {
    final userId = FirebaseAuth.instance.currentUser!.uid; // Replace with actual user ID
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
              "But independence came with weight. Bugs, buffering issues, customer support, hosting costs — it all added up fast. Without the muscle of a major distributor, discoverability was hard and expensive. While sales were promising in bursts, the profit margins were thin, and operational costs climbed with each new user.",
            ),
          ),

          Positioned(
            bottom: screenSize.height * 0.05,
            right: screenSize.width * 0.05,
            child: NextButton(
              onTap: () async {
                final snapshot = await FirebaseDatabase.instance
                    .ref('gameMechanics/$userId/')
                    .get();
                final type = snapshot.child('type').value.toString();
                if (type == 's' || type == 'd') {
                  if (!mounted) return; Navigator.push(context,
                    MaterialPageRoute(
                      builder: (context) => Frame19bsd1(),
                    ),
                  );
                }
                else {
                  if (!mounted) return; Navigator.push(context,
                    MaterialPageRoute(
                      builder: (context) => Frame19b4(),
                    ),
                  );
                }
              },
            ),
          ),
          EntertainmentMenuDrawer()
        ],
      ),
    );
  }
}
