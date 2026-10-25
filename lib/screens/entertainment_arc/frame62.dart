import 'dart:io';

import 'package:Marketing_Fruit/screens/dashboard/main_layout.dart';
import 'package:Marketing_Fruit/screens/entertainment_arc/frame11.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:Marketing_Fruit/components/player_details.dart';
import '../../components/answer_bubble.dart';
import '../../components/text_bubble.dart';
import '../../components/entertainment_menu_drawer.dart';
import 'frame19.dart';

class Frame62 extends StatefulWidget {
  final String? background;
  const Frame62({super.key, this.background});

  @override
  State<Frame62> createState() => _Frame62State();
}

class _Frame62State extends State<Frame62> {
  String? role;
  final playerDetails = PlayerDetails();

  Future<void> _updateGameMechanics({
    required String userId,
    required int salesChange,
    required int profitMarginChange,
    required int costChange,
    required int loyaltyChange,
  }) async {
    final snapshot =
    await FirebaseDatabase.instance.ref('gameMechanics/$userId/').get();

    final sales = int.tryParse(snapshot.child('sales').value.toString()) ?? 0;
    final profitMargin =
        int.tryParse(snapshot.child('profit_margin').value.toString()) ?? 0;
    final costOfOperations =
        int.tryParse(snapshot.child('cost_of_operations').value.toString()) ?? 0;
    final customerLoyalty =
        int.tryParse(snapshot.child('customer_loyalty').value.toString()) ?? 0;

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
    playerDetails.saveProgress('frame62', null);
    fetchRole();
  }

  Future<void> fetchRole() async {
    final userId = FirebaseAuth.instance.currentUser!.uid;
    final ref = FirebaseDatabase.instance.ref('users/$userId');
    final snapshot = await ref.get();
    setState(() {
      role = snapshot.child("role").value?.toString() ?? '';
    });
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
              'assets/EA3.png',
              fit: BoxFit.cover,
            ),
          ),

          // Julian Kelly Cartoon
          Positioned(
            bottom: screenHeight * 0.07,
            left: screenWidth * 0.05,
            child: Image.asset(
              'assets/explaining.gif',
              height: screenHeight * 0.80,
            ),
          ),

          // Message Bubble (tap to go to course screen)
          Positioned(
            bottom: screenHeight * 0.55,
            left: screenWidth * 0.35,
            child: MouseRegion(
              cursor: SystemMouseCursors.click,
              child: GestureDetector(
                onTap: () {
                  if (!mounted) return; Navigator.push(context,
                    MaterialPageRoute(
                        builder: (context) => MainLayout(
                            userRole: role ?? 'Student',
                            nftindex: 2,
                            fs: true,
                            sId: 1)),
                  );
                },
                child: MessageBubbleWithImage(
                  imageAsset: 'assets/messagebubble.png',
                  text:
                  "Hey there, now that you are done with definition and abbreviations in the course, lets continue with Foundations of marketing. Complete the course so that you can have a smooth way going ahead in the game \nGo to the course!",
                  textStyle: const TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.black,
                    fontSize: 18,
                  ),
                  maxWidth: screenWidth * 0.3,
                  padding: const EdgeInsets.symmetric(
                      horizontal: 20, vertical: 15),
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
              "Your production schedule is delayed due to such issues. How do you handle it?",
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
                        label: 'Increase production\nbudget to speed up work',
                        onTap: () async {
                          await _updateGameMechanics(
                            userId: userId,
                            salesChange: (0.05 * 100).toInt(),
                            profitMarginChange: -(0.10 * 100).toInt(),
                            costChange: (0.15 * 100).toInt(),
                            loyaltyChange: (0.05 * 100).toInt(),
                          );
                          if (!mounted) return; Navigator.push(context,
                            MaterialPageRoute(builder: (_) => Frame19()),
                          );
                        },
                      ),
                    ),
                    SizedBox(width: screenWidth * 0.06),
                    Expanded(
                      child: AnswerBubble(
                        label: 'Delay the release and\nupdate fans honestly',
                        onTap: () async {
                          await _updateGameMechanics(
                            userId: userId,
                            salesChange: -(0.05 * 100).toInt(),
                            profitMarginChange: 0,
                            costChange: 0,
                            loyaltyChange: (0.15 * 100).toInt(),
                          );
                          if (!mounted) return; Navigator.push(context,
                            MaterialPageRoute(builder: (_) => Frame19()),
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
                        label: 'Reduce content quality\nto meet the deadline',
                        onTap: () async {
                          await _updateGameMechanics(
                            userId: userId,
                            salesChange: -(0.10 * 100).toInt(),
                            profitMarginChange: (0.10 * 100).toInt(),
                            costChange: -(0.05 * 100).toInt(),
                            loyaltyChange: -(0.15 * 100).toInt(),
                          );
                          if (!mounted) return; Navigator.push(context,
                            MaterialPageRoute(builder: (_) => Frame19()),
                          );
                        },
                      ),
                    ),
                    SizedBox(width: screenWidth * 0.06),
                    Expanded(
                      child: AnswerBubble(
                        label: 'Shift focus to another project\nwhile resolving delays quietly',
                        onTap: () async {
                          await _updateGameMechanics(
                            userId: userId,
                            salesChange: (0.05 * 100).toInt(),
                            profitMarginChange: 0,
                            costChange: (0.05 * 100).toInt(),
                            loyaltyChange: (0.10 * 100).toInt(),
                          );
                          if (!mounted) return; Navigator.push(context,
                            MaterialPageRoute(builder: (_) => Frame19()),
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
