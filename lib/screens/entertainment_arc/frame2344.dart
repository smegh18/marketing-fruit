
import 'package:Marketing_Fruit/components/entertainment_menu_drawer.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:Marketing_Fruit/components/all_widgets.dart';
import 'package:Marketing_Fruit/components/answer_bubble.dart';
import 'package:Marketing_Fruit/screens/entertainment_arc/frame2344a.dart';
import '../../components/player_details.dart';
import 'frame2344b.dart';
import 'frame2344c.dart';
import 'frame2344d.dart';

class PitchScreen extends StatefulWidget {
  const PitchScreen({super.key});

  @override
  State<PitchScreen> createState() => _PitchScreenState();
}

class _PitchScreenState extends State<PitchScreen> {
  final TextEditingController movieNameController = TextEditingController();
  final TextEditingController genreController = TextEditingController();
  final TextEditingController storyController = TextEditingController();

  int _wordCount = 0;

  final userId = FirebaseAuth.instance.currentUser!.uid;
  final playerDetails = PlayerDetails();

  void _updateWordCount(String text) {
    final count = text.trim().split(RegExp(r'\s+')).where((w) => w.isNotEmpty).length;
    setState(() {
      _wordCount = count;
    });
  }

  @override
  void initState() {
    super.initState();
    playerDetails.saveProgress('frame2343', null);
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
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;

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
            width: screenWidth * 0.90,
            height: screenHeight * 0.80,
            backgroundColor: const Color(0xFFA39619),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    AllWidgets.buildTextField(
                      label: 'Explain Your Brand Concept in One Sentence.',
                      hint: 'Brand Concept',
                      controller: movieNameController,
                      widthm: 0.4,
                    ),
                    SizedBox(width: 20),
                    AllWidgets.buildTextField(
                      label: 'Brand Identity (Funny, Futuristic, Adventurous)',
                      hint: 'Brand Identity',
                      controller: genreController,
                      widthm: 0.4,
                    ),
                  ],
                ),
                SizedBox(height: 20),
                const Text(
                  'What is Your Story Behind the Brand?',
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
                    child: Stack(
                      children: [
                        ValueListenableBuilder<TextEditingValue>(
                          valueListenable: storyController,
                          builder: (context, value, _) {
                            if (value.text.isNotEmpty) return const SizedBox.shrink();
                            return SingleChildScrollView(
                              padding: const EdgeInsets.only(top: 12),
                              child: RichText(
                                text: const TextSpan(
                                  style: TextStyle(color: Colors.grey, fontSize: 24),
                                  children: [
                                    TextSpan(
                                      text: "Describe the thought and story behind brand",
                                      style: TextStyle(
                                        decoration: TextDecoration.underline,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                        TextField(
                          controller: storyController,
                          maxLines: null,
                          expands: true,
                          onChanged: _updateWordCount,
                          style: const TextStyle(color: Colors.black),
                          decoration: const InputDecoration(
                            border: InputBorder.none,
                            contentPadding: EdgeInsets.zero,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                SizedBox(height: 10),
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
            left: screenWidth * 0.45,
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

                final choice = snapshot.child('choice').value.toString();

                switch (choice) {
                  case 'studio':
                    if (!mounted) return; Navigator.push(context,
                      MaterialPageRoute(builder: (context) => const Frame2344a()),
                    );
                    break;
                  case 'collab':
                    if (!mounted) return; Navigator.push(context,
                      MaterialPageRoute(builder: (context) => const Frame2344b()),
                    );
                    break;
                  case 'ai':
                    if (!mounted) return; Navigator.push(context,
                      MaterialPageRoute(builder: (context) => const Frame2344c()),
                    );
                    break;
                  case 'niche':
                    if (!mounted) return; Navigator.push(context,
                      MaterialPageRoute(builder: (context) => const Frame2344d()),
                    );
                    break;
                }
              },
            ),
          ),
          EntertainmentMenuDrawer()
        ],
      ),
    );
  }
}
