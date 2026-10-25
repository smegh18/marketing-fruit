import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:Marketing_Fruit/components/all_widgets.dart';
import 'package:Marketing_Fruit/components/answer_bubble.dart';
import '../../components/player_details.dart';
import '../../components/entertainment_menu_drawer.dart';
import 'frame54a0_3.dart';

void main() {
  runApp(const MaterialApp(
    debugShowCheckedModeBanner: false,
    home: MovieScriptEditorScreen(),
  ));
}

class MovieScriptEditorScreen extends StatefulWidget {
  const MovieScriptEditorScreen({super.key});

  @override
  State<MovieScriptEditorScreen> createState() => _MovieScriptEditorScreenState();
}

class _MovieScriptEditorScreenState extends State<MovieScriptEditorScreen> {
  final TextEditingController movieNameController = TextEditingController();
  final TextEditingController genreController = TextEditingController();
  final TextEditingController storyController = TextEditingController();

  int _wordCount = 0;

  final userId = FirebaseAuth.instance.currentUser!.uid;
  final playerDetails = PlayerDetails();

  @override
  void initState() {
    super.initState();
    // Save progress when entering this frame
    playerDetails.saveProgress('movie_script_editor', null);
  }

  void _updateWordCount(String text) {
    final count = text.trim().split(RegExp(r'\s+')).where((w) => w.isNotEmpty).length;
    setState(() {
      _wordCount = count;
    });
  }

  @override
  void dispose() {
    movieNameController.dispose();
    genreController.dispose();
    storyController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          SizedBox.expand(
            child: Image.asset(
              'assets/EA10.png',
              fit: BoxFit.cover,
            ),
          ),
          AllWidgets.buildFrostedGlassContainer(
            width: MediaQuery.of(context).size.width * 0.90,
            height: MediaQuery.of(context).size.height * 0.80,
            backgroundColor: const Color(0xFFA39619),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    AllWidgets.buildTextField(
                      label: 'Enter Your Movie Name',
                      hint: ' Movie Name',
                      controller: movieNameController,
                      widthm: 0.4,
                    ),
                    const SizedBox(height: 20),
                    AllWidgets.buildTextField(
                      label: 'Which Genre Are you planning to enter?',
                      hint: ' Movie Genre',
                      controller: genreController,
                      widthm: 0.4,
                    ),
                    const SizedBox(height: 20),
                  ],
                ),
                const SizedBox(height: 20),
                const Text(
                  'Movie Storyline/Script:',
                  style: TextStyle(
                    fontSize: 18,
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 10),
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: TextField(
                      controller: storyController,
                      maxLines: null,
                      expands: true,
                      onChanged: _updateWordCount,
                      decoration: const InputDecoration.collapsed(
                        hintText: "Start writing your movie script here...",
                      ),
                      style: const TextStyle(color: Colors.black),
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                Align(
                  alignment: Alignment.bottomRight,
                  child: Text(
                    'Word count: $_wordCount',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ),
          Positioned(
            bottom: 20,
            right: MediaQuery.of(context).size.width * 0.4,
            child: AnswerBubble(
              label: "Submit",
              onTap: () async {
                final plainText = storyController.text.trim();

                if (movieNameController.text.isEmpty ||
                    genreController.text.isEmpty ||
                    plainText.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Please fill in all fields.')),
                  );
                  return;
                }

                final snapshot = await FirebaseDatabase.instance
                    .ref('gameMechanics/$userId/')
                    .get();

                final sales = int.tryParse(snapshot.child('sales').value.toString()) ?? 0;
                final profit = int.tryParse(snapshot.child('profit_margin').value.toString()) ?? 0;
                final costOfOperations = int.tryParse(snapshot.child('cost_of_operations').value.toString()) ?? 0;
                final customerLoyalty = int.tryParse(snapshot.child('customer_loyalty').value.toString()) ?? 0;

                int updatedProfitMargin = 0;
                if (_wordCount < 200) {
                  updatedProfitMargin = (profit - (profit * 0.15)).toInt();
                } else if (_wordCount >= 200 && _wordCount < 500) {
                  updatedProfitMargin = (profit + (profit * 0.01)).toInt();
                } else if (_wordCount >= 500 && _wordCount < 750) {
                  updatedProfitMargin = (profit + (profit * 0.25)).toInt();
                } else {
                  updatedProfitMargin = profit * 2;
                }

                await FirebaseDatabase.instance
                    .ref('gameMechanics/$userId/')
                    .update({
                  'sales': sales,
                  'profit_margin': updatedProfitMargin,
                  'cost_of_operations': costOfOperations,
                  'customer_loyalty': customerLoyalty,
                });

                playerDetails.getMovieName(movieNameController.text);
                playerDetails.getGenre(genreController.text);
                playerDetails.getStoryline(plainText);

                if (!mounted) return; Navigator.push(context,
                  MaterialPageRoute(builder: (context) => Frame54a0_3()),
                );
              },
            ),
          ),
          // Entertainment Menu Drawer
          const EntertainmentMenuDrawer(),
        ],
      ),
    );
  }
}
