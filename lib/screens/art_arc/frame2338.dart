import 'dart:io';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:Marketing_Fruit/components/player_details.dart';
import 'package:Marketing_Fruit/screens/art_arc/frame2338a.dart';
import 'package:Marketing_Fruit/screens/art_arc/frame2338b.dart';
import 'package:Marketing_Fruit/screens/art_arc/frame2338c.dart';
import 'package:Marketing_Fruit/screens/art_arc/frame2338d.dart';
import '../../components/answer_bubble.dart';
import '../../components/text_bubble.dart';
// import 'frame12a1.dart';
// import 'frame12b1.dart';
// import 'frame12c1.dart';
// import 'frame12d1.dart';
// import 'frame53.dart';
// import 'frame54a1.dart';
// import 'frame77.dart';

class Frame2338 extends StatelessWidget {
  const Frame2338({super.key});


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
              'assets/AA4.png',
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
              "How would you like to promote your platform",
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
                          label: 'Influencer Collaboration\n for Viral Content ',
                          onTap: () async {
                            final snapshot = await FirebaseDatabase.instance
                                .ref('gameMechanics/$userId/')
                                .get();

                            final sales = int.tryParse(snapshot.child('sales').value.toString()) ?? 0;
                            final profitMargin = int.tryParse(snapshot.child('profit_margin').value.toString()) ?? 0;
                            final costOfOperations = int.tryParse(snapshot.child('cost_of_operations').value.toString()) ?? 0;
                            final customerLoyalty = int.tryParse(snapshot.child('customer_loyalty').value.toString()) ?? 0;

                            final updatedSales = (sales + (sales * 0.08)).toInt(); // increase sales by 15%
                            final updatedProfitMargin = (profitMargin - (profitMargin * 0.05)).toInt(); // increase profit margin by 15%
                            final updatedCostOfOperations = (costOfOperations + (costOfOperations * 0.10)).toInt(); // increase cost of operations by 15%
                            final updatedCustomerLoyalty = (customerLoyalty + (customerLoyalty * 0.12)).toInt();

                            await FirebaseDatabase.instance
                                .ref('gameMechanics/$userId/')
                                .update({
                              'sales': updatedSales,
                              'profit_margin': updatedProfitMargin,
                              'cost_of_operations': updatedCostOfOperations,
                              'customer_loyalty': updatedCustomerLoyalty,
                            });

                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => Frame2338a(),
                              ),
                            );
                          },
                        ),
                        AnswerBubble(
                          label: 'Paid Advertising \n Campaign',
                          onTap: () async {
                            final snapshot = await FirebaseDatabase.instance
                                .ref('gameMechanics/$userId/')
                                .get();

                            final sales = int.tryParse(snapshot.child('sales').value.toString()) ?? 0;
                            final profitMargin = int.tryParse(snapshot.child('profit_margin').value.toString()) ?? 0;
                            final costOfOperations = int.tryParse(snapshot.child('cost_of_operations').value.toString()) ?? 0;
                            final customerLoyalty = int.tryParse(snapshot.child('customer_loyalty').value.toString()) ?? 0;

                            final updatedSales = (sales + (sales * 0.02)).toInt(); // increase sales by 15%
                            final updatedProfitMargin = (profitMargin + (profitMargin * 0.05)).toInt(); // increase profit margin by 15%
                            final updatedCostOfOperations = (costOfOperations - (costOfOperations * 0.03)).toInt(); // increase cost of operations by 15%
                            final updatedCustomerLoyalty = (customerLoyalty + (customerLoyalty * 0.05)).toInt();

                            await FirebaseDatabase.instance
                                .ref('gameMechanics/$userId/')
                                .update({
                              'sales': updatedSales,
                              'profit_margin': updatedProfitMargin,
                              'cost_of_operations': updatedCostOfOperations,
                              'customer_loyalty': updatedCustomerLoyalty,
                            });
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => Frame2338b(),
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
                          label: 'Collaborate with \n Local Schools, Artists & Coomunitites ',
                          onTap: () async {
                            final snapshot = await FirebaseDatabase.instance
                                .ref('gameMechanics/$userId/')
                                .get();

                            final sales = int.tryParse(snapshot.child('sales').value.toString()) ?? 0;
                            final profitMargin = int.tryParse(snapshot.child('profit_margin').value.toString()) ?? 0;
                            final costOfOperations = int.tryParse(snapshot.child('cost_of_operations').value.toString()) ?? 0;
                            final customerLoyalty = int.tryParse(snapshot.child('customer_loyalty').value.toString()) ?? 0;

                            final updatedSales = (sales + (sales * 0.06)).toInt(); // increase sales by 15%
                            final updatedProfitMargin = (profitMargin - (profitMargin * 0.02)).toInt(); // increase profit margin by 15%
                            final updatedCostOfOperations = (costOfOperations + (costOfOperations * 0.05)).toInt(); // increase cost of operations by 15%
                            final updatedCustomerLoyalty = (customerLoyalty + (customerLoyalty * 0.07)).toInt();

                            await FirebaseDatabase.instance
                                .ref('gameMechanics/$userId/')
                                .update({
                              'sales': updatedSales,
                              'profit_margin': updatedProfitMargin,
                              'cost_of_operations': updatedCostOfOperations,
                              'customer_loyalty': updatedCustomerLoyalty,
                            });
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => Frame2338c(),
                              ),
                            );
                          },
                        ),
                        AnswerBubble(
                          label: 'Rely on Organic \n Word-of-Mouthc ',
                          onTap: () async {
                            final snapshot = await FirebaseDatabase.instance
                                .ref('gameMechanics/$userId/')
                                .get();

                            final sales = int.tryParse(snapshot.child('sales').value.toString()) ?? 0;
                            final profitMargin = int.tryParse(snapshot.child('profit_margin').value.toString()) ?? 0;
                            final costOfOperations = int.tryParse(snapshot.child('cost_of_operations').value.toString()) ?? 0;
                            final customerLoyalty = int.tryParse(snapshot.child('customer_loyalty').value.toString()) ?? 0;

                            final updatedSales = (sales + (sales * 0.1)).toInt(); // increase sales by 15%
                            final updatedProfitMargin = (profitMargin + (profitMargin * 0.03)).toInt(); // increase profit margin by 15%
                            final updatedCostOfOperations = (costOfOperations - (costOfOperations * 0.02)).toInt(); // increase cost of operations by 15%
                            final updatedCustomerLoyalty = (customerLoyalty + (customerLoyalty * 0.03)).toInt();

                            await FirebaseDatabase.instance
                                .ref('gameMechanics/$userId/')
                                .update({
                              'sales': updatedSales,
                              'profit_margin': updatedProfitMargin,
                              'cost_of_operations': updatedCostOfOperations,
                              'customer_loyalty': updatedCustomerLoyalty,
                            });
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => Frame2338d(),
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
        ],
      ),
    );
  }
}
