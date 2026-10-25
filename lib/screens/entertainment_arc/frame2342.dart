import 'dart:io';

import 'package:Marketing_Fruit/components/entertainment_menu_drawer.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:Marketing_Fruit/components/player_details.dart';
import 'package:Marketing_Fruit/screens/entertainment_arc/frame2343.dart';
import '../../components/answer_bubble.dart';
import '../../components/text_bubble.dart';

class Frame2342 extends StatefulWidget {
  const Frame2342({super.key});

  @override
  State<Frame2342> createState() => _Frame2342State();
}

class _Frame2342State extends State<Frame2342> {
  final playerDetails = PlayerDetails();

  @override
  void initState() {
    super.initState();
    playerDetails.saveProgress('frame2342', null);
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
          // Julian Kelly Cartoon - Responsive Position (commented out)
          Positioned(
            bottom: isMobile ? screenHeight * 0.45 : screenHeight * 0.38,
            left: screenWidth * 0.05,
            right: screenWidth * 0.05,
            child: TextBubble(
              message:
              "Your revenue streams are stable but highly dependent on platform deals or ads. Now it is time to explore new monetization models to increase margins.",
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
                    AnswerBubble(
                      label: 'Offer exclusive behind-the-scenes\ncontent via subscription tier',
                      onTap: () async {
                        final snapshot = await FirebaseDatabase.instance.ref('gameMechanics/$userId/').get();
                        final sales = int.tryParse(snapshot.child('sales').value.toString()) ?? 0;
                        final profitMargin = int.tryParse(snapshot.child('profit_margin').value.toString()) ?? 0;
                        final costOfOperations = int.tryParse(snapshot.child('cost_of_operations').value.toString()) ?? 0;
                        final customerLoyalty = int.tryParse(snapshot.child('customer_loyalty').value.toString()) ?? 0;

                        final updatedSales = (sales + (sales * 0.08)).toInt();
                        final updatedProfitMargin = (profitMargin + (profitMargin * 0.05)).toInt();
                        final updatedCostOfOperations = (costOfOperations + (costOfOperations * 0.03)).toInt();
                        final updatedCustomerLoyalty = (customerLoyalty + (customerLoyalty * 0.06)).toInt();

                        await FirebaseDatabase.instance.ref('gameMechanics/$userId/').update({
                          'sales': updatedSales,
                          'profit_margin': updatedProfitMargin,
                          'cost_of_operations': updatedCostOfOperations,
                          'customer_loyalty': updatedCustomerLoyalty,
                        });

                        if (!mounted) return; Navigator.push(context, MaterialPageRoute(builder: (context) => Frame2343()));
                      },
                    ),
                    SizedBox(width: screenWidth * 0.10),
                    AnswerBubble(
                      label: 'Introduce branded content\nand product placements',
                      onTap: () async {
                        final snapshot = await FirebaseDatabase.instance.ref('gameMechanics/$userId/').get();
                        final sales = int.tryParse(snapshot.child('sales').value.toString()) ?? 0;
                        final profitMargin = int.tryParse(snapshot.child('profit_margin').value.toString()) ?? 0;
                        final costOfOperations = int.tryParse(snapshot.child('cost_of_operations').value.toString()) ?? 0;
                        final customerLoyalty = int.tryParse(snapshot.child('customer_loyalty').value.toString()) ?? 0;

                        final updatedSales = (sales + (sales * 0.1)).toInt();
                        final updatedProfitMargin = (profitMargin + (profitMargin * 0.04)).toInt();
                        final updatedCostOfOperations = costOfOperations; // No change
                        final updatedCustomerLoyalty = (customerLoyalty - (customerLoyalty * 0.04)).toInt();

                        await FirebaseDatabase.instance.ref('gameMechanics/$userId/').update({
                          'sales': updatedSales,
                          'profit_margin': updatedProfitMargin,
                          'cost_of_operations': updatedCostOfOperations,
                          'customer_loyalty': updatedCustomerLoyalty,
                        });
                        if (!mounted) return; Navigator.push(context, MaterialPageRoute(builder: (context) => Frame2343()));
                      },
                    ),
                  ],
                ),
                SizedBox(height: isMobile ? screenWidth * 0.01 : screenWidth * 0.03),
                Row(
                  children: [
                    AnswerBubble(
                      label: 'Host paid virtual\npremieres and creator AMAs',
                      onTap: () async {
                        final snapshot = await FirebaseDatabase.instance.ref('gameMechanics/$userId/').get();
                        final sales = int.tryParse(snapshot.child('sales').value.toString()) ?? 0;
                        final profitMargin = int.tryParse(snapshot.child('profit_margin').value.toString()) ?? 0;
                        final costOfOperations = int.tryParse(snapshot.child('cost_of_operations').value.toString()) ?? 0;
                        final customerLoyalty = int.tryParse(snapshot.child('customer_loyalty').value.toString()) ?? 0;

                        final updatedSales = (sales + (sales * 0.06)).toInt();
                        final updatedProfitMargin = (profitMargin + (profitMargin * 0.03)).toInt();
                        final updatedCostOfOperations = (costOfOperations + (costOfOperations * 0.02)).toInt();
                        final updatedCustomerLoyalty = (customerLoyalty + (customerLoyalty * 0.05)).toInt();

                        await FirebaseDatabase.instance.ref('gameMechanics/$userId/').update({
                          'sales': updatedSales,
                          'profit_margin': updatedProfitMargin,
                          'cost_of_operations': updatedCostOfOperations,
                          'customer_loyalty': updatedCustomerLoyalty,
                        });
                        if (!mounted) return; Navigator.push(context, MaterialPageRoute(builder: (context) => Frame2343()));
                      },
                    ),
                    SizedBox(width: screenWidth * 0.10),
                    AnswerBubble(
                      label: 'License your content to\nregional OTT platforms',
                      onTap: () async {
                        final snapshot = await FirebaseDatabase.instance.ref('gameMechanics/$userId/').get();
                        final sales = int.tryParse(snapshot.child('sales').value.toString()) ?? 0;
                        final profitMargin = int.tryParse(snapshot.child('profit_margin').value.toString()) ?? 0;
                        final costOfOperations = int.tryParse(snapshot.child('cost_of_operations').value.toString()) ?? 0;
                        final customerLoyalty = int.tryParse(snapshot.child('customer_loyalty').value.toString()) ?? 0;

                        final updatedSales = (sales + (sales * 0.12)).toInt();
                        final updatedProfitMargin = (profitMargin + (profitMargin * 0.03)).toInt();
                        final updatedCostOfOperations = (costOfOperations - (costOfOperations * 0.01)).toInt();
                        final updatedCustomerLoyalty = (customerLoyalty + (customerLoyalty * 0.01)).toInt();

                        await FirebaseDatabase.instance.ref('gameMechanics/$userId/').update({
                          'sales': updatedSales,
                          'profit_margin': updatedProfitMargin,
                          'cost_of_operations': updatedCostOfOperations,
                          'customer_loyalty': updatedCustomerLoyalty,
                        });
                        if (!mounted) return; Navigator.push(context, MaterialPageRoute(builder: (context) => Frame2343()));
                      },
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
