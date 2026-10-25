import 'dart:io';

import 'package:Marketing_Fruit/screens/dashboard/main_layout.dart';
import 'package:Marketing_Fruit/screens/entertainment_arc/frame11.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:Marketing_Fruit/components/player_details.dart';
import 'package:Marketing_Fruit/screens/entertainment_arc/frame26a1.dart';
import 'package:Marketing_Fruit/screens/entertainment_arc/frame26d1.dart';
import '../../components/answer_bubble.dart';
import '../../components/text_bubble.dart';
import '../../components/entertainment_menu_drawer.dart';
import 'frame26b1.dart';
import 'frame26c1.dart';

class Frame26 extends StatefulWidget {
  final String? background;
  const Frame26({super.key, this.background});

  @override
  State<Frame26> createState() => _Frame26State();
}

class _Frame26State extends State<Frame26> {
  String role = '';
  
  @override
  void initState() {
    super.initState();
    // Save progress when entering this frame
    PlayerDetails().saveProgress('frame26', null);
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
    final playerDetails = PlayerDetails();
    final userId = FirebaseAuth.instance.currentUser!.uid;

    return Scaffold(
      body: Stack(
        children: [
          // Background Image
          SizedBox.expand(
            child: Image.asset(
              'assets/EA2.png',
              fit: BoxFit.cover,
            ),
          ),

          // Julian Kelly Cartoon - Responsive Position
          Positioned(
            bottom: screenHeight * 0.07, // 8% from bottom
            left: screenWidth * 0.05, // Optional: slight left padding
            child: Image.asset(
              'assets/explaining.gif',
              height: screenHeight * 0.80, // 65% of screen height
            ),
          ),

          // Message bubble wrapped with GestureDetector to go to CourseDetailScreen
          Positioned(
            bottom: screenHeight * 0.55,
            left: screenWidth * 0.35,
            child : MouseRegion(
            cursor: SystemMouseCursors.click,
            child: GestureDetector(
              onTap: () {
                // Navigate to course screen (same as Frame12)
                if (!mounted) return; Navigator.push(context,
                  MaterialPageRoute(
                      builder: (context) => MainLayout(userRole: role,nftindex: 2,fs: true, sId: 2)
                    //     CourseDetailScreen(
                    //   courseId: 3016,
                    //   courseName: "Marketing 101",
                    //   onLessonTap: null,
                    // ),
                  ),
                );
              },
              child: MessageBubbleWithImage(
                imageAsset: 'assets/messagebubble.png',
                text:
                    "Did you know knowing different marketing channels and strategies might greatly impact on how you navigate your business through tough times \n Know different marketing channels and strategies through our course \n Go to Courses",
                textStyle: const TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                  fontSize: 18,
                ),
                maxWidth: screenWidth * 0.3, // You can adjust maxWidth
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
              ),
            ),
            ),
          ),

          // Text Bubble - Responsive Position and Width
          Positioned(
            bottom: isMobile ? screenHeight * 0.45 : screenHeight * 0.38, // 23% from bottom
            left: screenWidth * 0.05,
            right: screenWidth * 0.05,
            child: TextBubble(
              message:
                  "Now that our first assignment is successful, it is time to focus on long term goals. Your studio has gained traction, and now you want to expand. What’s your next move?",
            ),
          ),

          Positioned(
            bottom: screenHeight * 0.07,
            left: screenWidth * 0.25, // Center the button (200 width / 2)
            child: Column(
              // replaced deprecated spacing usage with SizedBox later in rows
              children: [
                Row(
                  children: [
                    Expanded(
                      child: AnswerBubble(
                        label: 'Open a second studio\nlocation in a major city',
                        onTap: () async {
                          final snapshot = await FirebaseDatabase.instance
                              .ref('gameMechanics/$userId/')
                              .get();

                          final sales = int.tryParse(snapshot.child('sales').value.toString()) ?? 0;
                          final profitMargin = int.tryParse(snapshot.child('profit_margin').value.toString()) ?? 0;
                          final costOfOperations = int.tryParse(snapshot.child('cost_of_operations').value.toString()) ?? 0;
                          final customerLoyalty = int.tryParse(snapshot.child('customer_loyalty').value.toString()) ?? 0;
                          final type = snapshot.child('type').value.toString();

                          int updatedSales = 0;
                          int updatedProfitMargin = 0;
                          int updatedCostOfOperations = 0;
                          int updatedCustomerLoyalty = 0;

                          switch (type) {
                            case 'm':
                              updatedSales = (sales + (sales * 0.20)).toInt();
                              updatedProfitMargin = (profitMargin - (profitMargin * 0.05)).toInt();
                              updatedCostOfOperations = (costOfOperations + (costOfOperations * 0.25)).toInt();
                              updatedCustomerLoyalty = (customerLoyalty + (customerLoyalty * 0.08)).toInt();
                              break;
                            case 's':
                              updatedSales = (sales + (sales * 0.12)).toInt();
                              updatedProfitMargin = (profitMargin - (profitMargin * 0.04)).toInt();
                              updatedCostOfOperations = (costOfOperations + (costOfOperations * 0.15)).toInt();
                              updatedCustomerLoyalty = (customerLoyalty + (customerLoyalty * 0.06)).toInt();
                              break;
                            case 'w':
                              updatedSales = (sales + (sales * 0.18)).toInt();
                              updatedProfitMargin = (profitMargin - (profitMargin * 0.06)).toInt();
                              updatedCostOfOperations = (costOfOperations + (costOfOperations * 0.22)).toInt();
                              updatedCustomerLoyalty = (customerLoyalty + (customerLoyalty * 0.10)).toInt();
                              break;
                            case 'd':
                              updatedSales = (sales + (sales * 0.16)).toInt();
                              updatedProfitMargin = (profitMargin - (profitMargin * 0.06)).toInt();
                              updatedCostOfOperations = (costOfOperations + (costOfOperations * 0.18)).toInt();
                              updatedCustomerLoyalty = (customerLoyalty + (customerLoyalty * 0.10)).toInt();
                              break;
                          }

                          final updatedChoice = 'studio';

                          await FirebaseDatabase.instance.ref('gameMechanics/$userId/').update({
                            'sales': updatedSales,
                            'profit_margin': updatedProfitMargin,
                            'cost_of_operations': updatedCostOfOperations,
                            'customer_loyalty': updatedCustomerLoyalty,
                            'choice': updatedChoice
                          });

                          if (!mounted) return; Navigator.push(context,
                            MaterialPageRoute(
                              builder: (context) => Frame26a1(),
                            ),
                          );
                        },
                      ),
                    ),
                    SizedBox(width: screenWidth * 0.06),
                    Expanded(
                      child: AnswerBubble(
                        label: 'Collaborate with international\nproduction partners',
                        onTap: () async {
                          final snapshot = await FirebaseDatabase.instance
                              .ref('gameMechanics/$userId/')
                              .get();

                          final sales = int.tryParse(snapshot.child('sales').value.toString()) ?? 0;
                          final profitMargin = int.tryParse(snapshot.child('profit_margin').value.toString()) ?? 0;
                          final costOfOperations = int.tryParse(snapshot.child('cost_of_operations').value.toString()) ?? 0;
                          final customerLoyalty = int.tryParse(snapshot.child('customer_loyalty').value.toString()) ?? 0;
                          final type = snapshot.child('type').value.toString();

                          int updatedSales = 0;
                          int updatedProfitMargin = 0;
                          int updatedCostOfOperations = 0;
                          int updatedCustomerLoyalty = 0;

                          switch (type) {
                            case 'm':
                              updatedSales = (sales + (sales * 0.30)).toInt();
                              updatedProfitMargin = (profitMargin - (profitMargin * 0.07)).toInt();
                              updatedCostOfOperations = (costOfOperations + (costOfOperations * 0.20)).toInt();
                              updatedCustomerLoyalty = (customerLoyalty + (customerLoyalty * 0.12)).toInt();
                              break;
                            case 's':
                              updatedSales = (sales + (sales * 0.18)).toInt();
                              updatedProfitMargin = (profitMargin - (profitMargin * 0.05)).toInt();
                              updatedCostOfOperations = (costOfOperations + (costOfOperations * 0.12)).toInt();
                              updatedCustomerLoyalty = (customerLoyalty + (customerLoyalty * 0.08)).toInt();
                              break;
                            case 'w':
                              updatedSales = (sales + (sales * 0.28)).toInt();
                              updatedProfitMargin = (profitMargin - (profitMargin * 0.07)).toInt();
                              updatedCostOfOperations = (costOfOperations + (costOfOperations * 0.18)).toInt();
                              updatedCustomerLoyalty = (customerLoyalty + (customerLoyalty * 0.12)).toInt();
                              break;
                            case 'd':
                              updatedSales = (sales + (sales * 0.24)).toInt();
                              updatedProfitMargin = (profitMargin - (profitMargin * 0.08)).toInt();
                              updatedCostOfOperations = (costOfOperations + (costOfOperations * 0.15)).toInt();
                              updatedCustomerLoyalty = (customerLoyalty + (customerLoyalty * 0.14)).toInt();
                              break;
                          }

                          final updatedChoice = 'collab';

                          await FirebaseDatabase.instance.ref('gameMechanics/$userId/').update({
                            'sales': updatedSales,
                            'profit_margin': updatedProfitMargin,
                            'cost_of_operations': updatedCostOfOperations,
                            'customer_loyalty': updatedCustomerLoyalty,
                            'choice': updatedChoice
                          });
                          if (!mounted) return; Navigator.push(context,
                            MaterialPageRoute(
                              builder: (context) => Frame26b1(),
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ),
                SizedBox(height: screenWidth * 0.03),
                Row(
                  children: [
                    Expanded(
                      child: AnswerBubble(
                        label: 'Invest in virtual production\nand AI-driven content creation',
                        onTap: () async {
                          final snapshot = await FirebaseDatabase.instance
                              .ref('gameMechanics/$userId/')
                              .get();

                          final sales = int.tryParse(snapshot.child('sales').value.toString()) ?? 0;
                          final profitMargin = int.tryParse(snapshot.child('profit_margin').value.toString()) ?? 0;
                          final costOfOperations = int.tryParse(snapshot.child('cost_of_operations').value.toString()) ?? 0;
                          final customerLoyalty = int.tryParse(snapshot.child('customer_loyalty').value.toString()) ?? 0;
                          final type = snapshot.child('type').value.toString();

                          int updatedSales = 0;
                          int updatedProfitMargin = 0;
                          int updatedCostOfOperations = 0;
                          int updatedCustomerLoyalty = 0;

                          switch (type) {
                            case 'm':
                              updatedSales = (sales + (sales * 0.10)).toInt();
                              updatedProfitMargin = (profitMargin + (profitMargin * 0.08)).toInt();
                              updatedCostOfOperations = (costOfOperations - (costOfOperations * 0.10)).toInt();
                              updatedCustomerLoyalty = (customerLoyalty - (customerLoyalty * 0.03)).toInt();
                              break;
                            case 's':
                              updatedSales = (sales + (sales * 0.25)).toInt();
                              updatedProfitMargin = (profitMargin + (profitMargin * 0.12)).toInt();
                              updatedCostOfOperations = (costOfOperations - (costOfOperations * 0.20)).toInt();
                              updatedCustomerLoyalty = (customerLoyalty + (customerLoyalty * 0.02)).toInt();
                              break;
                            case 'w':
                              updatedSales = (sales + (sales * 0.14)).toInt();
                              updatedProfitMargin = (profitMargin + (profitMargin * 0.11)).toInt();
                              updatedCostOfOperations = (costOfOperations - (costOfOperations * 0.18)).toInt();
                              updatedCustomerLoyalty = (customerLoyalty + (customerLoyalty * 0.02)).toInt();
                              break;
                            case 'd':
                              updatedSales = (sales + (sales * 0.10)).toInt();
                              updatedProfitMargin = (profitMargin + (profitMargin * 0.10)).toInt();
                              updatedCostOfOperations = (costOfOperations - (costOfOperations * 0.15)).toInt();
                              updatedCustomerLoyalty = (customerLoyalty + (customerLoyalty * 0.01)).toInt();
                              break;
                          }

                          final updatedChoice = 'ai';

                          await FirebaseDatabase.instance.ref('gameMechanics/$userId/').update({
                            'sales': updatedSales,
                            'profit_margin': updatedProfitMargin,
                            'cost_of_operations': updatedCostOfOperations,
                            'customer_loyalty': updatedCustomerLoyalty,
                            'choice': updatedChoice
                          });
                          if (!mounted) return; Navigator.push(context,
                            MaterialPageRoute(
                              builder: (context) => Frame26c1(),
                            ),
                          );
                        },
                      ),
                    ),
                    SizedBox(width: screenWidth * 0.06),
                    Expanded(
                      child: AnswerBubble(
                        label: 'Target niche markets like\nindie films and documentaries',
                        onTap: () async {
                          final snapshot = await FirebaseDatabase.instance
                              .ref('gameMechanics/$userId/')
                              .get();

                          final sales = int.tryParse(snapshot.child('sales').value.toString()) ?? 0;
                          final profitMargin = int.tryParse(snapshot.child('profit_margin').value.toString()) ?? 0;
                          final costOfOperations = int.tryParse(snapshot.child('cost_of_operations').value.toString()) ?? 0;
                          final customerLoyalty = int.tryParse(snapshot.child('customer_loyalty').value.toString()) ?? 0;
                          final type = snapshot.child('type').value.toString();

                          int updatedSales = 0;
                          int updatedProfitMargin = 0;
                          int updatedCostOfOperations = 0;
                          int updatedCustomerLoyalty = 0;

                          switch (type) {
                            case 'm':
                              updatedSales = (sales + (sales * 0.15)).toInt();
                              updatedProfitMargin = (profitMargin + (profitMargin * 0.05)).toInt();
                              updatedCostOfOperations = (costOfOperations + (costOfOperations * 0.10)).toInt();
                              updatedCustomerLoyalty = (customerLoyalty + (customerLoyalty * 0.10)).toInt();
                              break;
                            case 's':
                              updatedSales = (sales + (sales * 0.14)).toInt();
                              updatedProfitMargin = (profitMargin + (profitMargin * 0.06)).toInt();
                              updatedCostOfOperations = (costOfOperations + (costOfOperations * 0.08)).toInt();
                              updatedCustomerLoyalty = (customerLoyalty + (customerLoyalty * 0.15)).toInt();
                              break;
                            case 'w':
                              updatedSales = (sales + (sales * 0.20)).toInt();
                              updatedProfitMargin = (profitMargin + (profitMargin * 0.06)).toInt();
                              updatedCostOfOperations = (costOfOperations + (costOfOperations * 0.10)).toInt();
                              updatedCustomerLoyalty = (customerLoyalty + (customerLoyalty * 0.16)).toInt();
                              break;
                            case 'd':
                              updatedSales = (sales + (sales * 0.18)).toInt();
                              updatedProfitMargin = (profitMargin + (profitMargin * 0.07)).toInt();
                              updatedCostOfOperations = (costOfOperations + (costOfOperations * 0.09)).toInt();
                              updatedCustomerLoyalty = (customerLoyalty + (customerLoyalty * 0.30)).toInt();
                              break;
                          }

                          final updatedChoice = 'niche';

                          await FirebaseDatabase.instance.ref('gameMechanics/$userId/').update({
                            'sales': updatedSales,
                            'profit_margin': updatedProfitMargin,
                            'cost_of_operations': updatedCostOfOperations,
                            'customer_loyalty': updatedCustomerLoyalty,
                            'choice': updatedChoice
                          });
                          if (!mounted) return; Navigator.push(context,
                            MaterialPageRoute(
                              builder: (context) => Frame26d1(),
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Menu Drawer
          const EntertainmentMenuDrawer(),
        ],
      ),
    );
  }
}
