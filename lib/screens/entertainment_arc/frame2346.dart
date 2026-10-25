import 'dart:io';

import 'package:Marketing_Fruit/components/entertainment_menu_drawer.dart';
import 'package:Marketing_Fruit/screens/dashboard/main_layout.dart';
import 'package:Marketing_Fruit/screens/entertainment_arc/frame11.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:Marketing_Fruit/components/player_details.dart';
import 'package:Marketing_Fruit/screens/entertainment_arc/frame2345d.dart';
import '../../components/answer_bubble.dart';
import '../../components/text_bubble.dart';
import 'frame2346a.dart';
import 'frame2346b.dart';
import 'frame2346c.dart';

class Frame2346 extends StatefulWidget {
  final String? background;
  const Frame2346({super.key, this.background});

  @override
  State<Frame2346> createState() => _Frame2346State();
}

class _Frame2346State extends State<Frame2346> {
  String role = '';
  final playerDetails = PlayerDetails();

  @override
  void initState() {
    super.initState();
    fetchRole();
    playerDetails.saveProgress('frame2346', null);
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
                            userRole: role,
                            nftindex: 2,
                            fs: true,
                            sId: 4)),
                  );
                },
                child: MessageBubbleWithImage(
                  imageAsset: 'assets/messagebubble.png',
                  text:
                  "Hey user, now you have reached the point in your business where the only way ahead is strategic growth and innovation. Take the respective course to ensure that you know all its concepts and applications \n Go to the course",
                  textStyle: const TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.black,
                    fontSize: 18,
                  ),
                  maxWidth: screenWidth * 0.3,
                  padding:
                  const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
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
              "The COVID-19 is at its peak. Lockdowns, travel bans, no international flights, and the situation is just getting worse. Operation cost is piling up and there is no revenue source. How you want to stir your business?",
            ),
          ),
          Positioned(
            bottom: screenHeight * 0.07,
            left: screenWidth * 0.25,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: AnswerBubble(
                        label: 'Shift to Animation & Remote-Produced Content',
                        onTap: () async {
                          final snapshot = await FirebaseDatabase.instance
                              .ref('gameMechanics/$userId/')
                              .get();
                          final sales =
                              int.tryParse(snapshot.child('sales').value.toString()) ??
                                  0;
                          final profitMargin =
                              int.tryParse(snapshot.child('profit_margin').value.toString()) ??
                                  0;
                          final costOfOperations =
                              int.tryParse(snapshot.child('cost_of_operations').value.toString()) ??
                                  0;
                          final customerLoyalty =
                              int.tryParse(snapshot.child('customer_loyalty').value.toString()) ??
                                  0;

                          final updatedSales = (sales - (sales * 0.05)).toInt();
                          final updatedProfitMargin = (profitMargin - (profitMargin * 0.10)).toInt();
                          final updatedCostOfOperations = (costOfOperations + (costOfOperations * 0.07)).toInt();
                          final updatedCustomerLoyalty = (customerLoyalty + (customerLoyalty * 0.08)).toInt();

                          await FirebaseDatabase.instance
                              .ref('gameMechanics/$userId/')
                              .update({
                            'sales': updatedSales,
                            'profit_margin': updatedProfitMargin,
                            'cost_of_operations': updatedCostOfOperations,
                            'customer_loyalty': updatedCustomerLoyalty,
                          });

                          if (!mounted) return; Navigator.push(context,
                            MaterialPageRoute(
                                builder: (context) => Frame2346a()),
                          );
                        },
                      ),
                    ),
                    SizedBox(width: screenWidth * 0.06),
                    Expanded(
                      child: AnswerBubble(
                        label: 'Double Down on Short-Form User-Generated Content',
                        onTap: () async {
                          final snapshot = await FirebaseDatabase.instance
                              .ref('gameMechanics/$userId/')
                              .get();
                          final sales =
                              int.tryParse(snapshot.child('sales').value.toString()) ??
                                  0;
                          final profitMargin =
                              int.tryParse(snapshot.child('profit_margin').value.toString()) ??
                                  0;
                          final costOfOperations =
                              int.tryParse(snapshot.child('cost_of_operations').value.toString()) ??
                                  0;
                          final customerLoyalty =
                              int.tryParse(snapshot.child('customer_loyalty').value.toString()) ??
                                  0;

                          final updatedSales = (sales - (sales * 0.02)).toInt();
                          final updatedProfitMargin = (profitMargin - (profitMargin * 0.05)).toInt();
                          final updatedCostOfOperations = (costOfOperations + (costOfOperations * 0.03)).toInt();
                          final updatedCustomerLoyalty = customerLoyalty;

                          await FirebaseDatabase.instance
                              .ref('gameMechanics/$userId/')
                              .update({
                            'sales': updatedSales,
                            'profit_margin': updatedProfitMargin,
                            'cost_of_operations': updatedCostOfOperations,
                            'customer_loyalty': updatedCustomerLoyalty,
                          });

                          if (!mounted) return; Navigator.push(context,
                            MaterialPageRoute(
                                builder: (context) => Frame2346b()),
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
                        label: 'Pause Operations and Conserve Cash',
                        onTap: () async {
                          final snapshot = await FirebaseDatabase.instance
                              .ref('gameMechanics/$userId/')
                              .get();
                          final sales =
                              int.tryParse(snapshot.child('sales').value.toString()) ??
                                  0;
                          final profitMargin =
                              int.tryParse(snapshot.child('profit_margin').value.toString()) ??
                                  0;
                          final costOfOperations =
                              int.tryParse(snapshot.child('cost_of_operations').value.toString()) ??
                                  0;
                          final customerLoyalty =
                              int.tryParse(snapshot.child('customer_loyalty').value.toString()) ??
                                  0;

                          final updatedSales = (sales - (sales * 0.10)).toInt();
                          final updatedProfitMargin = (profitMargin - (profitMargin * 0.08)).toInt();
                          final updatedCostOfOperations = (costOfOperations + (costOfOperations * 0.04)).toInt();
                          final updatedCustomerLoyalty = (customerLoyalty - (customerLoyalty * 0.02)).toInt();

                          await FirebaseDatabase.instance
                              .ref('gameMechanics/$userId/')
                              .update({
                            'sales': updatedSales,
                            'profit_margin': updatedProfitMargin,
                            'cost_of_operations': updatedCostOfOperations,
                            'customer_loyalty': updatedCustomerLoyalty,
                          });

                          if (!mounted) return; Navigator.push(context,
                            MaterialPageRoute(
                                builder: (context) => Frame2346c()),
                          );
                        },
                      ),
                    ),
                    SizedBox(width: screenWidth * 0.06),
                    Expanded(
                      child: AnswerBubble(
                        label: 'Launch Virtual Content Lab for Global Collaboration',
                        onTap: () async {
                          final snapshot = await FirebaseDatabase.instance
                              .ref('gameMechanics/$userId/')
                              .get();
                          final sales =
                              int.tryParse(snapshot.child('sales').value.toString()) ??
                                  0;
                          final profitMargin =
                              int.tryParse(snapshot.child('profit_margin').value.toString()) ??
                                  0;
                          final costOfOperations =
                              int.tryParse(snapshot.child('cost_of_operations').value.toString()) ??
                                  0;
                          final customerLoyalty =
                              int.tryParse(snapshot.child('customer_loyalty').value.toString()) ??
                                  0;

                          final updatedSales = (sales + (sales * 0.04)).toInt();
                          final updatedProfitMargin = (profitMargin - (profitMargin * 0.03)).toInt();
                          final updatedCostOfOperations = (costOfOperations + (costOfOperations * 0.02)).toInt();
                          final updatedCustomerLoyalty = (customerLoyalty + (customerLoyalty * 0.05)).toInt();

                          await FirebaseDatabase.instance
                              .ref('gameMechanics/$userId/')
                              .update({
                            'sales': updatedSales,
                            'profit_margin': updatedProfitMargin,
                            'cost_of_operations': updatedCostOfOperations,
                            'customer_loyalty': updatedCustomerLoyalty,
                          });

                          if (!mounted) return; Navigator.push(context,
                            MaterialPageRoute(
                                builder: (context) => Frame2345d()),
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          EntertainmentMenuDrawer()
        ],
      ),
    );
  }
}
