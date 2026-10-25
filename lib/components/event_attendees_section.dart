import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_quill/flutter_quill.dart' as quill;
import 'package:flutter_quill/quill_delta.dart' as quill;

class AttendiesSection extends StatelessWidget {
  final List<dynamic> vipList;
  const AttendiesSection({super.key, required this.vipList});

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
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Appearances By',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 24),
            if (vipList.isNotEmpty)
              ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: vipList.length,
                separatorBuilder: (_, __) => const Divider(),
                itemBuilder: (_, index) {
                  final v = vipList[index] is Map
                      ? Map<String, dynamic>.from(vipList[index] as Map)
                      : <String, dynamic>{};

                  return Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(Icons.person, size: 40),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              v['name'] ?? '',
                              style: const TextStyle(fontWeight: FontWeight.bold),
                            ),
                            Text('Profession: ${v['profession'] ?? ''}'),
                            Text('Organization: ${v['organization'] ?? ''}'),
                            Text('Role: ${v['role'] ?? ''}'),
                            Text(
                              'Appearance Time: ' +
                                  (v['appearanceTime'] is int
                                      ? _timeFromMillis(v['appearanceTime'])
                                      : v['appearanceTime'] ?? ''),
                            ),
                            Text('LinkedIn: ${v['linkedin'] ?? ''}'),
                            const SizedBox(height: 4),
                            _buildDescriptionWidget(v['description']),
                          ],
                        ),
                      ),
                    ],
                  );
                },
              )
            else
              const Text('No guests added yet.'),
          ],
        ),
      ),
    );
  }

  String _timeFromMillis(dynamic ms) {
    if (ms == null || ms == '') return '';
    try {
      final dt = DateTime.fromMillisecondsSinceEpoch(ms is int ? ms : int.parse(ms.toString()));
      return "${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}";
    } catch (_) {
      return ms.toString();
    }
  }

  // Renders the description as rich text if possible
  Widget _buildDescriptionWidget(dynamic desc) {
    if (desc == null) return const SizedBox();
    // Try parsing as Quill Delta from JSON or List/Map
    if (desc is String) {
      try {
        final decoded = jsonDecode(desc);
        final quill.Delta delta;
        if (decoded is Map && decoded['ops'] is List) {
          delta = quill.Delta.fromJson(decoded['ops']);
        } else if (decoded is List) {
          delta = quill.Delta.fromJson(decoded);
        } else {
          return Text(desc, style: const TextStyle(fontStyle: FontStyle.italic, color: Colors.grey));
        }

        return Padding(
          padding: const EdgeInsets.only(bottom: 4),
          child: quill.QuillEditor.basic(
            controller: quill.QuillController(
              document: quill.Document.fromDelta(delta),
              selection: const TextSelection.collapsed(offset: 0),
            ),

          ),
        );
      } catch (_) {
        // Not a Quill JSON? Fallback to plain string
        return Text(desc, style: const TextStyle(fontStyle: FontStyle.italic, color: Colors.grey));
      }
    }
    if (desc is List) {
      try {
        final delta = quill.Delta.fromJson(desc);
        return Padding(
          padding: const EdgeInsets.only(bottom: 4),
          child: quill.QuillEditor.basic(
            controller: quill.QuillController(
              document: quill.Document.fromDelta(delta),
              selection: const TextSelection.collapsed(offset: 0),
            ),

          ),
        );
      } catch (_) {
        return Text(
          desc.map((e) => e?.toString() ?? '').join(' '),
          style: const TextStyle(fontStyle: FontStyle.italic, color: Colors.grey),
        );
      }
    }
    if (desc is Map && desc['ops'] is List) {
      try {
        final delta = quill.Delta.fromJson(desc['ops']);
        return Padding(
          padding: const EdgeInsets.only(bottom: 4),
          child: quill.QuillEditor.basic(
            controller: quill.QuillController(
              document: quill.Document.fromDelta(delta),
              selection: const TextSelection.collapsed(offset: 0),
            ),

          ),
        );
      } catch (_) {
        return Text(
          desc['ops'].toString(),
          style: const TextStyle(fontStyle: FontStyle.italic, color: Colors.grey),
        );
      }
    }
    // Fallback
    return Text(desc.toString(), style: const TextStyle(fontStyle: FontStyle.italic, color: Colors.grey));
  }
}
