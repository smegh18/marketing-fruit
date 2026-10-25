import 'package:flutter/material.dart';

class EventAttendeesQuestionSection extends StatefulWidget {
  final List<dynamic> questions;
  final void Function(List<Map<String, dynamic>> answers)? onSubmitted;

  const EventAttendeesQuestionSection({
    super.key,
    required this.questions,
    this.onSubmitted,
  });

  @override
  State<EventAttendeesQuestionSection> createState() => _EventAttendeesQuestionSectionState();
}

class _EventAttendeesQuestionSectionState extends State<EventAttendeesQuestionSection> {
  late List<Map<String, dynamic>> _questions;

  @override
  void initState() {
    super.initState();
    _questions = widget.questions.map<Map<String, dynamic>>((q) {
      if (q is Map<String, dynamic>) return {...q};
      if (q is Map) return Map<String, dynamic>.from(q);
      return {};
    }).toList();

    for (final q in _questions) {
      final type = (q['type'] ?? '').toString().toLowerCase().trim();
      if (type == 'radio' || type == 'multiple choice') {
        q['type'] = 'Radio';
      } else if (type == 'checkboxes' || type == 'checkbox') {
        q['type'] = 'Checkboxes';
      } else if (type == 'short answer') {
        q['type'] = 'Short Answer';
      } else if (type == 'paragraph') {
        q['type'] = 'Paragraph';
      }
      if (q['options'] is! List) {
        if (q['options'] is String && (q['options'] as String).isNotEmpty) {
          try {
            final opt = q['options'] as String;
            if (opt.trim().startsWith("[")) {
              q['options'] = List<String>.from(opt.replaceAll(RegExp(r'[\[\]\"]'), '').split(",").map((e) => e.trim()));
            } else {
              q['options'] = [opt];
            }
          } catch (_) {
            q['options'] = <String>[];
          }
        } else {
          q['options'] = <String>[];
        }
      }
      if (q['options'] is List) {
        q['options'] = (q['options'] as List).map((e) => e.toString()).toList();
      }
      if (q['type'] == 'Checkboxes' && q['selected'] == null) q['selected'] = <String>[];
      if (q['type'] == 'Radio' && q['selected'] == null) q['selected'] = null;
    }
  }

  Widget _buildAnswerTypePreview(Map<String, dynamic> q) {
    final type = q['type'] ?? '';
    final List<String> options = (q['options'] is List) ? List<String>.from(q['options']) : <String>[];
    final hint = q['hint'] ?? '';
    final bool locked = q['locked'] == true;

    switch (type) {
      case 'Short Answer':
        return TextField(
          enabled: !locked,
          onChanged: (val) => q['selected'] = val,
          decoration: InputDecoration(
            hintText: hint.isNotEmpty ? hint : 'Your answer...',
            border: const OutlineInputBorder(),
          ),
        );
      case 'Paragraph':
        return TextField(
          enabled: !locked,
          maxLines: 3,
          onChanged: (val) => q['selected'] = val,
          decoration: InputDecoration(
            hintText: hint.isNotEmpty ? hint : 'Your paragraph answer...',
            border: const OutlineInputBorder(),
          ),
        );
      case 'Radio':
        return Column(
          children: options.map((opt) {
            return RadioListTile<String>(
              title: Text(opt),
              value: opt,
              groupValue: q['selected'],
              onChanged: locked
                  ? null
                  : (value) {
                setState(() {
                  q['selected'] = value;
                });
              },
            );
          }).toList(),
        );
      case 'Checkboxes':
        List<String> selList = (q['selected'] is List)
            ? List<String>.from(q['selected'])
            : <String>[];
        return Column(
          children: options.map((opt) {
            final isSelected = selList.contains(opt);
            return CheckboxListTile(
              title: Text(opt),
              value: isSelected,
              controlAffinity: ListTileControlAffinity.leading,
              onChanged: locked
                  ? null
                  : (checked) {
                setState(() {
                  if (checked == true && !selList.contains(opt)) {
                    selList.add(opt);
                  } else if (checked == false && selList.contains(opt)) {
                    selList.remove(opt);
                  }
                  q['selected'] = selList;
                });
              },
            );
          }).toList(),
        );
      default:
        return const Text("Unsupported question type");
    }
  }

  /// On submission, callback with answers to parent
  void handleSubmission() {
    final answers = _questions.map((q) {
      return {
        'question': q['question'],
        'answer': q['selected'],
        'type': q['type'],
      };
    }).toList();
    if (widget.onSubmitted != null) widget.onSubmitted!(answers);
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final containerWidth = screenWidth * 0.90;

    return Center(
      child: Container(
        width: containerWidth,
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
        ),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Event Questions',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 24),
              if (_questions.isEmpty)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 16.0),
                  child: Text(
                    "No questions for this event.",
                    style: TextStyle(color: Colors.grey),
                  ),
                )
              else ..._questions.map((q) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: 20),
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.grey[100],
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.grey.shade300),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          (q['question'] ?? '').toString(),
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 12),
                        _buildAnswerTypePreview(q),
                      ],
                    ),
                  ),
                );
              }),
              const SizedBox(height: 16),
              Align(
                alignment: Alignment.centerRight,
                child: ElevatedButton(
                  onPressed: handleSubmission,
                  child: const Text('Save & Next'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
