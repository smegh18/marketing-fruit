import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:Marketing_Fruit/components/glasspopup.dart';

import 'event_attendee_profile_page.dart';
// ⬇️ Use your shared glass popup helper so every dialog matches the "glass" style
// import 'glass_popup.dart';

class AttendiesCountSection extends StatefulWidget {
  final String eventId;
  final ValueChanged<List<Map<String, dynamic>>>? onBulkMail;

  const AttendiesCountSection({
    super.key,
    required this.eventId,
    this.onBulkMail,
  });

  @override
  State<AttendiesCountSection> createState() => _AttendiesCountSectionState();
}

class _AttendiesCountSectionState extends State<AttendiesCountSection> {
  static const double _colGap = 16;

  List<Map<String, dynamic>> _questions = [];
  List<Map<String, dynamic>> _attendees = [];
  bool _loading = true;
  String? _loadError;
  String? _selectedUserId; // For profile view switching

  final Set<String> _selectedQuestionLabels = <String>{};
  final Map<String, Set<String>> _selectedAnswersByQuestion = <String, Set<String>>{};

  @override
  void initState() {
    super.initState();
    _fetchAllEventData();
  }

  Future<void> _fetchAllEventData() async {
    setState(() {
      _loading = true;
      _loadError = null;
    });
    try {
      final eventRef = FirebaseDatabase.instance.ref('events/${widget.eventId}');
      final eventSnap = await eventRef.get();
      if (!eventSnap.exists) {
        setState(() {
          _loadError = 'No data found for event.';
          _loading = false;
        });
        return;
      }
      final eventData = eventSnap.value as Map<dynamic, dynamic>;

      // 1. Fetch Questions (List of Maps)
      List<Map<String, dynamic>> questions = [];
      if (eventData['questions'] is List) {
        questions = (eventData['questions'] as List)
            .whereType<Map>()
            .map<Map<String, dynamic>>((item) {
          final q = Map<String, dynamic>.from(item);
          final opts = (q['options'] is List)
              ? (q['options'] as List).map((v) => v.toString()).toList()
              : <String>[];
          return {
            'label': q['question']?.toString() ?? '',
            'type': q['type']?.toString().toLowerCase() ?? '',
            'options': opts,
          };
        }).where((q) => q['label'].isNotEmpty).toList();
      }

      // 2. Build Registered Users & Answers
      List<_RawAttendee> rawAttendees = [];
      if (eventData['registeredUsers'] is Map) {
        final regUsers = eventData['registeredUsers'] as Map;
        for (final entry in regUsers.entries) {
          final userId = entry.key as String;
          final value = entry.value as Map;
          Map<String, dynamic> userDetails = {};
          if (value['userDetails'] is Map) {
            userDetails = Map<String, dynamic>.from(value['userDetails']);
          }
          List<dynamic> answersRaw = value['answers'] is List ? value['answers'] : [];
          rawAttendees.add(_RawAttendee(
            userId: userId,
            answersRaw: answersRaw,
            userDetails: userDetails,
          ));
        }
      }

      // 3. Fetch attendee role from /users/{userId}/role or playerDetails/role
      final Map<String, Future<String>> roleFutures = {};
      for (final att in rawAttendees) {
        roleFutures[att.userId] = _fetchUserRole(att.userId);
      }
      final Map<String, String> userRoles = {};
      for (final att in rawAttendees) {
        userRoles[att.userId] = await roleFutures[att.userId]!;
      }

      // 4. Build attendee info map for table (answers as {questionLabel: value})
      final List<Map<String, dynamic>> attendees = rawAttendees.map((att) {
        final Map<String, dynamic> answers = {};
        for (final ans in att.answersRaw) {
          final Map a = ans as Map;
          final String? label = a['question']?.toString();
          if (label != null) answers[label] = a['answer'];
        }
        final role = userRoles[att.userId] ??
            att.userDetails['role'] ??
            att.userDetails['playerDetails']?['role'] ??
            '';
        return {
          'userId': att.userId, // <--- Ensure userId in map!
          'name': att.userDetails['userName'] ??
              att.userDetails['first_name'] ??
              '',
          'role': role,
          'phone': att.userDetails['contact'] ??
              att.userDetails['mobile'] ??
              '',
          'email': att.userDetails['email'] ?? '',
          'answers': answers,
        };
      }).toList();

      setState(() {
        _questions = questions;
        _attendees = attendees;
        _loading = false;
      });
    } catch (e) {
      setState(() {
        _loadError = 'Error loading event data: $e';
        _loading = false;
      });
    }
  }

