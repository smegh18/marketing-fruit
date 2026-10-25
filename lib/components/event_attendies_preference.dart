import 'package:flutter/material.dart';

/// Attendees Preference Section
/// Left: list-style Q&A (not chat bubbles)
///   - text/textarea => simple question + answer row
///   - radio/checkbox => show "Selected" and "Unselected" chips
/// Right: user info + actions (Call / DM / Mail)
/// DM shows the composer at the bottom of the left list.
class AttendeesPreferenceSection extends StatefulWidget {
  final String userName;
  final String role; // School | Brand | Student | Admin
  final String? userDescription;

  /// Optional extra freeform Q&A items (each: {'q': '...', 'a': '...'})
  final List<Map<String, String>> qa;

  /// Event question schema (each item format below):
  /// {
  ///   'id': 'q1',
  ///   'label': 'Educational Quali.',
  ///   'type': 'text' | 'textarea' | 'checkbox' | 'radio',
  ///   'options': ['veg','non veg'] // only for checkbox/radio
  /// }
  final List<Map<String, dynamic>> questions;

  /// User answers keyed by question id.
  /// - text/textarea -> String
  /// - checkbox      -> List<String>
  /// - radio         -> String
  final Map<String, dynamic> answers;

  final VoidCallback? onCall;
  final VoidCallback? onDM;
  final VoidCallback? onMail;
  final VoidCallback? onBack;

  const AttendeesPreferenceSection({
    super.key,
    required this.userName,
    required this.role,
    this.userDescription,
    this.qa = const [],
    this.questions = const [],
    this.answers = const {},
    this.onCall,
    this.onDM,
    this.onMail, this.onBack,
  });

  @override
  State<AttendeesPreferenceSection> createState() => _AttendeesPreferenceSectionState();
}

class _AttendeesPreferenceSectionState extends State<AttendeesPreferenceSection> {
  bool _showComposer = false; // hidden until DM tapped

