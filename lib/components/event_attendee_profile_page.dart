import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';


import 'event_attendies_preference.dart'; // Import your section

class AttendeeProfileViewPage extends StatefulWidget {
  final String eventId;
  final String userId;
  final void Function() onBack;

  const AttendeeProfileViewPage({
    super.key,
    required this.eventId,
    required this.userId, required this.onBack,
  });

  @override
  State<AttendeeProfileViewPage> createState() => _AttendeeProfileViewPageState();
}

class _AttendeeProfileViewPageState extends State<AttendeeProfileViewPage> {
  bool _loading = true;
  String? _error;
  // For the AttendeesPreferenceSection widget below
  String _userName = '';
  String _role = '';
  String _description = '';
  final List<Map<String, dynamic>> _questions = [];
  Map<String, dynamic> _answers = {};

  @override
  void initState() {
    super.initState();
    _fetchAll();
  }

  Future<void> _fetchAll() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      // 1. Fetch event node
      final eventSnap = await FirebaseDatabase.instance.ref('events/${widget.eventId}').get();
      if (!eventSnap.exists) {
        setState(() {
          _error = 'Event not found';
          _loading = false;
        });
        return;
      }
      final eventData = eventSnap.value as Map<dynamic, dynamic>;

      // 1a. Parse questions (list)
      List<Map<String, dynamic>> questionSchema = [];
      if (eventData['questions'] is List) {
        questionSchema = (eventData['questions'] as List)
            .whereType<Map>()
            .map<Map<String, dynamic>>((item) {
          final q = Map<String, dynamic>.from(item);
          // generate a pseudo-id using label since there is no actual id
          final String id = (q['question'] ?? '').toString().trim();
          final type = (q['type'] ?? '').toString().toLowerCase();
          final opts = (q['options'] is List)
              ? (q['options'] as List).map((v) => v.toString()).toList()
              : <String>[];
          return {
            'id': id,
            'label': id,
            'type': type == 'checkboxes' ? 'checkbox' : type, // match UI naming
            'options': opts,
          };
        }).where((q) => q['id'].isNotEmpty).toList();
      }

      // 2. Fetch attendee's registeredUsers data
      final regUsers = eventData['registeredUsers'] as Map?;
      if (regUsers == null || !regUsers.containsKey(widget.userId)) {
        setState(() {
          _error = 'User is not registered for this event';
          _loading = false;
        });
        return;
      }
      final attendeeReg = regUsers[widget.userId] as Map;

      // 2a. Parse answers as {questionId: value}
      final List answersArr = attendeeReg['answers'] is List ? attendeeReg['answers'] : [];
      Map<String, dynamic> answersMap = {};
      for (final ans in answersArr) {
        if (ans is Map) {
          final k = (ans['question'] ?? '').toString().trim(); // must match id/label
          answersMap[k] = ans['answer'];
        }
      }

      // 2b. Basic user info (prefer userDetails fields)
      Map<String, dynamic> userDetails = {};
      if (attendeeReg['userDetails'] is Map) {
        userDetails = Map<String, dynamic>.from(attendeeReg['userDetails']);
      }

      // 3. Fetch user/master record for role and more info
      final userSnap = await FirebaseDatabase.instance.ref('users/${widget.userId}').get();
      String role = '';
      String description = '';
      if (userSnap.exists) {
        final userdata = userSnap.value as Map;
        if (userdata['playerDetails'] is Map &&
            userdata['playerDetails']['role'] != null) {
          role = userdata['playerDetails']['role'].toString();
        } else if (userdata['role'] != null) {
          role = userdata['role'].toString();
        }
        // build the description: can be improved/personalized
        if (userdata['bio'] != null && userdata['bio'].toString().trim().isNotEmpty) {
          description = userdata['bio'];
        } else if (userDetails['schoolName'] != null) {
          description = "School: ${userDetails['schoolName']}";
        }
      }

      setState(() {
        _loading = false;
        _questionSchema = questionSchema;
        _answers = answersMap;
        _userName = userDetails['userName'] ??
            userDetails['first_name'] ??
            '';
        _role = role;
        _description = description;
      });
    } catch (e) {
      setState(() {
        _error = 'Error loading data: $e';
        _loading = false;
      });
    }
  }

  late List<Map<String, dynamic>> _questionSchema;

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_error != null) {
      return Center(child: Text(
        _error!,
        style: const TextStyle(color: Colors.red, fontSize: 16),
      ));
    }

    return AttendeesPreferenceSection(
      userName: _userName,
      role: _role,
      userDescription: _description,
      qa: const [],
      questions: _questionSchema,
      answers: _answers,
      onCall: () {},
      onDM: () {},
      onMail: () {},
      onBack: () {
        widget.onBack();
      }
    );
  }
}
