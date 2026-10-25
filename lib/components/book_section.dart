import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';

class BookSectionWidget extends StatefulWidget {
  /// Optional: pass a different RTDB node (e.g., "researchReports")
  final String nodePath;
  final void Function(dynamic book)? onBookTap;

  const BookSectionWidget({
    super.key,
    this.onBookTap,
    this.nodePath = 'books',
  });

  @override
  State<BookSectionWidget> createState() => _BookSectionWidgetState();
}

class _BookSectionWidgetState extends State<BookSectionWidget> {
  // Optional quick client-side filtering via tag string (comma-separated in DB).
  final List<Map<String, String>> _chips = const [
    {'label': 'All', 'query': ''},
    {'label': 'Fiction', 'query': 'Fiction'},
    {'label': 'Business', 'query': 'Business'},
    {'label': 'Technology', 'query': 'Technology'},
    {'label': 'Education', 'query': 'Education'},
  ];

  final String _selectedTag = '';

  Query _booksQuery() {
    // Server-side: status == "published"
    return FirebaseDatabase.instance
        .ref(widget.nodePath)
        .orderByChild('status')
        .equalTo('published');
  }

  @override
  Widget build(BuildContext context) {
    final w = MediaQuery.of(context).size.width;
    final h = MediaQuery.of(context).size.height;
    final scale =
        (MediaQuery.of(context).devicePixelRatio.clamp(1.0, 1.2)) * 0.6;
    final theme = Theme.of(context);

    return Container(
      width: w * 0.92,
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // --- OPTIONAL: enable these chips for quick tag filtering ---
          // Wrap(
          //   spacing: 8,
          //   runSpacing: 6,
          //   children: _chips.map((c) {
          //     final isSel = _selectedTag == (c['query'] ?? '');
          //     return ChoiceChip(
          //       label: Text(c['label']!),
          //       selected: isSel,
          //       onSelected: (_) => setState(() => _selectedTag = c['query']!),
          //     );
          //   }).toList(),
          // ),
          Container(
            decoration: BoxDecoration(
              color: theme.cardColor,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.5),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                )
              ],
            ),
            padding: const EdgeInsets.all(12),
            child: SizedBox(
              height: h * 0.32,
              child: StreamBuilder<DatabaseEvent>(
                stream: _booksQuery().onValue,
                builder: (context, snap) {
                  if (snap.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  if (snap.hasError) {
                    return Center(
                      child: Text(
                        'Failed to load books',
                        style: TextStyle(color: theme.colorScheme.error),
                      ),
                    );
                  }
                  if (!snap.hasData || snap.data!.snapshot.value == null) {
                    return const Center(child: Text('No books found'));
                  }

                  // {bookId: {bookName, authorName, coverUrl, ...}, ...}
                  final map = Map<dynamic, dynamic>.from(
                      snap.data!.snapshot.value as Map);

                  // Map → List + client-side tag filter
                  final items = map.entries.map((e) {
                    final v = Map<String, dynamic>.from(e.value as Map);
                    v['id'] = e.key; // keep the ID if needed later
                    return v;
                  }).where((b) {
                    // Safety: only published (though already filtered at query)
                    if ((b['status'] ?? '') != 'published') return false;

                    if (_selectedTag.isEmpty) return true;
                    final tags = (b['tags'] ?? '').toString();
                    return tags.toLowerCase().contains(_selectedTag.toLowerCase());
                  }).toList();

                  // Optional: newest first if you store updatedAt
                  items.sort((a, b) =>
                      (b['updatedAt'] ?? '').toString().compareTo(
                            (a['updatedAt'] ?? '').toString(),
                          ));

                  if (items.isEmpty) {
                    return const Center(child: Text('No books found'));
                  }

                  final ctrl = ScrollController();

                  return Scrollbar(
                    controller: ctrl,
                    thumbVisibility: true,
                    child: ListView.separated(
                      controller: ctrl,
                      scrollDirection: Axis.horizontal,
                      padding: const EdgeInsets.only(bottom: 12),
                      itemCount: items.length,
                      separatorBuilder: (_, __) => const SizedBox(width: 12),
                      itemBuilder: (_, i) {
                        final book = items[i];

                        final String titleRaw = (book['bookName'] ?? '').toString();
                        final String title =
                            titleRaw.trim().isEmpty ? 'Untitled' : titleRaw;

                        final String authors =
                            (book['authorName'] ?? 'Unknown').toString();

                        // Ensure https + fallback placeholder
                        String thumb = (book['coverUrl'] ?? '').toString();
                        if (thumb.startsWith('http://')) {
                          thumb = thumb.replaceFirst('http://', 'https://');
                        }
                        if (thumb.isEmpty) {
                          thumb =
                              'https://via.placeholder.com/150x200.png?text=No+Cover';
                        }

                        final String tags = (book['tags'] ?? '').toString();
                        final String publishedAt =
                            (book['publishedAt'] ?? '').toString();
                        final String description =
                            (book['bookDescription'] ?? '').toString();

                        // Adapt to BookDetailPage’s Google-Books-like shape
                        final gbCompatible = {
                          'volumeInfo': {
                            'title': title,
                            'authors': [authors],
                            'description': description,
                            'publishedDate': publishedAt,
                            'categories': tags.isNotEmpty ? [tags] : [],
                            'imageLinks': {'thumbnail': thumb},

                            // 🔗 add these for BookDetailPage resolvers:
                            'pdfUrl': (book['pdfUrl'] ?? '').toString(),
                            'amazonLink': ((book['amazonLink'] ?? book['buyUrl']) ?? '').toString(),
                          },
                          // 🔗 also keep top-level fallbacks BookDetailPage checks:
                          'pdfUrl': (book['pdfUrl'] ?? '').toString(),
                          'amazonLink': ((book['amazonLink'] ?? book['buyUrl']) ?? '').toString(),
                          // (Optional) keep raw for future-proofing:
                          'raw': book,
                        };


                        return GestureDetector(
                          onTap: () {
                            debugPrint('[BookSectionWidget] Tapped: $title');
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('Opening Book Detail...')),
                              );
                            }
                            // ✅ Pass the *raw* RTDB map so BookDetailPage can resolve pdf/amazon/etc.
                            widget.onBookTap?.call({
                              'raw': book, // keep everything
                              // (Optional) Provide convenience fields for the grid’s title/cover if you want:
                              'title': title,
                              'author': authors,
                              'imageUrl': thumb,
                            });
                          },


                          child: Container(
                            width: w * 0.2,
                            margin: const EdgeInsets.only(bottom: 4),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(8),
                              color: theme.cardColor,
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.5),
                                  spreadRadius: 2,
                                  blurRadius: 5,
                                  offset: const Offset(0, 3),
                                )
                              ],
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                ClipRRect(
                                  borderRadius: const BorderRadius.vertical(
                                    top: Radius.circular(8),
                                  ),
                                  child: SizedBox(
                                    height: (h * 0.32) * 0.75,
                                    width: double.infinity,
                                    child: Image.network(
                                      thumb,
                                      fit: BoxFit.contain,
                                      alignment: Alignment.topCenter,
                                      errorBuilder: (context, error, stackTrace) => Container(
                                        color: Colors.grey.shade300,
                                        alignment: Alignment.center,
                                        child: Icon(
                                          Icons.broken_image,
                                          size: 40,
                                          color: Colors.grey.shade600,
                                        ),
                                      ),
                                      loadingBuilder: (context, child, progress) {
                                        if (progress == null) return child;
                                        return const Center(
                                          child: CircularProgressIndicator(),
                                        );
                                      },
                                    ),
                                  ),
                                ),
                                Padding(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 2,
                                  ),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        title,
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: TextStyle(
                                          fontSize:
                                              scale == 0.6 ? 14 : 14 * scale,
                                          fontWeight: FontWeight.w600,
                                          color: theme.hintColor,
                                        ),
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        authors,
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: TextStyle(
                                          fontSize:
                                              scale == 0.6 ? 12 : 12 * scale,
                                          fontWeight: FontWeight.w400,
                                          color:
                                              theme.hintColor.withOpacity(0.7),
                                        ),
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
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}
