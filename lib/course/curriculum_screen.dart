import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';

import 'course_service.dart';
import 'models.dart';
import 'package:flutter_html/flutter_html.dart';

class CurriculumInteractiveScreen extends StatefulWidget {
  final List<SectionItem> curriculum;
  final int courseId;
  final int startIndex;
  final void Function(Map<String, bool>)? onProgressUpdate;

  const CurriculumInteractiveScreen({
    super.key,
    required this.curriculum,
    required this.courseId,
    this.startIndex = 0,
    this.onProgressUpdate,
  });

  @override
  State<CurriculumInteractiveScreen> createState() => _CurriculumInteractiveScreenState();
}

class _CurriculumInteractiveScreenState extends State<CurriculumInteractiveScreen> {
  late int _currentIndex;
  Map<dynamic, dynamic> userResponses = {};
  User? _user;
  Map<String, bool> _progress = {};

  @override
  void initState() {
    super.initState();
    _user = FirebaseAuth.instance.currentUser;
    _currentIndex = widget.startIndex;
    _fetchProgress();
  }

  Future<void> _fetchProgress() async {
    if (_user == null) return;
    final dbRef = FirebaseDatabase.instance
        .ref('progress/${_user!.uid}/course_${widget.courseId}');
    final snapshot = await dbRef.get();
    final Map data = snapshot.value as Map? ?? {};
    setState(() {
      _progress = data.map((k, v) => MapEntry(k.toString(), v == true));
    });
    widget.onProgressUpdate?.call(_progress);
  }

  Future<void> _markComplete(String key) async {
    if (_user == null) return;
    final dbRef = FirebaseDatabase.instance
        .ref('progress/${_user!.uid}/course_${widget.courseId}/$key');
    await dbRef.set(true);
    setState(() {
      _progress[key] = true;
    });
    widget.onProgressUpdate?.call(_progress);
  }

  void _next() {
    if (_currentIndex < widget.curriculum.length - 1) {
      setState(() {
        _currentIndex++;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final item = widget.curriculum[_currentIndex];
    final progressKey = "${item.type}_${item.id}";
    final completed = _progress[progressKey] == true;

    return Scaffold(
      body: LayoutBuilder(
        builder: (context, constraints) {
          return Padding(
            padding: const EdgeInsets.all(24),
            child: Container(
              height: constraints.maxHeight,
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: theme.cardColor,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.5),
                    spreadRadius: 2,
                    blurRadius: 5,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: FutureBuilder<Object?>(
                future: item.type == "lp_lesson"
                    ? CourseService.fetchLesson(item.id)
                    : CourseService.fetchQuiz(item.id),
                builder: (ctx, snapshot) {
                  if (snapshot.connectionState != ConnectionState.done) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  if (snapshot.hasError) {
                    return Center(
                      child: Text(
                        'Error loading item: ${snapshot.error}. Please check your network or try again later.',
                        style: const TextStyle(color: Colors.red),
                      ),
                    );
                  }
                  if (snapshot.data == null) {
                    return const Center(
                      child: Text(
                        'Data not found for this item.',
                        style: TextStyle(color: Colors.red),
                      ),
                    );
                  }
                  final data = snapshot.data;
                  if (item.type == "lp_lesson") {
                    if (data is! Lesson) {
                      return const Center(
                        child: Text(
                          'Invalid lesson data.',
                          style: TextStyle(color: Colors.red),
                        ),
                      );
                    }
                    return Stack(
                      children: [
                        Positioned.fill(
                          child: Padding(
                            padding: const EdgeInsets.only(bottom: 80),
                            child: SingleChildScrollView(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Curriculum (${_currentIndex + 1} / ${widget.curriculum.length})',
                                    style: theme.textTheme.titleMedium?.copyWith(
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                  const SizedBox(height: 12),
                                  ..._buildLesson(data, completed),
                                ],
                              ),
                            ),
                          ),
                        ),
                        Positioned(
                          right: 16,
                          bottom: 16,
                          child: _buildBottomButton(item, data, completed, progressKey),
                        ),
                      ],
                    );
                  }
                  if (item.type == "lp_quiz") {
                    Quiz quiz;
                    if (data is Quiz) {
                      quiz = data;
                    } else if (data is Map<String, dynamic>) {
                      quiz = Quiz.fromJson(data);
                    } else {
                      return const Center(
                        child: Text(
                          'Invalid quiz data structure.',
                          style: TextStyle(color: Colors.red),
                        ),
                      );
                    }
                    return Stack(
                      children: [
                        Positioned.fill(
                          child: Padding(
                            padding: const EdgeInsets.only(bottom: 80),
                            child: SingleChildScrollView(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Curriculum (${_currentIndex + 1} / ${widget.curriculum.length})',
                                    style: theme.textTheme.titleMedium?.copyWith(
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                  const SizedBox(height: 12),
                                  ..._buildQuiz(quiz, completed),
                                ],
                              ),
                            ),
                          ),
                        ),
                        Positioned(
                          right: 16,
                          bottom: 16,
                          child: _buildBottomButton(item, quiz, completed, progressKey),
                        ),
                      ],
                    );
                  }
                  return const Center(
                    child: Text('Unknown curriculum item type', style: TextStyle(color: Colors.red)),
                  );
                },
              ),
            ),
          );
        },
      ),
    );
  }

