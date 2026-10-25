import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'course_service.dart';
import 'models.dart';

class CourseDetailScreen extends StatefulWidget {
  final int courseId;
  final String? courseName;
  final int sectionId;
  final void Function(List<SectionItem> items, int courseId, [int startIndex])? onLessonTap;

  const CourseDetailScreen({
    super.key,
    required this.courseId,
    this.courseName,
    this.sectionId = 0,
    this.onLessonTap,
  });

  @override
  State<CourseDetailScreen> createState() => _CourseDetailScreenState();
}

class _CourseDetailScreenState extends State<CourseDetailScreen> {
  Course? _course;
  bool _loading = true;
  String? _error;
  bool _enrolled = false;
  bool _enrolling = false;
  User? _user;
  Map<String, bool> _progress = {};
  int? _expandedSectionIdx; // Track expanded section

  @override
  void initState() {
    super.initState();
    _user = FirebaseAuth.instance.currentUser;
    _loadCourse();
    _checkEnrollment();
  }

  Future<void> _checkEnrollment() async {
    if (_user == null) {
      setState(() {
        _enrolled = false;
      });
      return;
    }
    try {
      final docSnap = await FirebaseFirestore.instance
          .collection('users')
          .doc(_user!.uid)
          .collection('enrolledCourses')
          .doc(widget.courseId.toString())
          .get();
      final data = docSnap.data();
      final enrolled = data != null && (data['enrolled'] == true);
      setState(() {
        _enrolled = enrolled;
      });
    } catch (e) {
      setState(() {
        _enrolled = false;
      });
    }
    // Progress: fetch from Realtime DB
    if (_user != null) {
      final dbRef = FirebaseDatabase.instance
          .ref('progress/${_user!.uid}/course_${widget.courseId}');
      final snapshot = await dbRef.get();
      final data = snapshot.value as Map<dynamic, dynamic>? ?? {};
      setState(() {
        _progress = data.map((k, v) => MapEntry(k.toString(), v == true));
      });
    }
  }

