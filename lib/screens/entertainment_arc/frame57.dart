import 'dart:io';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:Marketing_Fruit/components/player_details.dart';
import 'package:Marketing_Fruit/screens/entertainment_arc/frame57b1.dart';
import '../../components/answer_bubble.dart';
import '../../components/text_bubble.dart';
import '../../components/entertainment_menu_drawer.dart';
import 'frame57a1.dart';
import 'frame57c1.dart';
import 'frame57d1.dart';

class Frame57 extends StatefulWidget {
  final bool isDisabled;
  const Frame57({super.key, this.isDisabled = false});

  @override
  State<Frame57> createState() => _Frame57State();
}

class _Frame57State extends State<Frame57> {
  final playerDetails = PlayerDetails();

  @override
  void initState() {
    super.initState();
    playerDetails.saveProgress('frame57', null);
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
          // Background Image
          SizedBox.expand(
            child: Image.asset(
              'assets/EA3.png',
              fit: BoxFit.cover,
            ),
          ),
          // Julian Kelly Cartoon - Responsive Position
          Positioned(
            bottom: screenHeight * 0.07,
            left: screenWidth * 0.05,
            child: Image.asset(
              'assets/julian_kelly.png',
              height: screenHeight * 0.80,
            ),
          ),
          // Text Bubble - Responsive Position and Width
          Positioned(
            bottom: isMobile ? screenHeight * 0.45 : screenHeight * 0.38,
            left: screenWidth * 0.05,
            right: screenWidth * 0.05,
            child: TextBubble(
              message:
              "Now that we have secured our funds, lets create a strong team to create high-quality content. How do you approach hiring?",
            ),
          ),
          Positioned(
            bottom: screenHeight * 0.07,
            left: screenWidth * 0.25,
            child: Column(
              children: [
                Row(
                  children: [
                    AnswerBubble(
                      label: 'Hire experienced\nindustry professionals',
                      onTap: () async {
                        final snapshot = await FirebaseDatabase.instance
                            .ref('gameMechanics/$userId/')
                            .get();

                        final sales = int.tryParse(snapshot.child('sales').value.toString()) ?? 0;
                        final profitMargin = int.tryParse(snapshot.child('profit_margin').value.toString()) ?? 0;
                        final costOfOperations = int.tryParse(snapshot.child('cost_of_operations').value.toString()) ?? 0;
                        final customerLoyalty = int.tryParse(snapshot.child('customer_loyalty').value.toString()) ?? 0;

                        final updatedSales = (sales + (sales * 0.15)).toInt();
                        final updatedProfitMargin = (profitMargin - (profitMargin * 0.10)).toInt();
                        final updatedCostOfOperations = (costOfOperations + (costOfOperations * 0.10)).toInt();
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
                            builder: (context) => Frame57a1(),
                          ),
                        );
                      },
                    ),
                    SizedBox(width: screenWidth * 0.10),
                    AnswerBubble(
                      label: 'Recruit fresh talent\nand freelancers',
                      onTap: () async {
                        final snapshot = await FirebaseDatabase.instance
                            .ref('gameMechanics/$userId/')
                            .get();

                        final sales = int.tryParse(snapshot.child('sales').value.toString()) ?? 0;
                        final profitMargin = int.tryParse(snapshot.child('profit_margin').value.toString()) ?? 0;
                        final costOfOperations = int.tryParse(snapshot.child('cost_of_operations').value.toString()) ?? 0;
                        final customerLoyalty = int.tryParse(snapshot.child('customer_loyalty').value.toString()) ?? 0;

                        final updatedSales = (sales + (sales * 0.05)).toInt();
                        final updatedProfitMargin = (profitMargin + (profitMargin * 0.10)).toInt();
                        final updatedCostOfOperations = (costOfOperations - (costOfOperations * 0.05)).toInt();
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
                            builder: (context) => Frame57b1(),
                          ),
                        );
                      },
                    ),
                  ],
                ),
                SizedBox(height: isMobile ? screenWidth * 0.01 : screenWidth * 0.03),
                Row(
                  children: [
                    AnswerBubble(
                      label: 'Use AI-driven content\ngeneration tools',
                      isDisabled: widget.isDisabled,
                      onTap: () async {
                        if (!widget.isDisabled) {
                          final snapshot = await FirebaseDatabase.instance
                              .ref('gameMechanics/$userId/')
                              .get();

                          final sales = int.tryParse(snapshot.child('sales').value.toString()) ?? 0;
                          final profitMargin = int.tryParse(snapshot.child('profit_margin').value.toString()) ?? 0;
                          final costOfOperations = int.tryParse(snapshot.child('cost_of_operations').value.toString()) ?? 0;
                          final customerLoyalty = int.tryParse(snapshot.child('customer_loyalty').value.toString()) ?? 0;

                          final updatedSales = (sales - (sales * 0.05)).toInt();
                          final updatedProfitMargin = (profitMargin + (profitMargin * 0.20)).toInt();
                          final updatedCostOfOperations = (costOfOperations - (costOfOperations * 0.10)).toInt();
                          final updatedCustomerLoyalty = (customerLoyalty - (customerLoyalty * 0.10)).toInt();

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
                              builder: (context) => Frame57c1(),
                            ),
                          );
                        }
                      },
                    ),
                    SizedBox(width: screenWidth * 0.10),
                    AnswerBubble(
                      label: 'Work with influencers\nand content creators',
                      onTap: () async {
                        final snapshot = await FirebaseDatabase.instance
                            .ref('gameMechanics/$userId/')
                            .get();

                        final sales = int.tryParse(snapshot.child('sales').value.toString()) ?? 0;
                        final profitMargin = int.tryParse(snapshot.child('profit_margin').value.toString()) ?? 0;
                        final costOfOperations = int.tryParse(snapshot.child('cost_of_operations').value.toString()) ?? 0;
                        final customerLoyalty = int.tryParse(snapshot.child('customer_loyalty').value.toString()) ?? 0;

                        final updatedSales = (sales + (sales * 0.10)).toInt();
                        final updatedProfitMargin = (profitMargin + (profitMargin * 0.05)).toInt();
                        final updatedCostOfOperations = (costOfOperations + (costOfOperations * 0.10)).toInt();
                        final updatedCustomerLoyalty = (customerLoyalty + (customerLoyalty * 0.15)).toInt();

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
                            builder: (context) => Frame57d1(),
                          ),
                        );
                      },
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
