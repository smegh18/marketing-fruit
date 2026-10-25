import 'dart:io';

import 'package:Marketing_Fruit/course/models.dart';
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
import 'frame12a1.dart';
import 'frame12b1.dart';
import 'frame12c1.dart';
import 'frame12d1.dart';

class Frame12 extends StatefulWidget {
  const Frame12({super.key});

  @override
  State<Frame12> createState() => _Frame12State();
}

class _Frame12State extends State<Frame12> {
  final List<Course> _courses = [];
  final bool _loadingCourses = true;
  String? _fetchError;
  String role = '';
  int _messageStage = 0; // 0 = first message, 1 = second message


  @override
  void initState() {
    super.initState();
    final playerDetails = PlayerDetails();
    // Save progress when entering this frame
    playerDetails.saveProgress('frame12', null);
    playerDetails.gameMechanics();
    fetchRole();

    print('Frame12 initState: fetching courses...');
    // fetchCourses();
  }

  // Future<void> fetchCourses() async {
  //   try {
  //     final courses = await CourseService.fetchCourses();
  //     print('Courses fetched: ${courses.length}');
  //     setState(() {
  //       _courses = courses;
  //       _loadingCourses = false;
  //     });
  //   } catch (e) {
  //     print('Failed to fetch courses: $e');
  //     setState(() {
  //       _loadingCourses = false;
  //       _fetchError = e.toString();
  //     });
  //   }
  // }

  Future<void> fetchRole() async {
    final userId = FirebaseAuth.instance.currentUser!.uid;
    final ref = FirebaseDatabase.instance.ref('users/$userId');
    final snapshot = await ref.get();
    final dbRole = snapshot.child("role").value.toString();
    setState(() {
      role = dbRole;
    });
  }

