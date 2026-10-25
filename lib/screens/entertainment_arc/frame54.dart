import 'dart:io';

import 'package:Marketing_Fruit/screens/entertainment_arc/frame11.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:Marketing_Fruit/components/player_details.dart';
import '../../components/answer_bubble.dart';
import '../../components/text_bubble.dart';
import '../../components/entertainment_menu_drawer.dart';
import '../dashboard/main_layout.dart';
import 'frame54a1.dart';
import 'frame54b1.dart';
import 'frame54c1.dart';
import 'frame54d1.dart';

class Frame54 extends StatefulWidget {
  final String? background;
  const Frame54({super.key, this.background});

  @override
  State<Frame54> createState() => _Frame54State();
}

class _Frame54State extends State<Frame54> {
  String role = '';
  final playerDetails = PlayerDetails();

  Future<void> _updateGameMechanics({
    required String userId,
    required int salesChange,
    required int profitMarginChange,
    required int costChange,
    required int loyaltyChange,
  }) async {
    final snapshot = await FirebaseDatabase.instance.ref('gameMechanics/$userId/').get();

    final sales = int.tryParse(snapshot.child('sales').value.toString()) ?? 0;
    final profitMargin = int.tryParse(snapshot.child('profit_margin').value.toString()) ?? 0;
    final costOfOperations = int.tryParse(snapshot.child('cost_of_operations').value.toString()) ?? 0;
    final customerLoyalty = int.tryParse(snapshot.child('customer_loyalty').value.toString()) ?? 0;

    await FirebaseDatabase.instance.ref('gameMechanics/$userId/').update({
      'sales': sales + salesChange,
      'profit_margin': profitMargin + profitMarginChange,
      'cost_of_operations': costOfOperations + costChange,
      'customer_loyalty': customerLoyalty + loyaltyChange,
    });
  }

  @override
  void initState() {
    super.initState();
    // Save progress when entering this frame
    playerDetails.saveProgress('frame54', null);
    fetchRole();
  }

  Future<void> fetchRole() async {
    final userId = FirebaseAuth.instance.currentUser!.uid;
    final ref = FirebaseDatabase.instance.ref('users/$userId');
    final snapshot = await ref.get();
    final dbRole = snapshot.child("role").value.toString();
    role = dbRole;
  }

  @override
  Widget build(BuildContext context) {
    final isMobile = !kIsWeb && (Platform.isAndroid || Platform.isIOS);
    final screenSize = MediaQuery.of(context).size;
    final screenHeight = screenSize.height;
    final screenWidth = screenSize.width;
    final userId = FirebaseAuth.instance.currentUser!.uid;

    Widget verticalSpacer(double factor) => SizedBox(height: factor);

    return Scaffold(
      body: Stack(
        children: [
          // Background
          SizedBox.expand(
            child: Image.asset(
              widget.background ?? 'assets/EA3.png',
              fit: BoxFit.cover,
            ),
          ),

          // Julian Kelly Image
          Positioned(
            bottom: screenHeight * 0.07,
            left: screenWidth * 0.05,
            child: Image.asset(
              'assets/explaining.gif',
              height: screenHeight * 0.80,
            ),
          ),

          // Message Bubble with tap to go to course screen
          Positioned(
            bottom: screenHeight * 0.55,
            left: screenWidth * 0.35,
            child: MouseRegion(
              cursor: SystemMouseCursors.click,
              child: GestureDetector(
                onTap: () {
                  // Navigate to course screen (same as Frame12)
                  if (!mounted) return; Navigator.push(context,
                    MaterialPageRoute(
                      builder: (context) => MainLayout(userRole: role, nftindex: 2, fs: true, sId: 1),
                    ),
                  );
                },
                child: MessageBubbleWithImage(
                  imageAsset: 'assets/messagebubble.png',
                  text:
                  "Hey user, things are really amping up, it is better to gain enough marketing knowledge before taking decision which we might regret later, lets start with the Marketing 101 course and complete",
                  textStyle: const TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.black,
                    fontSize: 18,
                  ),
                  maxWidth: screenWidth * 0.3,
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
                ),
              ),
            ),
          ),

          // Text Bubble
          Positioned(
            bottom: isMobile ? screenHeight * 0.45 : screenHeight * 0.38,
            left: screenWidth * 0.05,
            right: screenWidth * 0.05,
            child: TextBubble(
              message:
              "Awesome, now let us start with securing the funding for your production. You need to secure funding for your first major production. What is your approach?",
            ),
          ),

          // Answer Bubbles
          Positioned(
            bottom: screenHeight * 0.07,
            left: screenWidth * 0.05,
            right: screenWidth * 0.05,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: AnswerBubble(
                        label: 'Pitch to investors for \nexternal funding',
                        onTap: () async {
                          await _updateGameMechanics(
                            userId: userId,
                            salesChange: (0.10 * 100).toInt(),
                            profitMarginChange: -(0.05 * 100).toInt(),
                            costChange: (0.10 * 100).toInt(),
                            loyaltyChange: (0.05 * 100).toInt(),
                          );
                          if (!mounted) return; Navigator.push(context,
                            MaterialPageRoute(builder: (_) => Frame54a1()),
                          );
                        },
                      ),
                    ),
                    SizedBox(width: screenWidth * 0.06),
                    Expanded(
                      child: AnswerBubble(
                        label: 'Take a business loan \n to fund production',
                        onTap: () async {
                          await _updateGameMechanics(
                            userId: userId,
                            salesChange: (0.05 * 100).toInt(),
                            profitMarginChange: -(0.10 * 100).toInt(),
                            costChange: (0.05 * 100).toInt(),
                            loyaltyChange: (0.10 * 100).toInt(),
                          );
                          if (!mounted) return; Navigator.push(context,
                            MaterialPageRoute(builder: (_) => Frame54b1()),
                          );
                        },
                      ),
                    ),
                  ],
                ),
                verticalSpacer(screenHeight * 0.02),
                Row(
                  children: [
                    Expanded(
                      child: AnswerBubble(
                        label: 'Crowdfund the project \n from loyal fans',
                        onTap: () async {
                          await _updateGameMechanics(
                            userId: userId,
                            salesChange: -(0.05 * 100).toInt(),
                            profitMarginChange: (0.15 * 100).toInt(),
                            costChange: -(0.10 * 100).toInt(),
                            loyaltyChange: (0.20 * 100).toInt(),
                          );
                          if (!mounted) return; Navigator.push(context,
                            MaterialPageRoute(builder: (_) => Frame54c1()),
                          );
                        },
                      ),
                    ),
                    SizedBox(width: screenWidth * 0.06),
                    Expanded(
                      child: AnswerBubble(
                        label: 'Bootstrap and self-fund \n from savings',
                        onTap: () async {
                          await _updateGameMechanics(
                            userId: userId,
                            salesChange: -(0.10 * 100).toInt(),
                            profitMarginChange: (0.10 * 100).toInt(),
                            costChange: -(0.15 * 100).toInt(),
                            loyaltyChange: (0.05 * 100).toInt(),
                          );
                          if (!mounted) return; Navigator.push(context,
                            MaterialPageRoute(builder: (_) => Frame54d1()),
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Entertainment Menu Drawer
          const EntertainmentMenuDrawer(),
        ],
      ),
    );
  }
}
