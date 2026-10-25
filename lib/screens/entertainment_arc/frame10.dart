
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../../components/next_button.dart';
import '../../components/player_details.dart';
import '../../components/text_bubble.dart';
import '../../components/entertainment_menu_drawer.dart';
import 'frame11.dart';

class Frame10 extends StatefulWidget {
  const Frame10({super.key});

  @override
  State<Frame10> createState() => _Frame10State();
}

class _Frame10State extends State<Frame10> {
  String? companyName;
  String userId = FirebaseAuth.instance.currentUser!.uid;

  final Color bubbleBackground = Color(0xFFDED08B).withOpacity(0.8);

  @override
  void initState() {
    super.initState();
    // Save progress when entering this frame
    PlayerDetails().saveProgress('frame10', null);
    _loadCompanyName();
  }

  Future<void> _loadCompanyName() async {
    final name = await PlayerDetails().fetchCompanyName();
    setState(() {
      companyName = name;
    });
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
              'assets/EA1.png',
              fit: BoxFit.cover,
            ),
          ),

          // Text Bubble
          if (companyName != null)
            Positioned(
              bottom: screenHeight * 0.18,
              left: screenWidth * 0.05,
              right: screenWidth * 0.05,
              child: TextBubble(
                message:
                "Congratulations on completing the legal part. Now you are the official owner of $companyName firm. Let us move on to the next step of setting up our Entertainment & streaming business.",
              ),
            )
          else
            Positioned(
              bottom: screenHeight * 0.18,
              left: screenWidth * 0.05,
              right: screenWidth * 0.05,
              child: Center(child: CircularProgressIndicator()),
            ),

          // Answer Bubble
          // Positioned(
          //   bottom: screenHeight * 0.05,
          //   left: screenWidth * 0.5 - 200,
          //   child: AnswerBubble(
          //     label: 'Pay \$700',
          //     onTap: () async {
          //       final snapshot = await FirebaseDatabase.instance
          //           .ref('wallet/$userId/balance')
          //           .get();
          //       final balance = int.tryParse(snapshot.value.toString()) ?? 0;
          //
          //       await FirebaseDatabase.instance
          //           .ref('wallet/$userId/balance')
          //           .set(balance - 700);
          //
          //       Navigator.push(
          //         context,
          //         MaterialPageRoute(builder: (context) => Frame10()),
          //       );
          //     },
          //   ),
          // ),
          Positioned(
            bottom: screenSize.height * 0.05,
            right: screenSize.width * 0.05,
            child: NextButton(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => Frame11(),
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