  List<Widget> _buildLesson(Lesson lesson, bool completed) {
    final title = (lesson.title).isNotEmpty ? lesson.title : "Untitled lesson";
    final content = (lesson.content).isNotEmpty ? lesson.content : "No content available.";
    return [
      Text(
        title,
        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 20),
      ),
      const SizedBox(height: 10),
      Html(data: content),
      const SizedBox(height: 8),
      if (completed)
        Row(
          children: [
            Icon(Icons.check_circle, color: Colors.green, size: 18),
            const SizedBox(width: 6),
            Text("Completed", style: TextStyle(color: Colors.green)),
          ],
        ),
    ];
  }

  List<Widget> _buildQuiz(Quiz quiz, bool completed) {
    final title = quiz.title.isNotEmpty ? quiz.title : "Quiz";
    final questions = quiz.questions ?? [];
    return [
      Text(
        title,
        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 20),
      ),
      const SizedBox(height: 20),
      if (questions.isNotEmpty)
        ...questions.map((q) {
          final String qId = q['id']?.toString() ?? '';
          final String qTitle = q['title'] ?? 'Question';
          final String qType = (q['type'] ?? '').toString().toLowerCase();
          final String qHint = q['hint'] ?? '';
          final List<dynamic> opts = q['options'] ?? [];

          Widget answerWidget;
          switch (qType) {
            case 'single_choice':
              answerWidget = Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ...opts.map((opt) {
                    final optUid = opt['uid']?.toString() ?? '';
                    final optTitle = opt['title'] ?? opt['title_api'] ?? '';
                    return RadioListTile<String>(
                      title: Text(optTitle.toString()),
                      value: optUid,
                      groupValue: userResponses[qId] as String?,
                      onChanged: (value) {
                        setState(() {
                          userResponses[qId] = value;
                        });
                      },
                    );
                  }),
                  if (qHint.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 6),
                      child: Text(
                        "Hint: $qHint",
                        style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
                      ),
                    ),
                ],
              );
              break;

            case 'multi_choice':
              answerWidget = Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ...opts.map((opt) {
                    final optUid = opt['uid']?.toString() ?? '';
                    final optTitle = opt['title'] ?? opt['title_api'] ?? '';
                    final selected = (userResponses[qId] as Set<String>? ?? <String>{}).contains(optUid);
                    return CheckboxListTile(
                      title: Text(optTitle.toString()),
                      value: selected,
                      onChanged: (isChecked) {
                        setState(() {
                          final resp = userResponses[qId] as Set<String>? ?? <String>{};
                          if (isChecked == true) {
                            resp.add(optUid);
                          } else {
                            resp.remove(optUid);
                          }
                          userResponses[qId] = resp;
                        });
                      },
                    );
                  }),
                  if (qHint.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 6),
                      child: Text(
                        "Hint: $qHint",
                        style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
                      ),
                    ),
                ],
              );
              break;

            case 'true_or_false':
              answerWidget = Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ...opts.map((opt) {
                    final optUid = opt['uid']?.toString() ?? '';
                    final optTitle = opt['title'] ?? opt['title_api'] ?? '';
                    return RadioListTile<String>(
                      title: Text(optTitle.toString()),
                      value: optUid,
                      groupValue: userResponses[qId] as String?,
                      onChanged: (value) {
                        setState(() {
                          userResponses[qId] = value;
                        });
                      },
                    );
                  }),
                  if (qHint.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 6),
                      child: Text(
                        "Hint: $qHint",
                        style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
                      ),
                    ),
                ],
              );
              break;

            case 'fill_in_blanks':
              answerWidget = Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  TextField(
                    onChanged: (val) => userResponses[qId] = val,
                    decoration: const InputDecoration(hintText: "Answer here..."),
                  ),
                  if (qHint.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 6),
                      child: Text(
                        "Hint: $qHint",
                        style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
                      ),
                    ),
                ],
              );
              break;

            default:
              answerWidget = Text(
                "Unsupported question type: $qType",
                style: TextStyle(color: Colors.red),
              );
          }

          return Card(
            margin: const EdgeInsets.symmetric(vertical: 8),
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(qTitle, style: const TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 6),
                  answerWidget,
                ],
              ),
            ),
          );
        })
      else
        const ListTile(
          contentPadding: EdgeInsets.zero,
          title: Text(
            'No questions available for this quiz.',
            style: TextStyle(color: Colors.red),
          ),
        ),
      const SizedBox(height: 8),
      if (completed)
        Row(
          children: [
            Icon(Icons.check_circle, color: Colors.green, size: 18),
            const SizedBox(width: 6),
            Text("Completed", style: TextStyle(color: Colors.green)),
          ],
        ),
    ];
  }


  Widget _buildBottomButton(SectionItem item, Object? data, bool completed, String progressKey) {
    if (completed) {
      return ElevatedButton(
        onPressed: _currentIndex < widget.curriculum.length - 1
            ? _next
            : () {
          Navigator.pop(context);
        },
        child: Text(_currentIndex < widget.curriculum.length - 1 ? "Next" : "Exit Curriculum"),
      );
    }
    if (item.type == "lp_lesson" && data is Lesson) {
      return ElevatedButton(
        onPressed: () async {
          try {
            await CourseService.finishLesson(lessonId: data.id);
          } catch (_) {}
          await _markComplete(progressKey);
          _next();
        },
        child: const Text("Mark Complete & Next"),
      );
    }
    if (item.type == "lp_quiz" && data is Quiz) {
      return ElevatedButton(
        onPressed: () async {
          try {
            await CourseService.finishQuiz(
              quizId: data.id,
              answers: userResponses as Map<String, dynamic>,
            );
          } catch (_) {}
          await _markComplete(progressKey);
          _next();
        },
        child: const Text("Submit Quiz & Next"),
      );
    }
    return const SizedBox.shrink();
  }
}
