import 'dart:convert';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:http/http.dart' as http;
import 'models.dart';

const String baseUrl = "https://marketingfruit.net/wp-json/learnpress/v1";

Future<String?> getWpTokenForCurrentUser() async {
  final user = FirebaseAuth.instance.currentUser;
  if (user == null) return null;
  final ref = FirebaseDatabase.instance.ref('users/${user.uid}/wp_token');
  final snapshot = await ref.get();
  if (snapshot.exists) {
    return snapshot.value as String;
  }
  return null;
}

class CourseService {


  static Future<Map<String, String>> _authHeader() async {
    final token = await getWpTokenForCurrentUser();
    if (token == null) throw Exception('No WordPress token found for user');
    return {'Authorization': 'Bearer $token'};
  }

  /// List All Courses
  static Future<List<Course>> fetchCourses() async {
    final headers = await _authHeader();
    final resp = await http.get(Uri.parse("$baseUrl/courses"), headers: headers);
    if (resp.statusCode != 200) throw Exception('Failed to fetch courses');
    final arr = json.decode(resp.body) as List;
    return arr.map((j) => Course.fromJson(j)).toList();
  }

  /// Retrieve A Course by ID (Full details)
  static Future<Course> fetchCourseDetail(int id) async {
    final headers = await _authHeader();
    final resp = await http.get(Uri.parse("$baseUrl/courses/$id/"), headers: headers);
    if (resp.statusCode != 200) throw Exception('Failed to fetch course detail');
    final jsonData = json.decode(resp.body);
    return Course.fromJson(jsonData);
  }

  /// List All Lessons
  static Future<List<Lesson>> listLessons() async {
    final headers = await _authHeader();
    final resp = await http.get(Uri.parse("$baseUrl/lessons"), headers: headers);
    if (resp.statusCode != 200) throw Exception('Failed to fetch lessons');
    final arr = json.decode(resp.body) as List;
    return arr.map((j) => Lesson.fromJson(j)).toList();
  }

  /// Retrieve A Lesson by ID
  static Future<Lesson> fetchLesson(int id) async {
    final headers = await _authHeader();
    print(headers);
    final url = "$baseUrl/lessons/$id";
    print(url);
    final resp = await http.get(Uri.parse(url), headers: headers);
    print(resp.body);
    if (resp.statusCode != 200) throw Exception('Failed to fetch lesson');
    return Lesson.fromJson(json.decode(resp.body));
  }

  /// List All Quizzes
  static Future<List<Quiz>> listQuizzes() async {
    final headers = await _authHeader();
    final resp = await http.get(Uri.parse("$baseUrl/quiz"), headers: headers);
    if (resp.statusCode != 200) throw Exception('Failed to fetch quizzes');
    final arr = json.decode(resp.body) as List;
    return arr.map((j) => Quiz.fromJson(j)).toList();
  }

  /// Retrieve A Quiz by ID
  static Future<Quiz> fetchQuiz(int id) async {
    final headers = await _authHeader();
    final resp = await http.get(Uri.parse("$baseUrl/quiz/$id"), headers: headers);
    if (resp.statusCode != 200) throw Exception('Failed to fetch quiz');
    print(resp.body);
    return Quiz.fromJson(json.decode(resp.body));
  }

  /// List All My Courses (need authentication)
  static Future<List<Course>> fetchMyCourses() async {
    final headers = await _authHeader();
    final resp = await http.get(
      Uri.parse("$baseUrl/courses/?learned=true"),
      headers: headers,
    );
    final arr = json.decode(resp.body) as List;
    return arr.map((j) => Course.fromJson(j)).toList();
  }

  /// Enroll in a Course
  static Future<bool> enrollCourse({required int courseId}) async {
    final headers = await _authHeader();
    headers['Content-Type'] = 'application/json';
    final resp = await http.post(
      Uri.parse("$baseUrl/courses/enroll"),
      headers: headers,
      body: json.encode({'id': courseId}),
    );
    print(resp.body);
    return resp.statusCode == 200;
  }

  /// Finish Course
  static Future<bool> finishCourse({required int courseId}) async {
    final headers = await _authHeader();
    headers['Content-Type'] = 'application/json';
    final resp = await http.post(
      Uri.parse("$baseUrl/courses/finish"),
      headers: headers,
      body: json.encode({'id': courseId}),
    );
    return resp.statusCode == 200;
  }

  /// Retake Course
  static Future<bool> retakeCourse({required int courseId}) async {
    final headers = await _authHeader();
    headers['Content-Type'] = 'application/json';
    final resp = await http.post(
      Uri.parse("$baseUrl/courses/retake"),
      headers: headers,
      body: json.encode({'id': courseId}),
    );
    return resp.statusCode == 200;
  }

  /// Finish Lesson (mark as complete)
  static Future<bool> finishLesson({required int lessonId}) async {
    final headers = await _authHeader();
    headers['Content-Type'] = 'application/json';
    final resp = await http.post(
      Uri.parse("$baseUrl/lessons/finish"),
      headers: headers,
      body: json.encode({'id': lessonId}),
    );
    return resp.statusCode == 200;
  }

  /// Start Quiz
  static Future<bool> startQuiz({required int quizId}) async {
    final headers = await _authHeader();
    headers['Content-Type'] = 'application/json';
    final resp = await http.post(
      Uri.parse("$baseUrl/quiz/start"),
      headers: headers,
      body: json.encode({'id': quizId}),
    );
    return resp.statusCode == 200;
  }

  /// Check Quiz Answer (single question)
  static Future<dynamic> checkQuizAnswer({
    required int quizId,
    required String answer,
  }) async {
    final headers = await _authHeader();
    headers['Content-Type'] = 'application/json';
    final resp = await http.post(
      Uri.parse("$baseUrl/quiz/check_answer"),
      headers: headers,
      body: json.encode({'id': quizId, 'answered': answer}),
    );
    return json.decode(resp.body);
  }

  /// Finish Quiz (submit all answers)
  static Future<bool> finishQuiz({
    required int quizId,
    required Map<String, dynamic> answers,
  }) async {
    final headers = await _authHeader();
    headers['Content-Type'] = 'application/json';
    final resp = await http.post(
      Uri.parse("$baseUrl/quiz/finish"),
      headers: headers,
      body: json.encode({'id': quizId, 'answered': answers}),
    );
    return resp.statusCode == 200;
  }

  /// Retrieve Course Category
  static Future<List<Map<String, dynamic>>> fetchCourseCategories() async {
    final resp = await http.get(Uri.parse("https://marketingfruit.net/wp-json/wp/v2/course_category"));
    if (resp.statusCode != 200) throw Exception('Failed to fetch categories');
    return List<Map<String, dynamic>>.from(json.decode(resp.body));
  }
}