  void _enableDM() {
    setState(() => _showComposer = true);
    widget.onDM?.call();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    // Finite height so Expanded children can layout inside scrollables.
    final double sectionHeight =
        (size.height.isFinite && size.height > 0) ? (size.height * 0.7).clamp(540.0, 760.0) : 640.0;

    return Container(
      color: const Color(0xFFF5F6FA),
      padding: const EdgeInsets.all(16),
      child: Center(
        child: ConstrainedBox(
          constraints: BoxConstraints(maxWidth: size.width * 0.95),
          child: SizedBox(
            height: sectionHeight,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: _QnAListPane(
                    userName: widget.userName,
                    role: widget.role,
                    qa: widget.qa,
                    questions: widget.questions,
                    answers: widget.answers,
                    showComposer: _showComposer,
                    onBack: widget.onBack,
                  ),
                ),
                const SizedBox(width: 16),
                SizedBox(
                  width: 360,
                  child: _UserDetailsPane(
                    userName: widget.userName,
                    role: widget.role,
                    description: widget.userDescription ?? 'Add user description',
                    onCall: widget.onCall,
                    onDM: _enableDM, // DM shows composer
                    onMail: widget.onMail,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ----------------------------- LEFT (List Q&A) --------------------------------

class _QnAListPane extends StatelessWidget {
  final String userName;
  final String role;
  final List<Map<String, String>> qa;
  final List<Map<String, dynamic>> questions;
  final Map<String, dynamic> answers;
  final bool showComposer;
  final VoidCallback? onBack;

  const _QnAListPane({
    required this.userName,
    required this.role,
    required this.qa,
    required this.questions,
    required this.answers,
    required this.showComposer, this.onBack,
  });

  Color _roleColor(String r) {
    switch (r.toLowerCase()) {
      case 'student':
        return const Color(0xFF3B82F6); // blue
      case 'admin':
        return const Color(0xFFF59E0B); // amber
      case 'brand':
        return const Color(0xFF8B5CF6); // violet
      case 'school':
        return const Color(0xFF22C55E); // green
      default:
        return const Color(0xFF6B7280); // gray
    }
  }

  List<String> _asStringList(dynamic v) {
    if (v == null) return const [];
    if (v is List) {
      return v.map((e) => e?.toString() ?? '').where((s) => s.isNotEmpty).toList();
    }
    if (v is String) return [v];
    return [v.toString()];
  }

  /// Build list rows for:
  /// - text/textarea => simple row
  /// - radio/checkbox => selected & unselected chips from options
  List<_QABundle> _buildQABundles() {
    final List<_QABundle> result = [];

    // From structured questions
    for (final q in questions) {
      final id = (q['id'] ?? '').toString();
      if (id.isEmpty) continue;

      final label = (q['label'] ?? '').toString();
      final type = (q['type'] ?? 'text').toString().toLowerCase();
      final opts = (q['options'] is List) ? _asStringList(q['options']) : const <String>[];
      final value = answers[id];

      String answerText = '—';
      List<String> selected = const [];
      List<String> unselected = const [];

      if (value != null) {
        switch (type) {
          case 'checkbox':
            final items = _asStringList(value);
            selected = items;
            answerText = items.isEmpty ? '—' : items.join(', ');
            unselected = opts.where((o) => !items.contains(o)).toList();
            break;
          case 'radio':
            final s = value.toString();
            selected = s.isEmpty ? const [] : [s];
            answerText = s.isEmpty ? '—' : s;
            unselected = opts.where((o) => o != s).toList();
            break;
          default:
            answerText = value.toString().isEmpty ? '—' : value.toString();
        }
      }

      if (label.isNotEmpty) {
        result.add(_QABundle(
          question: label,
          type: type,
          answerText: answerText,
          selected: selected,
          unselected: unselected,
        ));
      }
    }

    // Freeform QA extras (treated like text)
    for (final item in qa) {
      final qText = (item['q'] ?? '').trim();
      final aText = (item['a'] ?? '').trim();
      if (qText.isNotEmpty || aText.isNotEmpty) {
        result.add(_QABundle(
          question: qText,
          type: 'text',
          answerText: aText.isEmpty ? '—' : aText,
        ));
      }
    }

    // Fallback sample
    if (result.isEmpty) {
      result.addAll([
        _QABundle(question: 'Educational Quali.', type: 'text', answerText: 'BTECH, etc'),
        _QABundle(question: 'About Yourself', type: 'textarea', answerText: 'Tell me about yourself...'),
        _QABundle(
          question: 'Meal option',
          type: 'radio',
          answerText: 'veg',
          selected: const ['veg'],
          unselected: const ['non veg'],
        ),
        _QABundle(
          question: 'Mode of transport',
          type: 'checkbox',
          answerText: 'train',
          selected: const ['train'],
          unselected: const ['bus', 'flight'],
        ),
      ]);
    }

    return result;
  }

  @override
  Widget build(BuildContext context) {
    final items = _buildQABundles();

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 6, offset: Offset(0, 3))],
      ),
      child: Column(
        children: [
          // Header with name + role chip
          Container(
            height: 56,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Row(
              children: [
                IconButton(
                  onPressed: onBack,
                  icon: const Icon(Icons.arrow_back_ios_new_rounded),
                  tooltip: 'Back',
                ),
                const SizedBox(width: 4),
                Expanded(
                  child: Row(
                    children: [
                      Flexible(
                        child: Text(
                          userName,
                          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: _roleColor(role).withOpacity(0.12),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          role,
                          style: TextStyle(
                            fontSize: 12,
                            color: _roleColor(role),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1),

          // List of Q&A
          Expanded(
            child: ListView.separated(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
              itemCount: items.length,
              separatorBuilder: (_, __) => const SizedBox(height: 12),
              itemBuilder: (context, i) {
                final it = items[i];
                final isChoice = it.type == 'radio' || it.type == 'checkbox';

                return Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF8F9FB),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFFE8EAEE)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Question
                      Text(
                        it.question,
                        style: const TextStyle(fontWeight: FontWeight.w700),
                      ),
                      const SizedBox(height: 8),

                      // Answer / Chips
                      if (!isChoice) ...[
                        Text(it.answerText),
                      ] else ...[
                        if (it.selected.isNotEmpty) ...[
                          const Text('Selected', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                          const SizedBox(height: 6),
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: it.selected.map((s) => _OptionChip(label: s, selected: true)).toList(),
                          ),
                          const SizedBox(height: 10),
                        ] else ...[
                          const Text('Selected', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                          const SizedBox(height: 6),
                          const Text('—', style: TextStyle(color: Colors.grey)),
                          const SizedBox(height: 10),
                        ],
                        const Text('Unselected', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                        const SizedBox(height: 6),
                        if (it.unselected.isEmpty)
                          const Text('—', style: TextStyle(color: Colors.grey))
                        else
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: it.unselected
                                .map((s) => _OptionChip(label: s, selected: false))
                                .toList(),
                          ),
                      ],
                    ],
                  ),
                );
              },
            ),
          ),

          // Composer only when DM selected
          if (showComposer) const _ComposerBar(),
        ],
      ),
    );
  }
}

class _QABundle {
  final String question;
  final String type; // 'text' | 'textarea' | 'radio' | 'checkbox'
  final String answerText; // for text/textarea, or a readable join for choice
  final List<String> selected;
  final List<String> unselected;

  _QABundle({
    required this.question,
    required this.type,
    required this.answerText,
    this.selected = const [],
    this.unselected = const [],
  });
}

class _OptionChip extends StatelessWidget {
  final String label;
  final bool selected;
  const _OptionChip({required this.label, required this.selected});

  @override
  Widget build(BuildContext context) {
    final bg = selected ? Colors.blue.shade50 : Colors.grey.shade100;
    final fg = selected ? Colors.blue : Colors.grey.shade700;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(8)),
      child: Text(label, style: TextStyle(color: fg, fontWeight: FontWeight.w600)),
    );
    }
}

class _ComposerBar extends StatelessWidget {
  const _ComposerBar();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.only(left: 12, right: 12, top: 10, bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: const BorderRadius.vertical(bottom: Radius.circular(12)),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 4, offset: const Offset(0, -1)),
        ],
      ),
      child: Row(
        children: [
          const Icon(Icons.mic_none, color: Colors.grey),
          const SizedBox(width: 10),
          Expanded(
            child: TextField(
              decoration: InputDecoration(
                hintText: 'Write message',
                isDense: true,
                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
              ),
            ),
          ),
          const SizedBox(width: 10),
          IconButton(onPressed: () {}, icon: const Icon(Icons.attach_file_outlined), tooltip: 'Attach'),
          const SizedBox(width: 4),
          ElevatedButton.icon(
            onPressed: () {},
            icon: const Icon(Icons.send, size: 18),
            label: const Text('Send'),
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              backgroundColor: const Color(0xFF3E6AF2),
            ),
          ),
        ],
      ),
    );
  }
}

