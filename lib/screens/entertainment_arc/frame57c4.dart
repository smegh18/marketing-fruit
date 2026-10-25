import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:Marketing_Fruit/components/player_details.dart';
import '../../components/answer_bubble.dart';
import '../../components/text_bubble.dart';
import '../../components/entertainment_menu_drawer.dart';
import 'frame57.dart';
import 'frame57c5.dart';

class Frame57c4 extends StatefulWidget {
  const Frame57c4({super.key});

  @override
  State<Frame57c4> createState() => _Frame57c4State();
}

class _Frame57c4State extends State<Frame57c4> {
  final playerDetails = PlayerDetails();

  @override
  void initState() {
    super.initState();
    playerDetails.saveProgress('frame57c4', null);
  }

  @override
  Widget build(BuildContext context) {
    final userId = FirebaseAuth.instance.currentUser!.uid;
    final screenSize = MediaQuery.of(context).size;
    final screenHeight = screenSize.height;
    final screenWidth = screenSize.width;

    return Scaffold(
      body: Stack(
        children: [
          SizedBox.expand(
            child: Image.asset(
              'assets/EA11.png',
              fit: BoxFit.cover,
            ),
          ),
          Positioned(
            bottom: screenHeight * 0.26,
            left: screenWidth * 0.05,
            right: screenWidth * 0.05,
            child: TextBubble(
              message:
              "So, just asking to confirm if you want to stick with AI based production or explore other options",
            ),
          ),
          Positioned(
            bottom: screenHeight * 0.07,
            left: screenWidth * 0.25,
            child: Row(
              children: [
                AnswerBubble(
                  label: 'Yup, AI it is',
                  onTap: () {
                    if (!mounted) return; Navigator.push(context,
                      MaterialPageRoute(
                        builder: (context) => Frame57c5(),
                      ),
                    );
                  },
                ),
                SizedBox(width: screenWidth * 0.08),
                AnswerBubble(
                  label: 'Rethink Decision',
                  onTap: () async {
                    final snapshot = await FirebaseDatabase.instance
                        .ref('gameMechanics/$userId/')
                        .get();

                    final sales = int.tryParse(snapshot.child('sales').value.toString()) ?? 0;
                    final profitMargin = int.tryParse(snapshot.child('profit_margin').value.toString()) ?? 0;
                    final costOfOperations = int.tryParse(snapshot.child('cost_of_operations').value.toString()) ?? 0;
                    final customerLoyalty = int.tryParse(snapshot.child('customer_loyalty').value.toString()) ?? 0;

                    final updatedSales = (sales + (sales * 0.05)).toInt();
                    final updatedProfitMargin = (profitMargin - (profitMargin * 0.20)).toInt();
                    final updatedCostOfOperations = (costOfOperations + (costOfOperations * 0.10)).toInt();
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
                        builder: (context) => Frame57(),
                      ),
                    );
                  },
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
