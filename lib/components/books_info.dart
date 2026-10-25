// lib/components/books_info.dart
import 'package:flutter/material.dart';
import 'package:Marketing_Fruit/screens/dashboard/book_creation_controller.dart';
import 'package:provider/provider.dart';

class BookInfoSection extends StatefulWidget {
  const BookInfoSection({super.key});

  @override
  State<BookInfoSection> createState() => _BookInfoSectionState();
}

class _BookInfoSectionState extends State<BookInfoSection> {
  static const List<String> kAllTags = [
    'Fiction',
    'Science',
    'Technology',
    'Education',
  ];

  bool _tagsExpanded = false;

  @override
  Widget build(BuildContext context) {
    final ctrl = context.watch<BookCreationController>();
    final screenWidth = MediaQuery.of(context).size.width;
    final containerWidth = screenWidth * 0.90;

    final selectedTags = _parseTags(ctrl.tags);

    return SingleChildScrollView(
      child: Container(
        width: containerWidth,
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Book Info', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 24),

            // ---- Book Name ----
            const Text('Book Name', style: TextStyle(fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            TextFormField(
              initialValue: ctrl.bookName,
              onChanged: ctrl.setBookName,
              decoration: _inputDecoration(),
            ),

            const SizedBox(height: 24),

            // ---- Book Description ----
            const Text('Book Description', style: TextStyle(fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            TextFormField(
              initialValue: ctrl.bookDescription,
              onChanged: ctrl.setBookDescription,
              maxLines: 4,
              decoration: _inputDecoration(),
            ),

            const SizedBox(height: 24),

            // ---- Author Name ----
            const Text('Author Name', style: TextStyle(fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            TextFormField(
              initialValue: ctrl.authorName,
              onChanged: ctrl.setAuthorName,
              decoration: _inputDecoration(),
            ),

            const SizedBox(height: 24),

            // ---- Author Description ----
            const Text('Author Description', style: TextStyle(fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            TextFormField(
              initialValue: ctrl.authorDescription,
              onChanged: ctrl.setAuthorDescription,
              maxLines: 3,
              decoration: _inputDecoration(),
            ),

            const SizedBox(height: 24),

            // ---- Tags ----
            const Text('Tags', style: TextStyle(fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),

            // Dropdown-like field
            GestureDetector(
              onTap: () => setState(() => _tagsExpanded = !_tagsExpanded),
              child: InputDecorator(
                decoration: _inputDecoration(),
                isEmpty: selectedTags.isEmpty,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        selectedTags.isEmpty
                            ? 'Select tags'
                            : selectedTags.join(', '),
                        style: TextStyle(
                          color: selectedTags.isEmpty ? Colors.grey[600] : Colors.black87,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    Icon(_tagsExpanded ? Icons.arrow_drop_up : Icons.arrow_drop_down),
                  ],
                ),
              ),
            ),

            // Expanded list below
            if (_tagsExpanded)
              Container(
                margin: const EdgeInsets.only(top: 4),
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey.shade400),
                  borderRadius: BorderRadius.circular(12),
                  color: Colors.grey.shade50,
                ),
                child: Column(
                  children: kAllTags.map((tag) {
                    final checked = selectedTags.contains(tag);
                    return CheckboxListTile(
                      dense: true,
                      value: checked,
                      title: Text(tag),
                      controlAffinity: ListTileControlAffinity.leading,
                      onChanged: (v) {
                        final newSet = {...selectedTags};
                        if (v == true) {
                          newSet.add(tag);
                        } else {
                          newSet.remove(tag);
                        }
                        ctrl.setTags(newSet.join(', '));
                      },
                    );
                  }).toList(),
                ),
              ),

            const SizedBox(height: 24),

            // ---- Amazon Link ----
            const Text('Amazon Link', style: TextStyle(fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            TextFormField(
              initialValue: ctrl.amazonLink,
              onChanged: ctrl.setAmazonLink,
              decoration: _inputDecoration(hint: 'Paste Amazon product URL here'),
            ),

            const SizedBox(height: 8),
            Text('Draft ID: ${ctrl.draftId}', style: TextStyle(color: Colors.grey[600], fontSize: 12)),

            const SizedBox(height: 8),
            Row(
              children: [
                const Text('Status: ', style: TextStyle(fontWeight: FontWeight.w600)),
                Text(ctrl.status),
              ],
            ),
          ],
        ),
      ),
    );
  }

  InputDecoration _inputDecoration({String? hint}) {
    return InputDecoration(
      hintText: hint,
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
    );
  }

  static Set<String> _parseTags(String raw) {
    if (raw.trim().isEmpty) return <String>{};
    return raw.split(',').map((s) => s.trim()).where((s) => s.isNotEmpty).toSet();
  }
}
