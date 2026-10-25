// lib/components/book_dashboard_page.dart
import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:Marketing_Fruit/components/glasspopup.dart';
import 'package:Marketing_Fruit/screens/dashboard/books_filter_controller.dart';
import 'package:provider/provider.dart';

// ⬇️ Add your glass popup helper import
// import 'glass_popup.dart';

class BookDashboardPage extends StatelessWidget {
  const BookDashboardPage({super.key});

  @override
  Widget build(BuildContext context) {
    final filter = context.watch<BooksFilterController>();
    final screenSize = MediaQuery.of(context).size;
    final maxWidth = screenSize.width * 0.95;

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
              BoxShadow(color: Colors.black12, blurRadius: 6, offset: Offset(0, 3)),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                "Books List",
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),

              StreamBuilder<DatabaseEvent>(
                stream: FirebaseDatabase.instance.ref('books').onValue,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Padding(
                      padding: EdgeInsets.all(24.0),
                      child: Center(child: CircularProgressIndicator()),
                    );
                  }
                  if (snapshot.hasError) {
                    return Padding(
                      padding: const EdgeInsets.all(24.0),
                      child: Text('Error: ${snapshot.error}'),
                    );
                  }

                  final raw = snapshot.data?.snapshot.value;
                  if (raw == null) {
                    return const Padding(
                      padding: EdgeInsets.all(24.0),
                      child: Text('No books found.'),
                    );
                  }

                  final Map<dynamic, dynamic> map = raw as Map<dynamic, dynamic>;
                  final nowUtc = DateTime.now().toUtc();
                  final List<Map<String, dynamic>> books = [];

                  // Cleanup, normalize, build view list
                  map.forEach((key, value) {
                    if (value is! Map) return;
                    final id = key?.toString() ?? '';
                    final m = Map<String, dynamic>.from(value);

                    final statusRaw = (m['status']?.toString() ?? '').toLowerCase();
                    final createdAtStr = (m['createdAt']?.toString() ?? '');

                    // Hide drafts; delete drafts older than 1 hour
                    if (statusRaw == 'draft') {
                      final createdAt = DateTime.tryParse(createdAtStr)?.toUtc();
                      if (createdAt != null) {
                        final age = nowUtc.difference(createdAt);
                        if (age > const Duration(hours: 1)) {
                          FirebaseDatabase.instance.ref('books/$id').remove();
                        }
                      }
                      return;
                    }

                    // Normalize to published | unpublished
                    final normalizedStatus = statusRaw == 'published' ? 'published' : 'unpublished';
                    if (normalizedStatus != statusRaw) {
                      FirebaseDatabase.instance.ref('books/$id').update({
                        'status': normalizedStatus,
                        'updatedAt': nowUtc.toIso8601String(),
                      });
                      m['status'] = normalizedStatus;
                      m['updatedAt'] = nowUtc.toIso8601String();
                    }

                    m['id'] = id;
                    books.add(m);
                  });

                  // Tag filter
                  if (filter.tag != 'All Tags') {
                    final tagLower = filter.tag.toLowerCase();
                    books.retainWhere((b) {
                      final tags = (b['tags']?.toString() ?? '').toLowerCase();
                      return tags
                          .split(',')
                          .map((e) => e.trim())
                          .where((e) => e.isNotEmpty)
                          .any((e) => e == tagLower);
                    });
                  }

                  // Search filter
                  if (filter.search.isNotEmpty) {
                    books.retainWhere((b) {
                      final title = (b['bookName']?.toString() ?? '').toLowerCase();
                      return title.contains(filter.search);
                    });
                  }

                  // Sort by updatedAt desc
                  books.sort((a, b) {
                    final aTime = DateTime.tryParse(a['updatedAt']?.toString() ?? '')?.millisecondsSinceEpoch ?? 0;
                    final bTime = DateTime.tryParse(b['updatedAt']?.toString() ?? '')?.millisecondsSinceEpoch ?? 0;
                    return bTime.compareTo(aTime);
                  });

                  if (books.isEmpty) {
                    return const Padding(
                      padding: EdgeInsets.all(24.0),
                      child: Text('No books match your filters.'),
                    );
                  }

