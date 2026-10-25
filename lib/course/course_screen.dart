import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart'; // For kIsWeb
import 'course_service.dart';
import 'models.dart';

class CoursesScreen extends StatefulWidget {
  final void Function(Course course) onCourseTap;

  const CoursesScreen({super.key, required this.onCourseTap});

  @override
  State<CoursesScreen> createState() => _CoursesScreenState();
}

class _CoursesScreenState extends State<CoursesScreen> {
  late Future<List<Course>> _coursesFuture;
  final Map<int, Course?> _courseDetails = {};
  final Map<int, bool> _detailsLoading = {};

  final TextEditingController _searchCtrl = TextEditingController();
  String _query = '';

  @override
  void initState() {
    super.initState();
    _coursesFuture = CourseService.fetchCourses();
    _searchCtrl.addListener(() {
      final next = _searchCtrl.text;
      if (next != _query) {
        setState(() => _query = next);
      }
    });
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  Widget statIconText(IconData icon, String text,
      {Color color = const Color(0xFF7B1FA2)}) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 18, color: color),
        const SizedBox(width: 4),
        Text(
          text,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: color,
          ),
        ),
      ],
    );
  }

  void _fetchDetails(int id) async {
    if (_detailsLoading[id] == true || _courseDetails.containsKey(id)) return;
    setState(() => _detailsLoading[id] = true);
    try {
      final detail = await CourseService.fetchCourseDetail(id);
      setState(() {
        _courseDetails[id] = detail;
        _detailsLoading[id] = false;
      });
    } catch (_) {
      setState(() {
        _detailsLoading[id] = false;
      });
    }
  }

  List<Course> _applyFilter(List<Course> courses) {
    final q = _query.trim().toLowerCase();
    if (q.isEmpty) return courses;
    return courses.where((c) {
      final name = c.name.toLowerCase();
      final instr =
      (c.instructorName.isNotEmpty ? c.instructorName : 'user').toLowerCase();
      return name.contains(q) || instr.contains(q);
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final bool isWeb = kIsWeb;
    return Container(
      padding: const EdgeInsets.all(24),
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
      child: FutureBuilder<List<Course>>(
        future: _coursesFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const SizedBox(
              height: 300,
              child: Center(child: CircularProgressIndicator()),
            );
          }
          if (snapshot.hasError) {
            return SizedBox(
              height: 300,
              child: Center(child: Text('Error: ${snapshot.error}')),
            );
          }
          final courses = snapshot.data ?? [];
          final filtered = _applyFilter(courses);

          return SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextField(
                  controller: _searchCtrl,
                  decoration: InputDecoration(
                    hintText: 'Search courses or instructors...',
                    prefixIcon: const Icon(Icons.search),
                    suffixIcon: (_query.isNotEmpty)
                        ? IconButton(
                      tooltip: 'Clear',
                      icon: const Icon(Icons.close),
                      onPressed: () {
                        _searchCtrl.clear();
                        FocusScope.of(context).unfocus();
                      },
                    )
                        : null,
                    isDense: true,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Padding(
                  padding: const EdgeInsets.only(bottom: 16.0),
                  child: Text(
                    "Courses",
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: theme.colorScheme.primary,
                    ),
                  ),
                ),
                if (courses.isEmpty)
                  const SizedBox(
                    height: 300,
                    child: Center(child: Text('No courses found')),
                  )
                else if (filtered.isEmpty)
                  SizedBox(
                    height: 300,
                    child: Center(
                      child: Text(
                        'No results for “$_query”',
                        style: const TextStyle(fontSize: 16),
                      ),
                    ),
                  )
                else
                  for (final course in filtered)
                    Builder(
                      builder: (ctx) {
                        WidgetsBinding.instance.addPostFrameCallback((_) {
                          _fetchDetails(course.id);
                        });

                        final details = _courseDetails[course.id];
                        final loadingDetails = _detailsLoading[course.id] == true;

                        final price = "Free";
                        final imageWidget = (course.image.isNotEmpty)
                            ? ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: Image.network(
                            course.image,
                            width: 120,
                            height: 90,
                            fit: BoxFit.cover,
                            errorBuilder: (ctx, err, stack) => Container(
                              width: 120,
                              height: 90,
                              color: Colors.grey.shade200,
                              child: const Icon(Icons.image,
                                  size: 40, color: Colors.grey),
                            ),
                          ),
                        )
                            : Container(
                          width: 120,
                          height: 90,
                          decoration: BoxDecoration(
                            color: Colors.grey.shade200,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Icon(Icons.image,
                              size: 40, color: Colors.grey),
                        );

                        final lessonCount = (details?.sections ?? [])
                            .fold<int>(
                            0,
                                (sum, s) =>
                            sum + s.items.where((item) => item.type == "lp_lesson").length);
                        final quizCount = (details?.sections ?? [])
                            .fold<int>(
                            0,
                                (sum, s) =>
                            sum + s.items.where((item) => item.type == "lp_quiz").length);
                        final studentCount = details?.countStudents ?? 0;

                        Widget cardContent = Container(
                          margin: const EdgeInsets.symmetric(vertical: 14),
                          padding: const EdgeInsets.symmetric(
                              vertical: 12, horizontal: 14),
                          decoration: BoxDecoration(
                            color: theme.canvasColor,
                            borderRadius: BorderRadius.circular(12),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.12),
                                spreadRadius: 1,
                                blurRadius: 9,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              imageWidget,
                              const SizedBox(width: 18),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      course.name,
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 19,
                                        color: theme.colorScheme.secondary,
                                      ),
                                    ),
                                    const SizedBox(height: 7),
                                    Text.rich(
                                      TextSpan(
                                        text: 'by ',
                                        style: const TextStyle(
                                            fontSize: 14,
                                            color: Colors.black87),
                                        children: [
                                          TextSpan(
                                            text: course.instructorName.isNotEmpty
                                                ? course.instructorName
                                                : "user",
                                            style: const TextStyle(
                                              fontWeight: FontWeight.bold,
                                              color: Colors.black,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    const SizedBox(height: 7),
                                    loadingDetails
                                        ? const Padding(
                                      padding:
                                      EdgeInsets.symmetric(vertical: 8),
                                      child: SizedBox(
                                        width: 22,
                                        height: 22,
                                        child: CircularProgressIndicator(
                                            strokeWidth: 2),
                                      ),
                                    )
                                        : Wrap(
                                      spacing: 15,
                                      children: [
                                        statIconText(
                                            Icons.access_time,
                                            course.duration.isNotEmpty
                                                ? course.duration
                                                : '0 Weeks',
                                            color: const Color(0xFF673AB7)),
                                        statIconText(Icons.bar_chart,
                                            "All Levels",
                                            color: const Color(0xFF673AB7)),
                                        statIconText(Icons.description,
                                            "$lessonCount Lessons",
                                            color: const Color(0xFF673AB7)),
                                        statIconText(Icons.quiz,
                                            "$quizCount Quizzes",
                                            color: const Color(0xFF673AB7)),
                                        statIconText(Icons.verified_user,
                                            "$studentCount Student${studentCount == 1 ? '' : 's'}",
                                            color: const Color(0xFF673AB7)),
                                      ],
                                    ),
                                    const SizedBox(height: 9),
                                    Text(
                                      price,
                                      style: const TextStyle(
                                        color: Colors.green,
                                        fontSize: 17,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              if (isWeb)
                                Padding(
                                  padding: const EdgeInsets.only(left: 10),
                                  child: Column(
                                    children: [
                                      SizedBox(
                                        height: 36,
                                        child: OutlinedButton(
                                          style: OutlinedButton.styleFrom(
                                            foregroundColor: theme.textTheme.bodyLarge?.color ??
                                                Colors.black87,
                                            side: BorderSide(
                                                color: theme.dividerColor),
                                            shape: RoundedRectangleBorder(
                                              borderRadius:
                                              BorderRadius.circular(6),
                                            ),
                                          ),
                                          child: const Text('Read more'),
                                          onPressed: () => widget.onCourseTap(
                                              details ?? course),
                                        ),
                                      ),
                                    ],
                                  ),
                                )
                            ],
                          ),
                        );

                        // For NOT web, make the card clickable, no Read more button
                        if (!isWeb) {
                          cardContent = InkWell(
                            borderRadius: BorderRadius.circular(12),
                            onTap: () => widget.onCourseTap(details ?? course),
                            child: cardContent,
                          );
                        }

                        return cardContent;
                      },
                    )
              ],
            ),
          );
        },
      ),
    );
  }
}
