import 'dart:io';

import 'package:Marketing_Fruit/components/entertainment_menu_drawer.dart';
import 'package:Marketing_Fruit/screens/dashboard/main_layout.dart';
import 'package:Marketing_Fruit/screens/entertainment_arc/frame11.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:Marketing_Fruit/components/player_details.dart';
import 'package:Marketing_Fruit/screens/entertainment_arc/frame2345a.dart';
import 'package:Marketing_Fruit/screens/entertainment_arc/frame2345b.dart';
import 'package:Marketing_Fruit/screens/entertainment_arc/frame2345c.dart';
import 'package:Marketing_Fruit/screens/entertainment_arc/frame2345d.dart';
import '../../components/answer_bubble.dart';
import '../../components/text_bubble.dart';

class Frame2345 extends StatefulWidget {
  final String? background;
  const Frame2345({super.key, this.background});

  @override
  State<Frame2345> createState() => _Frame2345State();
}

class _Frame2345State extends State<Frame2345> {
  String role = '';

  @override
  void initState() {
    super.initState();
    fetchRole();
    Optionally: PlayerDetails().saveProgress('frame2345', null);
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
                            sId: 3)),
                  );
                },
                child: MessageBubbleWithImage(
                  imageAsset: 'assets/messagebubble.png',
                  text:
                  "Now that you have come so far in business, it is important to know how to build and manage the brand that you are trying so hard create. \n Take this course to learn more",
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
              "Now with all these legal turmoils and law suit coming your way, how would you like to navigate",
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
                        label: 'Fight it Out in Court',
                        onTap: () async {
                          final snapshot = await FirebaseDatabase.instance.ref('gameMechanics/$userId/').get();
                          final sales = int.tryParse(snapshot.child('sales').value.toString()) ?? 0;
                          final profitMargin = int.tryParse(snapshot.child('profit_margin').value.toString()) ?? 0;
                          final costOfOperations = int.tryParse(snapshot.child('cost_of_operations').value.toString()) ?? 0;
                          final customerLoyalty = int.tryParse(snapshot.child('customer_loyalty').value.toString()) ?? 0;
                          final updatedSales = (sales - (sales * 0.05)).toInt();
                          final updatedProfitMargin = (profitMargin - (profitMargin * 0.10)).toInt();
                          final updatedCostOfOperations = (costOfOperations + (costOfOperations * 0.07)).toInt();
                          final updatedCustomerLoyalty = (customerLoyalty + (customerLoyalty * 0.08)).toInt();
                          await FirebaseDatabase.instance.ref('gameMechanics/$userId/').update({
                            'sales': updatedSales,
                            'profit_margin': updatedProfitMargin,
                            'cost_of_operations': updatedCostOfOperations,
                            'customer_loyalty': updatedCustomerLoyalty,
                          });
                          if (!mounted) return; Navigator.push(context, MaterialPageRoute(builder: (context) => Frame2345a()));
                        },
                      ),
                    ),
                    SizedBox(width: screenWidth * 0.06),
                    Expanded(
                      child: AnswerBubble(
                        label: 'Settle Privately and Acquire Partial Rights',
                        onTap: () async {
                          final snapshot = await FirebaseDatabase.instance.ref('gameMechanics/$userId/').get();
                          final sales = int.tryParse(snapshot.child('sales').value.toString()) ?? 0;
                          final profitMargin = int.tryParse(snapshot.child('profit_margin').value.toString()) ?? 0;
                          final costOfOperations = int.tryParse(snapshot.child('cost_of_operations').value.toString()) ?? 0;
                          final customerLoyalty = int.tryParse(snapshot.child('customer_loyalty').value.toString()) ?? 0;
                          final updatedSales = (sales - (sales * 0.02)).toInt();
                          final updatedProfitMargin = (profitMargin - (profitMargin * 0.05)).toInt();
                          final updatedCostOfOperations = (costOfOperations + (costOfOperations * 0.03)).toInt();
                          final updatedCustomerLoyalty = (customerLoyalty + 0); // +0%
                          await FirebaseDatabase.instance.ref('gameMechanics/$userId/').update({
                            'sales': updatedSales,
                            'profit_margin': updatedProfitMargin,
                            'cost_of_operations': updatedCostOfOperations,
                            'customer_loyalty': updatedCustomerLoyalty,
                          });
                          if (!mounted) return; Navigator.push(context, MaterialPageRoute(builder: (context) => Frame2345b()));
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
                        label: 'Remove the Content and Issue an Apology',
                        onTap: () async {
                          final snapshot = await FirebaseDatabase.instance.ref('gameMechanics/$userId/').get();
                          final sales = int.tryParse(snapshot.child('sales').value.toString()) ?? 0;
                          final profitMargin = int.tryParse(snapshot.child('profit_margin').value.toString()) ?? 0;
                          final costOfOperations = int.tryParse(snapshot.child('cost_of_operations').value.toString()) ?? 0;
                          final customerLoyalty = int.tryParse(snapshot.child('customer_loyalty').value.toString()) ?? 0;
                          final updatedSales = (sales - (sales * 0.10)).toInt();
                          final updatedProfitMargin = (profitMargin - (profitMargin * 0.08)).toInt();
                          final updatedCostOfOperations = (costOfOperations + (costOfOperations * 0.04)).toInt();
                          final updatedCustomerLoyalty = (customerLoyalty - (customerLoyalty * 0.02)).toInt();
                          await FirebaseDatabase.instance.ref('gameMechanics/$userId/').update({
                            'sales': updatedSales,
                            'profit_margin': updatedProfitMargin,
                            'cost_of_operations': updatedCostOfOperations,
                            'customer_loyalty': updatedCustomerLoyalty,
                          });
                          if (!mounted) return; Navigator.push(context, MaterialPageRoute(builder: (context) => Frame2345c()));
                        },
                      ),
                    ),
                    SizedBox(width: screenWidth * 0.06),
                    Expanded(
                      child: AnswerBubble(
                        label: 'Launch a PR Counterattack',
                        onTap: () async {
                          final snapshot = await FirebaseDatabase.instance.ref('gameMechanics/$userId/').get();
                          final sales = int.tryParse(snapshot.child('sales').value.toString()) ?? 0;
                          final profitMargin = int.tryParse(snapshot.child('profit_margin').value.toString()) ?? 0;
                          final costOfOperations = int.tryParse(snapshot.child('cost_of_operations').value.toString()) ?? 0;
                          final customerLoyalty = int.tryParse(snapshot.child('customer_loyalty').value.toString()) ?? 0;
                          final updatedSales = (sales + (sales * 0.04)).toInt();
                          final updatedProfitMargin = (profitMargin - (profitMargin * 0.03)).toInt();
                          final updatedCostOfOperations = (costOfOperations + (costOfOperations * 0.02)).toInt();
                          final updatedCustomerLoyalty = (customerLoyalty + (customerLoyalty * 0.05)).toInt();
                          await FirebaseDatabase.instance.ref('gameMechanics/$userId/').update({
                            'sales': updatedSales,
                            'profit_margin': updatedProfitMargin,
                            'cost_of_operations': updatedCostOfOperations,
                            'customer_loyalty': updatedCustomerLoyalty,
                          });
                          if (!mounted) return; Navigator.push(context, MaterialPageRoute(builder: (context) => Frame2345d()));
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
