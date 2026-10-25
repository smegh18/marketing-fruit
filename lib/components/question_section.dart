
import 'package:flutter/material.dart';

class QuestionsSection extends StatefulWidget {
  final void Function(List<Map<String, dynamic>>) onQuestionsChanged;
  const QuestionsSection({super.key, required this.onQuestionsChanged});

  @override
  State<QuestionsSection> createState() => _QuestionsSectionState();
}

class _QuestionsSectionState
    extends State<QuestionsSection> {
  final TextEditingController _questionController = TextEditingController();
  final TextEditingController _optionController = TextEditingController();
  final TextEditingController _hintController = TextEditingController();

  String _selectedAnswerType = 'Short Answer';
  final List<String> _options = [];

  final List<Map<String, dynamic>> _questions = [];

  final List<String> _answerTypes = [
    'Short Answer',
    'Paragraph',
    'Radio',
    'Checkboxes',
  ];

  void _addOption() {
    final option = _optionController.text.trim();
    if (option.isNotEmpty) {
      setState(() {
        _options.add(option);
        _optionController.clear();
      });
    }
  }

  void _addQuestion() {
    String questionText = _questionController.text.trim();
    String hintText = _hintController.text.trim();

    if (questionText.isEmpty) return;

    if (_selectedAnswerType == 'Short Answer' ||
        _selectedAnswerType == 'Paragraph') {
      setState(() {
        _questions.add({
          'question': questionText,
          'type': _selectedAnswerType,
          'hint': hintText,
        });
        _questionController.clear();
        _hintController.clear();
        _selectedAnswerType = 'Short Answer';
      });
    } else {
      setState(() {
        _questions.add({
          'question': questionText,
          'type': _selectedAnswerType,
          'options': List<String>.from(_options),
          'selected': _selectedAnswerType == 'Radio'
              ? null
              : <String>[], // For checkboxes
        });
        _questionController.clear();
        _options.clear();
        _selectedAnswerType = 'Short Answer';
        widget.onQuestionsChanged(_questions);
      });
    }
  }

  void _deleteQuestion(int index) {
    setState(() {
      _questions.removeAt(index);
      widget.onQuestionsChanged(_questions);
    });
  }

  Widget _buildAnswerInputFields() {
    if (_selectedAnswerType == 'Radio' ||
        _selectedAnswerType == 'Checkboxes') {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 16),
          const Text('Answer Options',
              style: TextStyle(fontWeight: FontWeight.w600)),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _optionController,
                  decoration: InputDecoration(
                    hintText: 'Enter option',
                    contentPadding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              ElevatedButton.icon(
                onPressed: _addOption,
                icon: const Icon(Icons.add),
                label: const Text("Add"),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 4,
            children: _options.map((opt) => Chip(label: Text(opt))).toList(),
          ),
        ],
      );
    } else if (_selectedAnswerType == 'Short Answer' ||
        _selectedAnswerType == 'Paragraph') {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 16),
          const Text('Hint for User',
              style: TextStyle(fontWeight: FontWeight.w600)),
          const SizedBox(height: 8),
          TextField(
            controller: _hintController,
            decoration: InputDecoration(
              hintText: _selectedAnswerType == 'Paragraph'
                  ? 'Enter hint for paragraph answer...'
                  : 'Enter hint for short answer...',
              contentPadding:
              const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
              border:
              OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            ),
            maxLines: _selectedAnswerType == 'Paragraph' ? 3 : 1,
          ),
        ],
      );
    }
    return const SizedBox.shrink();
  }

  Widget _buildAnswerTypePreview(int index) {
    final q = _questions[index];
    final type = q['type'];
    final options = q['options'] ?? [];
    final hint = q['hint'] ?? '';

    switch (type) {
      case 'Short Answer':
        return TextField(
          enabled: false,
          decoration: InputDecoration(
            hintText: hint.isNotEmpty ? hint : 'Your answer...',
            border: const OutlineInputBorder(),
          ),
        );
      case 'Paragraph':
        return TextField(
          enabled: false,
          maxLines: 3,
          decoration: InputDecoration(
            hintText: hint.isNotEmpty ? hint : 'Your paragraph answer...',
            border: const OutlineInputBorder(),
          ),
        );
      case 'Radio':
        return Column(
          children: options.map<Widget>((opt) {
            return RadioListTile<String>(
              controlAffinity: ListTileControlAffinity.leading,
              title: Text(opt),
              value: opt,
              groupValue: q['selected'],
              onChanged: (_) {},
            );
          }).toList(),
        );
      case 'Checkboxes':
        return Column(
          children: options.map<Widget>((opt) {
            return CheckboxListTile(
              controlAffinity: ListTileControlAffinity.leading,
              title: Text(opt),
              value: false,
              onChanged: (_) {},
            );
          }).toList(),
        );
      default:
        return const SizedBox.shrink();
    }
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
                'Event Attendees Questions',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 24),

              const Text('Question',
                  style: TextStyle(fontWeight: FontWeight.w600)),
              const SizedBox(height: 8),
              TextField(
                controller: _questionController,
                decoration: InputDecoration(
                  hintText: 'Enter your question...',
                  contentPadding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
              ),
              const SizedBox(height: 16),

              const Text('Answer Type',
                  style: TextStyle(fontWeight: FontWeight.w600)),
              const SizedBox(height: 8),
              DropdownButtonFormField<String>(
                value: _selectedAnswerType,
                items: _answerTypes
                    .map((type) =>
                    DropdownMenuItem(value: type, child: Text(type)))
                    .toList(),
                onChanged: (value) {
                  if (value != null) {
                    setState(() {
                      _selectedAnswerType = value;
                      _options.clear();
                      _hintController.clear();
                    });
                  }
                },
                decoration: InputDecoration(
                  contentPadding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
              ),

              _buildAnswerInputFields(),

              const SizedBox(height: 16),
              Align(
                alignment: Alignment.centerRight,
                child: ElevatedButton.icon(
                  onPressed: _addQuestion,
                  icon: const Icon(Icons.add),
                  label: const Text("Add Question"),
                ),
              ),
              const SizedBox(height: 32),

              if (_questions.isNotEmpty) ...[
                const Text(
                  'Preview Questions',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 12),
                ..._questions.asMap().entries.map((entry) {
                  final index = entry.key;
                  final q = entry.value;
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
                            q['question'] ?? '',
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 12),
                          _buildAnswerTypePreview(index),
                          const SizedBox(height: 12),
                          Align(
                            alignment: Alignment.centerRight,
                            child: IconButton(
                              icon: const Icon(Icons.delete, color: Colors.red),
                              onPressed: () => _deleteQuestion(index),
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                })
              ]
            ],
          ),
        ),
      ),
    );
  }
}