// ----------------------------- RIGHT (User details) ---------------------------

class _UserDetailsPane extends StatelessWidget {
  final String userName;
  final String role;
  final String description;
  final VoidCallback? onCall;
  final VoidCallback? onDM;
  final VoidCallback? onMail;

  const _UserDetailsPane({
    required this.userName,
    required this.role,
    required this.description,
    this.onCall,
    this.onDM,
    this.onMail,
  });

  Color _roleColor(String r) {
    switch (r.toLowerCase()) {
      case 'student':
        return const Color(0xFF3B82F6);
      case 'admin':
        return const Color(0xFFF59E0B);
      case 'brand':
        return const Color(0xFF8B5CF6);
      case 'school':
        return const Color(0xFF22C55E);
      default:
        return const Color(0xFF6B7280);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 6, offset: Offset(0, 3))],
      ),
      child: Column(
        children: [
          const SizedBox(height: 16),
          const CircleAvatar(
            radius: 28,
            backgroundColor: Color(0xFFFFE0E0),
            child: Icon(Icons.person, color: Colors.black87, size: 28),
          ),
          const SizedBox(height: 8),
          Text(userName, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
          const SizedBox(height: 4),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: _roleColor(role).withOpacity(0.12),
              borderRadius: BorderRadius.circular(999),
            ),
            child: Text(
              role,
              style: TextStyle(
                color: _roleColor(role),
                fontWeight: FontWeight.w600,
                fontSize: 12,
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Call / DM / Mail
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Row(
              children: [
                Expanded(child: _ActionButton(icon: Icons.call, label: 'Call', onPressed: onCall)),
                const SizedBox(width: 8),
                Expanded(child: _ActionButton(icon: Icons.chat_bubble_outline, label: 'DM', onPressed: onDM)),
                const SizedBox(width: 8),
                Expanded(child: _ActionButton(icon: Icons.mail_outline, label: 'Mail', onPressed: onMail)),
              ],
            ),
          ),
          const SizedBox(height: 12),

          // User description (readonly look)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: TextField(
              readOnly: true,
              controller: TextEditingController(text: description),
              maxLines: 3,
              decoration: InputDecoration(
                hintText: 'User description',
                filled: true,
                fillColor: const Color(0xFFF5F6FA),
                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),
        ],
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback? onPressed;
  const _ActionButton({required this.icon, required this.label, this.onPressed});

  @override
  Widget build(BuildContext context) {
    return OutlinedButton.icon(
      onPressed: onPressed,
      icon: Icon(icon, size: 18),
      label: Text(label),
      style: OutlinedButton.styleFrom(
        padding: const EdgeInsets.symmetric(vertical: 10),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }
}