                  return _BooksTable(books: books);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _BooksTable extends StatelessWidget {
  final List<Map<String, dynamic>> books;
  const _BooksTable({required this.books});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (ctx, constraints) {
        final totalWidth = constraints.maxWidth;
        final isWide = totalWidth > 1200;
        final isMedium = totalWidth > 800;

        // Responsive column widths
        final columnWidths = <int, TableColumnWidth>{
          0: FlexColumnWidth(isWide ? 2.5 : (isMedium ? 2.0 : 1.8)), // Title
          1: FlexColumnWidth(isWide ? 2.0 : (isMedium ? 1.5 : 1.2)), // Author
          2: const FlexColumnWidth(1.0),                              // Genre
          3: FlexColumnWidth(isWide ? 1.8 : 1.5),                     // Updated
          4: FlexColumnWidth(isWide ? 1.5 : 1.2),                     // Status toggle
          5: const FlexColumnWidth(1.0),                              // Actions
        };

        return Table(
          columnWidths: columnWidths,
          defaultVerticalAlignment: TableCellVerticalAlignment.middle,
          children: [
            /// Header
            TableRow(
              decoration: BoxDecoration(color: Colors.grey[200]),
              children: const [
                Padding(padding: EdgeInsets.all(12), child: Text('Title', style: TextStyle(fontWeight: FontWeight.bold))),
                Padding(padding: EdgeInsets.all(12), child: Text('Author', style: TextStyle(fontWeight: FontWeight.bold))),
                Padding(padding: EdgeInsets.all(12), child: Text('Genre', style: TextStyle(fontWeight: FontWeight.bold))),
                Padding(padding: EdgeInsets.all(12), child: Text('Updated', style: TextStyle(fontWeight: FontWeight.bold))),
                Padding(padding: EdgeInsets.all(12), child: Text('Status', style: TextStyle(fontWeight: FontWeight.bold))),
                Padding(padding: EdgeInsets.all(12), child: Text('Actions', style: TextStyle(fontWeight: FontWeight.bold))),
              ],
            ),

            /// Data rows
            ...books.map((book) {
              final id = book['id'];
              final title = (book['bookName']?.toString() ?? '').trim();
              final author = (book['authorName']?.toString() ?? '').trim();
              final tags = (book['tags']?.toString() ?? '').trim();
              final genre = (tags.isNotEmpty) ? tags.split(',').first.trim() : '—';

              final updatedAt = book['updatedAt']?.toString();
              final updatedDisplay = _formatDate(updatedAt) ?? '—';

              final isPublished = (book['status']?.toString() ?? 'unpublished').toLowerCase() == 'published';

              return TableRow(
                children: [
                  Padding(padding: const EdgeInsets.all(12), child: Text(title.isNotEmpty ? title : 'Untitled')),
                  Padding(padding: const EdgeInsets.all(12), child: Text(author.isNotEmpty ? author : '—')),
                  Padding(padding: const EdgeInsets.all(12), child: Text(genre)),
                  Padding(padding: const EdgeInsets.all(12), child: Text(updatedDisplay)),

                  /// Status toggle
                  Padding(
                    padding: const EdgeInsets.all(12),
                    child: _StatusToggle(
                      bookId: id,
                      isPublished: isPublished,
                    ),
                  ),

                  /// Actions (Delete)
                  Padding(
                    padding: const EdgeInsets.all(12),
                    child: IconButton(
                      icon: const Icon(Icons.delete, color: Colors.red),
                      tooltip: "Delete this book",
                      onPressed: () async {
                        // ✅ GLASS POPUP CONFIRMATION (same behavior)
                        final confirm = await showGlassPopup<bool>(
                          context: context,
                          title: 'Delete Book',
                          dismissible: true,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Are you sure you want to delete "${title.isEmpty ? 'Untitled' : title}"?',
                                style: const TextStyle(color: Colors.white, fontSize: 16, height: 1.35),
                              ),
                              const Spacer(),
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
                                      onPressed: () => Navigator.pop(context, false),
                                      child: const Text('Cancel', style: TextStyle(fontWeight: FontWeight.w600)),
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: ElevatedButton(
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: Colors.red,
                                        padding: const EdgeInsets.symmetric(vertical: 14),
                                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                        elevation: 0,
                                      ),
                                      onPressed: () => Navigator.pop(context, true),
                                      child: const Text('Delete', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        );

                        if (confirm == true) {
                          await FirebaseDatabase.instance.ref('books/$id').remove();
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text('Book "${title.isEmpty ? 'Untitled' : title}" deleted')),
                            );
                          }
                        }
                      },
                    ),
                  ),
                ],
              );
            }),
          ],
        );
      },
    );
  }

  String? _formatDate(String? iso) {
    if (iso == null || iso.isEmpty) return null;
    try {
      final dt = DateTime.parse(iso).toLocal();
      final y = dt.year.toString().padLeft(4, '0');
      final m = dt.month.toString().padLeft(2, '0');
      final d = dt.day.toString().padLeft(2, '0');
      return '$y-$m-$d';
    } catch (_) {
      return null;
    }
  }
}

/// Status toggle widget that writes to Firebase on change.
class _StatusToggle extends StatefulWidget {
  final String bookId;
  final bool isPublished;
  const _StatusToggle({required this.bookId, required this.isPublished});

  @override
  State<_StatusToggle> createState() => _StatusToggleState();
}

class _StatusToggleState extends State<_StatusToggle> {
  late bool _value;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _value = widget.isPublished;
  }

  Future<void> _updateStatus(bool publish) async {
    setState(() => _saving = true);
    final now = DateTime.now().toUtc().toIso8601String();
    final ref = FirebaseDatabase.instance.ref('books/${widget.bookId}');
    final updates = <String, dynamic>{
      'status': publish ? 'published' : 'unpublished',
      'updatedAt': now,
    };
    // Optional: set/refresh publishedAt when turning ON
    if (publish) {
      updates['publishedAt'] = now;
    }
    try {
      await ref.update(updates);
      setState(() => _value = publish); // optimistic — stream will also refresh
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Switch.adaptive(
          value: _value,
          onChanged: _saving ? null : (v) => _updateStatus(v),
        ),
        const SizedBox(width: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            color: _value ? Colors.green.shade100 : Colors.grey.shade200,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            _value ? 'Published' : 'Unpublished',
            style: TextStyle(
              color: _value ? Colors.green : Colors.grey[700],
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }
}