  Future<String> _fetchUserRole(String userId) async {
    try {
      final ref = FirebaseDatabase.instance.ref('users/$userId');
      final snap = await ref.get();
      if (!snap.exists) return '';
      final data = snap.value as Map<dynamic, dynamic>;
      if (data['playerDetails'] is Map && data['playerDetails']['role'] != null) {
        return (data['playerDetails']['role'] ?? '').toString();
      }
      return (data['role'] ?? '').toString();
    } catch (_) {
      return '';
    }
  }

  List<Map<String, dynamic>> get _filterableQuestions => _questions
      .where((q) =>
          (q['type'] == 'radio' || q['type'] == 'checkboxes' || q['type'] == 'checkbox') &&
          (q['label'] as String?)?.isNotEmpty == true)
      .toList();

  Map<String, dynamic>? _getQuestion(String label) {
    try {
      return _filterableQuestions.firstWhere((q) => q['label'] == label);
    } catch (_) {
      return null;
    }
  }

  List<String> _optionsFor(String questionLabel) {
    final q = _getQuestion(questionLabel);
    if (q == null) return [];
    return (q['options'] as List).map((e) => e.toString()).toList();
  }

  List<Map<String, dynamic>> get _filteredAttendees {
    if (_selectedQuestionLabels.isEmpty) {
      return _attendees;
    }
    return _attendees.where((a) {
      final answers = (a['answers'] as Map<String, dynamic>? ?? const {});
      for (final questionLabel in _selectedQuestionLabels) {
        final selectedAnswers = _selectedAnswersByQuestion[questionLabel] ?? <String>{};
        final q = _getQuestion(questionLabel);
        final type = q?['type'] ?? 'radio';
        final v = answers[questionLabel];
        if (v == null) return false;
        if (selectedAnswers.isEmpty) continue;
        if (type == 'checkboxes' || type == 'checkbox') {
          final List<String> vals = v is List
              ? v.map((e) => e.toString()).toList()
              : [v.toString()];
          if (!vals.toSet().intersection(selectedAnswers).isNotEmpty) {
            return false;
          }
        } else {
          if (!selectedAnswers.contains(v.toString())) {
            return false;
          }
        }
      }
      return true;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;
    final maxWidth = screenSize.width * 0.95;

    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_loadError != null) {
      return Center(child: Text(_loadError!, style: const TextStyle(color: Colors.red)));
    }

    return SingleChildScrollView(
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: maxWidth),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            boxShadow: const [
              BoxShadow(
                color: Colors.black12,
                blurRadius: 6,
                offset: Offset(0, 3),
              ),
            ],
          ),
          child: _selectedUserId == null
              ? buildTable(context)
              : AttendeeProfileViewPage(
                  eventId: widget.eventId,
                  userId: _selectedUserId!,
                  onBack: () => setState(() => _selectedUserId = null),
                ),
        ),
      ),
    );
  }

  Widget buildTable(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Wrap(
                alignment: WrapAlignment.start,
                crossAxisAlignment: WrapCrossAlignment.center,
                spacing: 12,
                runSpacing: 8,
                children: [
                  const Padding(
                    padding: EdgeInsets.only(right: 4),
                    child: Text(
                      "Attendees Count",
                      style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                    ),
                  ),
                  OutlinedButton.icon(
                    icon: const Icon(Icons.filter_list),
                    label: Text(
                      _selectedQuestionLabels.isEmpty
                          ? 'Questions'
                          : 'Questions (${_selectedQuestionLabels.length})',
                    ),
                    onPressed: _openQuestionsPicker,
                  ),
                  OutlinedButton.icon(
                    icon: const Icon(Icons.tune),
                    label: Text(_selectedAnswersCountLabel()),
                    onPressed: _selectedQuestionLabels.isEmpty ? null : _openAnswersPicker,
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            ElevatedButton.icon(
              icon: const Icon(Icons.mail_outline),
              label: Text(_selectedQuestionLabels.isNotEmpty ? 'Mail (Filtered)' : 'Mail (All)'),
              onPressed: _handleBulkMail,
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
          decoration: BoxDecoration(
            color: Colors.grey[200],
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            children: const [
              _HeaderCell(text: 'Name', flex: 4),
              _HeaderGap(),
              _HeaderCell(text: 'Role', flex: 2),
              _HeaderGap(),
              _HeaderCell(text: 'Contact', flex: 3),
            ],
          ),
        ),
        const SizedBox(height: 8),
        ListView.separated(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: _filteredAttendees.length,
          separatorBuilder: (_, __) => const SizedBox(height: 8),
          itemBuilder: (context, index) {
            final a = _filteredAttendees[index];
            return InkWell(
              borderRadius: BorderRadius.circular(8),
              onTap: () => setState(() => _selectedUserId = a['userId']),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  border: Border.all(color: Colors.grey.shade300),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Expanded(flex: 4, child: Text(a['name'] ?? '')),
                    const SizedBox(width: _colGap),
                    const SizedBox.shrink(),
                    Expanded(
                      flex: 2,
                      child: Align(
                        alignment: Alignment.centerLeft,
                        child: _RoleChip(role: a['role'] ?? ''),
                      ),
                    ),
                    const SizedBox(width: _colGap),
                    Expanded(
                      flex: 3,
                      child: Row(
                        children: [
                          _ContactIcon(
                            tooltip: 'Call ${a['phone']}',
                            icon: Icons.call_outlined,
                            onPressed: () => debugPrint('Call ${a['phone']}'),
                          ),
                          _ContactIcon(
                            tooltip: 'Mail ${a['email']}',
                            icon: Icons.mail_outline,
                            onPressed: () => debugPrint('Mail ${a['email']}'),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ],
    );
  }

  // =========================
  // GLASS POPUP: Questions UI
  // =========================
  void _openQuestionsPicker() async {
    final temp = Set<String>.from(_selectedQuestionLabels);
    await showGlassPopup<void>(
      context: context,
      title: 'Select questions',
      dismissible: true,
      child: SizedBox(
        width: 420,
        child: StatefulBuilder(
          builder: (context, setSt) {
            return Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Flexible(
                  child: ListView(
                    shrinkWrap: true,
                    children: [
                      for (final q in _filterableQuestions)
                        CheckboxListTile(
                          title: Text(q['label'] as String, style: const TextStyle(color: Colors.white)),
                          subtitle: Text(
                            (q['type'] as String).toUpperCase(),
                            style: const TextStyle(color: Colors.white70),
                          ),
                          value: temp.contains(q['label']),
                          onChanged: (val) {
                            setSt(() {
                              if (val == true) {
                                temp.add(q['label'] as String);
                              } else {
                                temp.remove(q['label'] as String);
                              }
                            });
                          },
                          activeColor: Colors.white,
                          checkColor: const Color.fromARGB(255, 90, 89, 89),
                        ),
                    ],
                  ),
                ),
                const SizedBox(height: 14),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        style: OutlinedButton.styleFrom(
                          side: BorderSide(color: Colors.white.withOpacity(0.7)),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                        onPressed: () => Navigator.pop(context),
                        child: const Text('Cancel', style: TextStyle(fontWeight: FontWeight.w600)),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.black,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          elevation: 0,
                        ),
                        onPressed: () {
                          setState(() {
                            _selectedQuestionLabels
                              ..clear()
                              ..addAll(temp);
                            _selectedAnswersByQuestion
                                .removeWhere((key, value) => !_selectedQuestionLabels.contains(key));
                          });
                          Navigator.pop(context);
                        },
                        child: const Text('Apply', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
                      ),
                    ),
                  ],
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  // =======================
  // GLASS POPUP: Answers UI
  // =======================
  void _openAnswersPicker() async {
    final Map<String, Set<String>> temp =
        _selectedAnswersByQuestion.map((k, v) => MapEntry(k, Set<String>.from(v)));
    for (final label in _selectedQuestionLabels) {
      temp.putIfAbsent(label, () => <String>{});
    }

    await showGlassPopup<void>(
      context: context,
      title: 'Select answers',
      dismissible: true,
      child: SizedBox(
        width: 520,
        child: StatefulBuilder(
          builder: (context, setSt) {
            return SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  for (final qLabel in _selectedQuestionLabels) ...[
                    const SizedBox(height: 8),
                    Text(qLabel, style: const TextStyle(fontWeight: FontWeight.w700, color: Colors.white)),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        for (final opt in _optionsFor(qLabel))
                          FilterChip(
                            label: Text(opt),
                            selected: temp[qLabel]!.contains(opt),
                            onSelected: (sel) {
                              setSt(() {
                                if (sel) {
                                  temp[qLabel]!.add(opt);
                                } else {
                                  temp[qLabel]!.remove(opt);
                                }
                              });
                            },
                          ),
                      ],
                    ),
                    const Divider(height: 20, color: Colors.white24),
                  ],
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          style: OutlinedButton.styleFrom(
                            side: BorderSide(color: Colors.white.withOpacity(0.7)),
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          ),
                          onPressed: () {
                            setState(() {
                              for (final qLabel in _selectedQuestionLabels) {
                                _selectedAnswersByQuestion[qLabel] = <String>{};
                              }
                            });
                            Navigator.pop(context);
                          },
                          child: const Text('Clear', style: TextStyle(fontWeight: FontWeight.w600)),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.black,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                            elevation: 0,
                          ),
                          onPressed: () {
                            setState(() {
                              _selectedAnswersByQuestion
                                ..clear()
                                ..addAll(temp);
                            });
                            Navigator.pop(context);
                          },
                          child: const Text('Apply', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  String _selectedAnswersCountLabel() {
    if (_selectedQuestionLabels.isEmpty) return 'Answers';
    int count = 0;
    for (final qLabel in _selectedQuestionLabels) {
      count += (_selectedAnswersByQuestion[qLabel]?.length ?? 0);
    }
    return count == 0 ? 'Answers' : 'Answers ($count)';
  }

  // ===========================
  // GLASS POPUP: Bulk Mail List
  // ===========================
  void _handleBulkMail() {
    final List<Map<String, dynamic>> targets =
        _selectedQuestionLabels.isNotEmpty ? _filteredAttendees : _attendees;

    if (widget.onBulkMail != null) {
      widget.onBulkMail!(targets);
      return;
    }

    final emails = targets
        .map((a) => (a['email'] ?? '').toString().trim())
        .where((e) => e.isNotEmpty)
        .toSet()
        .toList();

    if (emails.isEmpty) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No emails found for selected attendees.')),
      );
      return;
    }

    showGlassPopup<void>(
      context: context,
      title: _selectedQuestionLabels.isNotEmpty ? 'Mock Mail (Filtered)' : 'Mock Mail (All)',
      dismissible: true,
      child: SizedBox(
        width: 480,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Recipients (${emails.length}):', style: const TextStyle(color: Colors.white)),
            const SizedBox(height: 8),
            Container(
              constraints: const BoxConstraints(maxHeight: 260),
              child: ListView.builder(
                shrinkWrap: true,
                itemCount: emails.length,
                itemBuilder: (_, i) => ListTile(
                  dense: true,
                  leading: const Icon(Icons.email_outlined, color: Colors.white),
                  title: Text(emails[i], style: const TextStyle(color: Colors.white)),
                ),
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    style: OutlinedButton.styleFrom(
                      side: BorderSide(color: Colors.white.withOpacity(0.7)),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Close', style: TextStyle(fontWeight: FontWeight.w600)),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.black,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      elevation: 0,
                    ),
                    onPressed: () {
                      Navigator.pop(context);
                      if (!mounted) return;
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Mock mail queued to ${emails.length} recipients.')),
                      );
                    },
                    child: const Text('Send', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _RawAttendee {
  final String userId;
  final Map<String, dynamic> userDetails;
  final List<dynamic> answersRaw;
  _RawAttendee({
    required this.userId,
    required this.userDetails,
    required this.answersRaw,
  });
}

class _HeaderGap extends StatelessWidget {
  const _HeaderGap();
  @override
  Widget build(BuildContext context) => const SizedBox(width: 16);
}

class _HeaderCell extends StatelessWidget {
  final String text;
  final int flex;
  const _HeaderCell({required this.text, required this.flex});
  @override
  Widget build(BuildContext context) {
    return Expanded(
      flex: flex,
      child: Text(text, style: const TextStyle(fontWeight: FontWeight.bold)),
    );
  }
}

class _RoleChip extends StatelessWidget {
  final String role;
  const _RoleChip({required this.role});
  Color _bg(String r) {
    switch (r.toLowerCase()) {
      case 'student':
        return Colors.blue.shade50;
      case 'admin':
        return Colors.orange.shade50;
      case 'brand':
        return Colors.purple.shade50;
      case 'school':
        return Colors.green.shade50;
      default:
        return Colors.grey.shade100;
    }
  }
  Color _fg(String r) {
    switch (r.toLowerCase()) {
      case 'student':
        return Colors.blue;
      case 'admin':
        return Colors.orange;
      case 'brand':
        return Colors.purple;
      case 'school':
        return Colors.green;
      default:
        return Colors.grey;
    }
  }
  @override
  Widget build(BuildContext context) {
    final display = role.isEmpty ? '—' : role;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: _bg(display),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        display,
        style: TextStyle(
          color: _fg(display),
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

class _ContactIcon extends StatelessWidget {
  final IconData icon;
  final String tooltip;
  final VoidCallback onPressed;

  const _ContactIcon({
    required this.icon,
    required this.tooltip,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: IconButton(
        icon: Icon(icon),
        onPressed: onPressed,
        splashRadius: 20,
      ),
    );
  }
}