  @override
  Widget build(BuildContext context) {
    final isMobile = !kIsWeb && (Platform.isAndroid || Platform.isIOS);
    final screenSize = MediaQuery.of(context).size;
    final screenHeight = screenSize.height;
    final screenWidth = screenSize.width;
    final playerDetails = PlayerDetails();
    final userId = FirebaseAuth.instance.currentUser!.uid;

    Widget horizontalSpacer() => SizedBox(width: screenWidth * 0.10);
    Widget verticalSpacer() => SizedBox(height: isMobile ? screenHeight * 0.01 : screenHeight * 0.02);

    return Scaffold(
      body: Stack(
        children: [
          SizedBox.expand(
            child: Image.asset(
              'assets/EA2.png',
              fit: BoxFit.cover,
            ),
          ),
          Positioned(
            bottom: screenHeight * 0.07,
            left: screenWidth * 0.05,
            child: Image.asset(
              'assets/explaining.gif',
              height: screenHeight * 0.80,
            ),
          ),
          // Positioned(
          //   bottom: screenHeight * 0.55,
          //   left: screenWidth * 0.35,
          //   child: MessageBubbleWithImage(
          //     imageAsset: 'assets/messagebubble.png',
          //     text: "Hey Jay AI here once again. Before going ahead, I strongly recommend to go through our Definition and Abbreviations section in the course.",
          //     textStyle: const TextStyle(
          //       fontWeight: FontWeight.bold,
          //       color: Colors.black,
          //       fontSize: 18,
          //     ),
          //     maxWidth: screenWidth * 0.3,
          //     padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
          //   ),
          // ),
                    Positioned(
            bottom: screenHeight * 0.55,
            left: screenWidth * 0.35,
            child: MouseRegion(
              cursor: SystemMouseCursors.click,
              child: GestureDetector(
                onTap: () {
                  setState(() {
                    if (_messageStage == 0) {
                      _messageStage = 1; // Move to next message
                    } else if (_messageStage == 1) {
                      if (!mounted) return; Navigator.push(context,
                        MaterialPageRoute(
                          builder: (context) => MainLayout(userRole: role, nftindex: 2, fs: true, sId: 0),
                        ),
                      );
                    }
                  });
                },
                child: MessageBubbleWithImage(
                  imageAsset: 'assets/messagebubble.png',
                  text: _messageStage == 0
                      ? "Hey Jay AI here once again. Before going ahead, I strongly recommend to go through our Definition and Abbreviations section in the course."
                      : "This will help you understand various business terminology during this gameplay.\n\nGo to course!",
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



          Positioned(
            bottom: isMobile ? screenHeight * 0.45 : screenHeight * 0.38,
            left: screenWidth * 0.05,
            right: screenWidth * 0.05,
            child: TextBubble(
              message:
                  "Your content production studio is set up, but you need to decide on your primary content focus.What type of content will your studio focus on first?",
            ),
          ),
          Positioned(
            bottom: screenHeight * 0.07,
            left: screenWidth * 0.10,
            right: screenWidth * 0.10,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Expanded(
                      child: AnswerBubble(
                        label: 'High-budget movies \nfor theatrical release',
                        onTap: () async {
                          print('Tapped answer bubble: High-budget movies');
                          final snapshot = await FirebaseDatabase.instance.ref('gameMechanics/$userId/').get();

                          final sales = int.tryParse(snapshot.child('sales').value.toString()) ?? 0;
                          final profitMargin = int.tryParse(snapshot.child('profit_margin').value.toString()) ?? 0;
                          final costOfOperations = int.tryParse(snapshot.child('cost_of_operations').value.toString()) ?? 0;
                          final customerLoyalty = int.tryParse(snapshot.child('customer_loyalty').value.toString()) ?? 0;

                          final updatedSales = (sales + (sales * 0.15)).toInt();
                          final updatedProfitMargin = (profitMargin - (profitMargin * 0.10)).toInt();
                          final updatedCostOfOperations = (costOfOperations + (costOfOperations * 0.20)).toInt();
                          final updatedCustomerLoyalty = (customerLoyalty + (customerLoyalty * 0.10)).toInt();
                          final updatedType = 'm';

                          await FirebaseDatabase.instance.ref('gameMechanics/$userId/').update({
                            'sales': updatedSales,
                            'profit_margin': updatedProfitMargin,
                            'cost_of_operations': updatedCostOfOperations,
                            'customer_loyalty': updatedCustomerLoyalty,
                            'type': updatedType,
                          });

                          if (!mounted) return; Navigator.push(context,
                            MaterialPageRoute(builder: (context) => Frame12a1()),
                          );
                        },
                      ),
                    ),
                    SizedBox(width: screenWidth * 0.06),
                    Expanded(
                      child: AnswerBubble(
                        label: 'Web series for streaming \nplatforms',
                        onTap: () async {
                          print('Tapped answer bubble: Web series');
                          final snapshot = await FirebaseDatabase.instance.ref('gameMechanics/$userId/').get();

                          final sales = int.tryParse(snapshot.child('sales').value.toString()) ?? 0;
                          final profitMargin = int.tryParse(snapshot.child('profit_margin').value.toString()) ?? 0;
                          final costOfOperations = int.tryParse(snapshot.child('cost_of_operations').value.toString()) ?? 0;
                          final customerLoyalty = int.tryParse(snapshot.child('customer_loyalty').value.toString()) ?? 0;

                          final updatedSales = (sales + (sales * 0.10)).toInt();
                          final updatedProfitMargin = (profitMargin + (profitMargin * 0.05)).toInt();
                          final updatedCostOfOperations = (costOfOperations + (costOfOperations * 0.10)).toInt();
                          final updatedCustomerLoyalty = (customerLoyalty + (customerLoyalty * 0.15)).toInt();
                          final updatedType = 'w';

                          await FirebaseDatabase.instance.ref('gameMechanics/$userId/').update({
                            'sales': updatedSales,
                            'profit_margin': updatedProfitMargin,
                            'cost_of_operations': updatedCostOfOperations,
                            'customer_loyalty': updatedCustomerLoyalty,
                            'type': updatedType,
                          });

                          if (!mounted) return; Navigator.push(context,
                            MaterialPageRoute(builder: (context) => Frame12b1()),
                          );
                        },
                      ),
                    ),
                  ],
                ),
                verticalSpacer(),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Expanded(
                      child: AnswerBubble(
                        label: 'Short-form content \nfor social media',
                        onTap: () async {
                          print('Tapped answer bubble: Short-form content');
                          final snapshot = await FirebaseDatabase.instance.ref('gameMechanics/$userId/').get();

                          final sales = int.tryParse(snapshot.child('sales').value.toString()) ?? 0;
                          final profitMargin = int.tryParse(snapshot.child('profit_margin').value.toString()) ?? 0;
                          final costOfOperations = int.tryParse(snapshot.child('cost_of_operations').value.toString()) ?? 0;
                          final customerLoyalty = int.tryParse(snapshot.child('customer_loyalty').value.toString()) ?? 0;

                          final updatedSales = (sales + (sales * 0.05)).toInt();
                          final updatedProfitMargin = (profitMargin + (profitMargin * 0.20)).toInt();
                          final updatedCostOfOperations = (costOfOperations - (costOfOperations * 0.10)).toInt();
                          final updatedCustomerLoyalty = (customerLoyalty + (customerLoyalty * 0.05)).toInt();
                          final updatedType = 's';

                          await FirebaseDatabase.instance.ref('gameMechanics/$userId/').update({
                            'sales': updatedSales,
                            'profit_margin': updatedProfitMargin,
                            'cost_of_operations': updatedCostOfOperations,
                            'customer_loyalty': updatedCustomerLoyalty,
                            'type': updatedType,
                          });

                          if (!mounted) return; Navigator.push(context,
                            MaterialPageRoute(builder: (context) => Frame12c1()),
                          );
                        },
                      ),
                    ),
                    SizedBox(width: screenWidth * 0.06),
                    Expanded(
                      child: AnswerBubble(
                        label: 'Documentaries and \ninvestigative journalism',
                        onTap: () async {
                          print('Tapped answer bubble: Documentaries');
                          final snapshot = await FirebaseDatabase.instance.ref('gameMechanics/$userId/').get();

                          final sales = int.tryParse(snapshot.child('sales').value.toString()) ?? 0;
                          final profitMargin = int.tryParse(snapshot.child('profit_margin').value.toString()) ?? 0;
                          final costOfOperations = int.tryParse(snapshot.child('cost_of_operations').value.toString()) ?? 0;
                          final customerLoyalty = int.tryParse(snapshot.child('customer_loyalty').value.toString()) ?? 0;

                          final updatedSales = (sales - (sales * 0.05)).toInt();
                          final updatedProfitMargin = (profitMargin + (profitMargin * 0.10)).toInt();
                          final updatedCostOfOperations = (costOfOperations + (costOfOperations * 0.05)).toInt();
                          final updatedCustomerLoyalty = (customerLoyalty + (customerLoyalty * 0.20)).toInt();
                          final updatedType = 'd';

                          await FirebaseDatabase.instance.ref('gameMechanics/$userId/').update({
                            'sales': updatedSales,
                            'profit_margin': updatedProfitMargin,
                            'cost_of_operations': updatedCostOfOperations,
                            'customer_loyalty': updatedCustomerLoyalty,
                            'type': updatedType,
                          });

                          if (!mounted) return; Navigator.push(context,
                            MaterialPageRoute(builder: (context) => Frame12d1()),
                          );
                        },
                      ),
                    ),
                ],
              ),
            ],
          ),


          // Menu Drawer
          ),
          EntertainmentMenuDrawer(),
        ],
      ),
    );
  }
}

