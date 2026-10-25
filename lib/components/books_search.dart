// lib/components/books_search_section.dart
import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:Marketing_Fruit/screens/dashboard/books_filter_controller.dart';
import 'package:provider/provider.dart';
// import 'package:Marketing_Fruit/components/books_filter_controller.dart';

class BooksSearchSection extends StatefulWidget {
  final VoidCallback onAddBook;
  const BooksSearchSection({super.key, required this.onAddBook});

  @override
  State<BooksSearchSection> createState() => _BooksSearchSectionState();
}

class _BooksSearchSectionState extends State<BooksSearchSection> {
  late final TextEditingController _searchCtrl;

  @override
  void initState() {
    super.initState();
    final filter = context.read<BooksFilterController>();
    _searchCtrl = TextEditingController(text: filter.search);
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final containerWidth = screenWidth * 0.90;
    final filter = context.watch<BooksFilterController>();

    return Center(
      child: Container(
        width: containerWidth,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          children: [
            /// 🔍 Search Bar (updates shared filter)
            Expanded(
              flex: 3,
              child: TextField(
                controller: _searchCtrl,
                onChanged: (v) => context.read<BooksFilterController>().setSearch(v),
                decoration: InputDecoration(
                  hintText: 'Search Books...',
                  prefixIcon: const Icon(Icons.search),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                ),
              ),
            ),
            const SizedBox(width: 16),

            /// 🏷️ Tag Filter Dropdown (options from Realtime DB; sets shared filter)
            Expanded(
              flex: 2,
              child: StreamBuilder<DatabaseEvent>(
                stream: FirebaseDatabase.instance.ref('books').onValue,
                builder: (context, snapshot) {
                  final Set<String> tagSet = <String>{};

                  if (snapshot.hasData && snapshot.data!.snapshot.value != null) {
                    final raw = snapshot.data!.snapshot.value;
                    if (raw is Map) {
                      raw.forEach((_, value) {
                        if (value is Map) {
                          final tagsRaw = (value['tags'] ?? '').toString();
                          tagsRaw
                              .split(',')
                              .map((s) => s.trim())
                              .where((s) => s.isNotEmpty)
                              .forEach(tagSet.add);
                        }
                      });
                    }
                  }

                  final items = ['All Tags', ...tagSet.toList()..sort()];
                  final current = items.contains(filter.tag) ? filter.tag : 'All Tags';

                  return DropdownButtonFormField<String>(
                    value: current,
                    items: items
                        .map((t) => DropdownMenuItem(value: t, child: Text(t)))
                        .toList(),
                    onChanged: (v) => context.read<BooksFilterController>().setTag(v),
                    decoration: InputDecoration(
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    ),
                    hint: const Text('Filter by Tag'),
                  );
                },
              ),
            ),
            const SizedBox(width: 16),

            /// ➕ Add Book Button
            ElevatedButton.icon(
              onPressed: widget.onAddBook,
              icon: const Icon(Icons.add),
              label: const Text("Add Book"),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
