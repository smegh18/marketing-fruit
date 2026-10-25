import 'dart:io';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:Marketing_Fruit/components/player_details.dart';
import 'package:Marketing_Fruit/screens/entertainment_arc/frame19b1.dart';
import '../../components/answer_bubble.dart';
import '../../components/text_bubble.dart';
import '../../components/entertainment_menu_drawer.dart';
import 'frame19ad.dart';
import 'frame19c1.dart';

class Frame19 extends StatefulWidget {
  const Frame19({super.key});

  @override
  State<Frame19> createState() => _Frame19State();
}

class _Frame19State extends State<Frame19> {
  final playerDetails = PlayerDetails();

  @override
  void initState() {
    super.initState();
    // Save progress when entering this frame
    playerDetails.saveProgress('frame19', null);
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
            bottom: isMobile ? screenHeight * 0.45 : screenHeight * 0.38, // 23% from bottom
            left: screenWidth * 0.05,
            right: screenWidth * 0.05,
            child: TextBubble(
              message:
              "Good choice, You have your first production ready, but where will you distribute it?",
            ),
          ),


          Positioned(
              bottom: screenHeight * 0.07,
              left: screenWidth * 0.25 , // Center the button (200 width / 2)
              child: Column(
                  spacing: isMobile ? screenWidth * 0.01 : screenWidth * 0.03,
                  children: [
                    Row(
                      spacing: screenWidth * 0.10,
                      children: [
                        AnswerBubble(
                          label: 'Sell distribution rights to\na major streaming service',
                          onTap: () async {
                            final snapshot = await FirebaseDatabase.instance
                                .ref('gameMechanics/$userId/')
                                .get();

                            final sales = int.tryParse(snapshot.child('sales').value.toString()) ?? 0;
                            final profitMargin = int.tryParse(snapshot.child('profit_margin').value.toString()) ?? 0;
                            final costOfOperations = int.tryParse(snapshot.child('cost_of_operations').value.toString()) ?? 0;
                            final customerLoyalty = int.tryParse(snapshot.child('customer_loyalty').value.toString()) ?? 0;
                            final type = snapshot.child('type').value.toString();

                            final updatedSales = (sales + (sales * 0.20)).toInt(); // increase sales by 15%
                            final updatedProfitMargin = (profitMargin + (profitMargin * 0.10)).toInt(); // increase profit margin by 15%
                            final updatedCostOfOperations = (costOfOperations + (costOfOperations * 0.05)).toInt(); // increase cost of operations by 15%
                            final updatedCustomerLoyalty = (customerLoyalty - (customerLoyalty * 0.05)).toInt();

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
                                builder: (context) => Frame19ad(frame: 'a',),
                              ),
                            );
                          },
                        ),
                        AnswerBubble(
                          label: 'Launch your own digital\nstreaming platform',
                          onTap: () async {
                            final snapshot = await FirebaseDatabase.instance
                                .ref('gameMechanics/$userId/')
                                .get();

                            final sales = int.tryParse(snapshot.child('sales').value.toString()) ?? 0;
                            final profitMargin = int.tryParse(snapshot.child('profit_margin').value.toString()) ?? 0;
                            final costOfOperations = int.tryParse(snapshot.child('cost_of_operations').value.toString()) ?? 0;
                            final customerLoyalty = int.tryParse(snapshot.child('customer_loyalty').value.toString()) ?? 0;

                            final updatedSales = (sales - (sales * 0.05)).toInt(); // increase sales by 15%
                            final updatedProfitMargin = (profitMargin - (profitMargin * 0.10)).toInt(); // increase profit margin by 15%
                            final updatedCostOfOperations = (costOfOperations + (costOfOperations * 0.20)).toInt(); // increase cost of operations by 15%
                            final updatedCustomerLoyalty = (customerLoyalty + (customerLoyalty * 0.20)).toInt();

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
                                builder: (context) => Frame19b1(),
                              ),
                            );
                          },
                        ),
                      ],
                    ),
                    Row(
                      spacing: screenWidth * 0.10,
                      children: [
                        AnswerBubble(
                          label: 'Release content for free on\nYouTube and monetize via ads',
                          onTap: () async {
                            final snapshot = await FirebaseDatabase.instance
                                .ref('gameMechanics/$userId/')
                                .get();

                            final sales = int.tryParse(snapshot.child('sales').value.toString()) ?? 0;
                            final profitMargin = int.tryParse(snapshot.child('profit_margin').value.toString()) ?? 0;
                            final costOfOperations = int.tryParse(snapshot.child('cost_of_operations').value.toString()) ?? 0;
                            final customerLoyalty = int.tryParse(snapshot.child('customer_loyalty').value.toString()) ?? 0;

                            final updatedSales = (sales + (sales * 0.05)).toInt(); // increase sales by 15%
                            final updatedProfitMargin = (profitMargin + (profitMargin * 0.05)).toInt(); // increase profit margin by 15%
                            final updatedCostOfOperations = (costOfOperations - (costOfOperations * 0.10)).toInt(); // increase cost of operations by 15%
                            final updatedCustomerLoyalty = (customerLoyalty + (customerLoyalty * 0.10)).toInt();

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
                                builder: (context) => Frame19c1(),
                              ),
                            );
                          },
                        ),
                        AnswerBubble(
                          label: 'Sell content directly\nto TV networks',
                          onTap: () async {
                            final snapshot = await FirebaseDatabase.instance
                                .ref('gameMechanics/$userId/')
                                .get();

                            final sales = int.tryParse(snapshot.child('sales').value.toString()) ?? 0;
                            final profitMargin = int.tryParse(snapshot.child('profit_margin').value.toString()) ?? 0;
                            final costOfOperations = int.tryParse(snapshot.child('cost_of_operations').value.toString()) ?? 0;
                            final customerLoyalty = int.tryParse(snapshot.child('customer_loyalty').value.toString()) ?? 0;

                            final updatedSales = (sales + (sales * 0.15)).toInt(); // increase sales by 15%
                            final updatedProfitMargin = (profitMargin + (profitMargin * 0.05)).toInt(); // increase profit margin by 15%
                            final updatedCostOfOperations = (costOfOperations + (costOfOperations * 0.10)).toInt(); // increase cost of operations by 15%
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
                                builder: (context) => Frame19ad(frame: 'd',),
                              ),
                            );
                          },
                        ),
                      ],
                    )
                  ]
              )),

          // Row(
          //   children: [
          //     Positioned(
          //       bottom: screenHeight * 0.05,
          //       left: screenWidth * 0.5 - 200, // Center the button (200 width / 2)
          //       child: AnswerBubble(
          //         label: 'Male',
          //         onTap: () {
          //           Navigator.push(
          //             context,
          //             MaterialPageRoute(
          //               builder: (context) => Frame1(),
          //             ),
          //           );
          //         },
          //       ),
          //     ),
          // Positioned(
          //   bottom: screenHeight * 0.05,
          //   left: screenWidth * 0.5 - 200, // Center the button (200 width / 2)
          //   child: AnswerBubble(
          //     label: 'Female',
          //     onTap: () {
          //       Navigator.push(
          //         context,
          //         MaterialPageRoute(
          //           builder: (context) => Frame1(),
          //         ),
          //       );
          //     },
          //   ),
          // ),
          // Positioned(
          //   bottom: screenHeight * 0.05,
          //   left: screenWidth * 0.5 - 100, // Center the button (200 width / 2)
          //   child: AnswerBubble(
          //     label: 'Not to disclose',
          //     onTap: () {
          //       Navigator.push(
          //         context,
          //         MaterialPageRoute(
          //           builder: (context) => Frame1(),
          //         ),
          //       );
          //     },
          //   ),
          // )
          //   ],
          // )


          // Positioned(
          //   bottom: screenSize.height * 0.05,
          //   right: screenSize.width * 0.05,
          //   child: GestureDetector(
          //     onTap: () {
          //       Navigator.push(
          //         context,
          //         MaterialPageRoute(
          //           builder: (context) => Frame2(),
          //         ),
          //       );
          //     },
          //     child: Image.asset(
          //       'assets/next_Button.png', // Make sure this matches the file name
          //       height: screenSize.height * 0.08,
          //     ),
          //   ),
          // ),

          // Menu Drawer
          const EntertainmentMenuDrawer(),
        ],
      ),
    );
  }
}
