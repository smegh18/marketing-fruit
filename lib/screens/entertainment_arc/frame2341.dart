import 'dart:io';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:Marketing_Fruit/components/player_details.dart';
import 'package:Marketing_Fruit/screens/entertainment_arc/frame2342.dart';
import '../../components/answer_bubble.dart';
import '../../components/entertainment_menu_drawer.dart';
import '../../components/text_bubble.dart';

class Frame2341 extends StatefulWidget {
  const Frame2341({super.key});

  @override
  State<Frame2341> createState() => _Frame2341State();
}

class _Frame2341State extends State<Frame2341> {
  String? companyName;
  String userId = FirebaseAuth.instance.currentUser!.uid;
  final playerDetails = PlayerDetails();

  @override
  void initState() {
    super.initState();
    _loadCompanyName();
    playerDetails.saveProgress('frame2341', null);
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
    final playerDetails = PlayerDetails();
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
          // Positioned(...),
          Positioned(
            bottom: isMobile ? screenHeight * 0.45 : screenHeight * 0.38,
            left: screenWidth * 0.05,
            right: screenWidth * 0.05,
            child: TextBubble(
              message:
              "Now that you have setup your “$companyName” You're suddenly juggling multiple productions across locations. The strain on your original team is showing. You need fresh talent, but speed and alignment are crucial.",
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
                      label: 'Hire in-house department\nheads for each new unit',
                      onTap: () async {
                        final snapshot = await FirebaseDatabase.instance
                            .ref('gameMechanics/$userId/')
                            .get();

                        final sales = int.tryParse(snapshot.child('sales').value.toString()) ?? 0;
                        final profitMargin = int.tryParse(snapshot.child('profit_margin').value.toString()) ?? 0;
                        final costOfOperations = int.tryParse(snapshot.child('cost_of_operations').value.toString()) ?? 0;
                        final customerLoyalty = int.tryParse(snapshot.child('customer_loyalty').value.toString()) ?? 0;

                        final updatedSales = (sales + (sales * 0.05)).toInt();
                        final updatedProfitMargin = (profitMargin - (profitMargin * 0.05)).toInt();
                        final updatedCostOfOperations = (costOfOperations + (costOfOperations * 0.15)).toInt();
                        final updatedCustomerLoyalty = (customerLoyalty - (customerLoyalty * 0.08)).toInt();

                        await FirebaseDatabase.instance
                            .ref('gameMechanics/$userId/')
                            .update({
                          'sales': updatedSales,
                          'profit_margin': updatedProfitMargin,
                          'cost_of_operations': updatedCostOfOperations,
                          'customer_loyalty': updatedCustomerLoyalty,
                        });

                        if (!mounted) return; Navigator.push(context,
                          MaterialPageRoute(builder: (context) => Frame2342()),
                        );
                      },
                    ),
                    SizedBox(width: screenWidth * 0.10),
                    AnswerBubble(
                      label: 'Outsource to specialized\nproduction vendors',
                      onTap: () async {
                        final snapshot = await FirebaseDatabase.instance
                            .ref('gameMechanics/$userId/')
                            .get();

                        final sales = int.tryParse(snapshot.child('sales').value.toString()) ?? 0;
                        final profitMargin = int.tryParse(snapshot.child('profit_margin').value.toString()) ?? 0;
                        final costOfOperations = int.tryParse(snapshot.child('cost_of_operations').value.toString()) ?? 0;
                        final customerLoyalty = int.tryParse(snapshot.child('customer_loyalty').value.toString()) ?? 0;

                        final updatedSales = (sales + (sales * 0.03)).toInt();
                        final updatedProfitMargin = (profitMargin + (profitMargin * 0.05)).toInt();
                        final updatedCostOfOperations = (costOfOperations - (costOfOperations * 0.05)).toInt();
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
                          MaterialPageRoute(builder: (context) => Frame2342()),
                        );
                      },
                    ),
                  ],
                ),
                SizedBox(height: isMobile ? screenWidth * 0.01 : screenWidth * 0.03),
                Row(
                  children: [
                    AnswerBubble(
                      label: 'Run a Creator Fellowship Program\nto develop fresh talent',
                      onTap: () async {
                        final snapshot = await FirebaseDatabase.instance
                            .ref('gameMechanics/$userId/')
                            .get();

                        final sales = int.tryParse(snapshot.child('sales').value.toString()) ?? 0;
                        final profitMargin = int.tryParse(snapshot.child('profit_margin').value.toString()) ?? 0;
                        final costOfOperations = int.tryParse(snapshot.child('cost_of_operations').value.toString()) ?? 0;
                        final customerLoyalty = int.tryParse(snapshot.child('customer_loyalty').value.toString()) ?? 0;

                        final updatedSales = (sales + (sales * 0.06)).toInt();
                        final updatedProfitMargin = (profitMargin - (profitMargin * 0.02)).toInt();
                        final updatedCostOfOperations = (costOfOperations + (costOfOperations * 0.08)).toInt();
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
                          MaterialPageRoute(builder: (context) => Frame2342()),
                        );
                      },
                    ),
                    SizedBox(width: screenWidth * 0.10),
                    AnswerBubble(
                      label: 'Automate pre/post-production\nusing AI and upskill current team',
                      onTap: () async {
                        final snapshot = await FirebaseDatabase.instance
                            .ref('gameMechanics/$userId/')
                            .get();

                        final sales = int.tryParse(snapshot.child('sales').value.toString()) ?? 0;
                        final profitMargin = int.tryParse(snapshot.child('profit_margin').value.toString()) ?? 0;
                        final costOfOperations = int.tryParse(snapshot.child('cost_of_operations').value.toString()) ?? 0;
                        final customerLoyalty = int.tryParse(snapshot.child('customer_loyalty').value.toString()) ?? 0;

                        final updatedSales = (sales + (sales * 0.04)).toInt();
                        final updatedProfitMargin = (profitMargin + (profitMargin * 0.07)).toInt();
                        final updatedCostOfOperations = (costOfOperations + (costOfOperations * 0.02)).toInt();
                        final updatedCustomerLoyalty = customerLoyalty; // No change

                        await FirebaseDatabase.instance
                            .ref('gameMechanics/$userId/')
                            .update({
                          'sales': updatedSales,
                          'profit_margin': updatedProfitMargin,
                          'cost_of_operations': updatedCostOfOperations,
                          'customer_loyalty': updatedCustomerLoyalty,
                        });
                        if (!mounted) return; Navigator.push(context,
                          MaterialPageRoute(builder: (context) => Frame2342()),
                        );
                      },
                    ),
                  ],
                ),
              ],
            ),
          ),
          const EntertainmentMenuDrawer(),
        ],
      ),
    );
  }
}
