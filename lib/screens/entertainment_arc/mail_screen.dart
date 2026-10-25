import 'package:Marketing_Fruit/components/entertainment_menu_drawer.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:Marketing_Fruit/components/all_widgets.dart';
import 'package:Marketing_Fruit/components/answer_bubble.dart';

import '../../components/player_details.dart';
import 'frame19asd1.dart';
import 'frame19awm1.dart';
import 'frame19d1.dart';

class MailScreen extends StatefulWidget {
  final String frame;
  const MailScreen({super.key, required this.frame});

  @override
  State<MailScreen> createState() => _MailScreenState();
}

class _MailScreenState extends State<MailScreen> {
  final TextEditingController movieNameController = TextEditingController();
  final TextEditingController genreController = TextEditingController();
  final TextEditingController subjectController = TextEditingController();
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
    playerDetails.saveProgress('mail_screen', null);
  }

  @override
  void dispose() {
    movieNameController.dispose();
    genreController.dispose();
    subjectController.dispose();
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
                    SizedBox(width: 20),
                    AllWidgets.buildTextField(
                      label: 'Which Genre Are you planning to enter?',
                      hint: ' Movie Genre',
                      controller: genreController,
                      widthm: 0.4,
                    ),
                  ],
                ),
                SizedBox(height: 20),
                AllWidgets.buildTextField(
                  label: 'Subject Line',
                  hint: ' Subject Line Here',
                  controller: subjectController,
                  widthw: 0.88,
                ),
                SizedBox(height: 20),
                const Text(
                  'Body',
                  style: TextStyle(
                    fontSize: 18,
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: 10),
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Stack(
                      children: [
                        Positioned.fill(
                          child: ValueListenableBuilder<TextEditingValue>(
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
                                        text: "Mail Body Here\n\nHint:- Things you should consider including in your mail body\n",
                                        style: TextStyle(
                                          decoration: TextDecoration.underline,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      TextSpan(
                                        text:
                                        "\n"
                                            "-> Brief Synopsis – What is the content about? Keep it tight, engaging, and evocative.\n"
                                            "-> Market Potential – Why it’s commercially viable.\n"
                                            "-> Target Audience – Who will watch this and why they’ll love it.\n"
                                            "-> Format & Delivery – Details like runtime, number of episodes, format (HD/4K), language, etc.\n"
                                            "-> Previous Success (if any) – Festival selections, awards, streaming numbers, fanbase.\n"
                                            "-> Call-to-Action – What you want from them and why now.\n",
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            },
                          ),
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
            right: MediaQuery.of(context).size.width * 0.4,
            child: AnswerBubble(
              label: "Submit",
              onTap: () async {
                final plainText = storyController.text.trim();

                if (movieNameController.text.isEmpty ||
                    genreController.text.isEmpty ||
                    subjectController.text.isEmpty ||
                    plainText.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Please fill in all fields.')),
                  );
                  return;
                }

                final snapshot = await FirebaseDatabase.instance
                    .ref('gameMechanics/$userId/')
                    .get();

                final type = snapshot.child('type').value.toString();

                if(widget.frame == 'a'){
                  if (type == 'm' || type == 'w') {
                    if (!mounted) return; Navigator.push(context,
                      MaterialPageRoute(
                        builder: (context) => Frame19awm1(),
                      ),
                    );
                  } else {
                    if (!mounted) return; Navigator.push(context,
                        MaterialPageRoute(
                          builder: (context) => Frame19asd1(),
                        )
                    );
                  }
                } else {
                  if (!mounted) return; Navigator.push(context,
                    MaterialPageRoute(builder: (context) => Frame19d1()),
                  );
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