  Future<void> _loadCourse() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final course = await CourseService.fetchCourseDetail(widget.courseId);
      setState(() {
        _course = course;
        _loading = false;
      });
      // Set expanded section idx using sectionId
      _setExpandedSectionIdx();
      // Refresh progress after course load
      await _checkEnrollment();
    } catch (e) {
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  void _setExpandedSectionIdx() {
    if (_course == null || _course!.sections.isEmpty) return;
    // Find index for sectionId; fallback to 0 if not found
    final idx = _course!.sections.indexWhere((s) => s.id == widget.sectionId);
    setState(() {
      _expandedSectionIdx = idx >= 0 ? idx : null;
    });
  }

  Future<void> _enrollUser() async {
    setState(() => _enrolling = true);
    try {
      final ok = await CourseService.enrollCourse(courseId: widget.courseId);
      if (ok && _user != null) {
        final enrolledRef = FirebaseFirestore.instance
            .collection('users')
            .doc(_user!.uid)
            .collection('enrolledCourses')
            .doc(widget.courseId.toString());
        await enrolledRef.set({'enrolled': true});
      }
      setState(() {
        _enrolled = ok;
        _enrolling = false;
      });
      if (ok) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Successfully Enrolled!')),
        );
        _loadCourse();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Enrollment Failed')),
        );
      }
    } catch (e) {
      setState(() => _enrolling = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    }
  }

  void _startCurriculum([int? startIndex]) {
    if (_course == null) return;
    final allItems = _course!.sections.expand((s) => s.items).toList();
    final idx = startIndex ??
        allItems.indexWhere(
                (item) => !(_progress["${item.type}_${item.id}"] ?? false));
    widget.onLessonTap!(allItems, widget.courseId, idx);
  }

  void _openEntry(int sectionIdx, int itemIdx) {
    if (_course == null) return;
    final allItems = _course!.sections.expand((s) => s.items).toList();
    int idx = 0;
    for (int i = 0; i < sectionIdx; i++) {
      idx += _course!.sections[i].items.length;
    }
    idx += itemIdx;
    if (widget.onLessonTap != null) {
      widget.onLessonTap!(allItems, widget.courseId, idx);
    }
  }

  void _updateProgress(Map<String, bool> updated) {
    setState(() {
      _progress = {..._progress, ...updated};
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_error != null) {
      return Center(child: Text(_error!, style: const TextStyle(color: Colors.red)));
    }
    final course = _course!;
    final allItems = course.sections.expand((s) => s.items).toList();
    final hasUncompleted = allItems.any(
            (item) => !(_progress["${item.type}_${item.id}"] ?? false));

    return Material(
      child: LayoutBuilder(
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
              child: Stack(
                children: [
                  Positioned.fill(
                    child: Padding(
                      padding: const EdgeInsets.only(bottom: 80),
                      child: SingleChildScrollView(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            ListTile(
                              contentPadding: EdgeInsets.zero,
                              title: Text(
                                course.name,
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 22,
                                ),
                              ),
                              subtitle: Text(
                                'Instructor: ${course.instructorName}\nDuration: ${course.duration}',
                              ),
                            ),
                            const Divider(height: 32),
                            const Text(
                              'Curriculum:',
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
                            if (!_enrolled)
                              Padding(
                                padding: const EdgeInsets.symmetric(vertical: 12),
                                child: ElevatedButton(
                                  onPressed: _enrolling ? null : _enrollUser,
                                  child: _enrolling
                                      ? const SizedBox(
                                    height: 18,
                                    width: 18,
                                    child: CircularProgressIndicator(strokeWidth: 2),
                                  )
                                      : const Text('Enroll in Course'),
                                ),
                              ),
                            if (_enrolled && course.sections.isNotEmpty)
                              ...course.sections.asMap().entries.map((sectionEntry) {
                                final sectionIdx = sectionEntry.key;
                                final section = sectionEntry.value;
                                return ExpansionTile(
                                  key: PageStorageKey('section_${section.id}'),
                                  title: Text(
                                    section.title,
                                    style: const TextStyle(fontWeight: FontWeight.bold),
                                  ),
                                  initiallyExpanded:
                                  _expandedSectionIdx == sectionIdx,
                                  onExpansionChanged: (expanded) {
                                    setState(() {
                                      _expandedSectionIdx =
                                      expanded ? sectionIdx : null;
                                    });
                                  },
                                  children: section.items.asMap().entries.map((itemEntry) {
                                    final itemIdx = itemEntry.key;
                                    final item = itemEntry.value;
                                    final progressKey = "${item.type}_${item.id}";
                                    final completed = _progress[progressKey] == true;

                                    return ListTile(
                                      title: Row(
                                        children: [
                                          Text(item.title),
                                          const SizedBox(width: 6),
                                          if (completed)
                                            Icon(Icons.check_circle,
                                                color: Colors.green, size: 18),
                                        ],
                                      ),
                                      leading: Icon(
                                        item.type == 'lp_lesson'
                                            ? Icons.book
                                            : item.type == 'lp_quiz'
                                            ? Icons.quiz
                                            : Icons.interpreter_mode,
                                      ),
                                      trailing: item.locked
                                          ? const Icon(Icons.lock, size: 16)
                                          : null,
                                      onTap: (!item.locked)
                                          ? () => _openEntry(sectionIdx, itemIdx)
                                          : null,
                                    );
                                  }).toList(),
                                );
                              }),
                            if (_enrolled && course.sections.isEmpty)
                              Padding(
                                padding: const EdgeInsets.all(8.0),
                                child: Text(
                                  'No sections available!',
                                  style: TextStyle(color: Colors.red.shade700),
                                ),
                              ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  if (_enrolled && course.sections.isNotEmpty)
                    Positioned(
                      right: 16,
                      bottom: 16,
                      child: ElevatedButton.icon(
                        icon: const Icon(Icons.play_arrow),
                        label: Text(
                          hasUncompleted ? 'Resume' : 'Start',
                        ),
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        ),
                        onPressed: () => _startCurriculum(),
                      ),
                    ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
