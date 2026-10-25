import 'dart:io';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import '../../components/answer_bubble.dart';
import '../../components/player_details.dart';
import '../../components/text_bubble.dart';
import '../../components/entertainment_menu_drawer.dart';
import 'frame10.dart';

class Frame9 extends StatefulWidget {
  const Frame9({super.key});

  @override
  State<Frame9> createState() => _Frame9State();
}

class _Frame9State extends State<Frame9> {
  String? companyName;
  String userId = FirebaseAuth.instance.currentUser!.uid;

  final Color bubbleBackground = Color(0xFFDED08B).withOpacity(0.8);

  @override
  void initState() {
    super.initState();
    // Save progress when entering this frame
    PlayerDetails().saveProgress('frame9', null);
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
    final isMobile = !kIsWeb && (Platform.isAndroid || Platform.isIOS);
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
                "The licensing, registration and legal work of $companyName firm will cost \$700",
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
          Positioned(
            bottom: screenHeight * 0.05,
            left: isMobile ? screenWidth * 0.4 : screenWidth * 0.5 - 200,
            child: AnswerBubble(
              label: 'Pay \$700',
              onTap: () async {
                final snapshot = await FirebaseDatabase.instance
                    .ref('wallet/$userId/balance')
                    .get();
                final balance = int.tryParse(snapshot.value.toString()) ?? 0;

                await FirebaseDatabase.instance
                    .ref('wallet/$userId/balance')
                    .set(balance - 700);

                if (!mounted) return; Navigator.push(context,
                  MaterialPageRoute(builder: (context) => Frame10()),
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
