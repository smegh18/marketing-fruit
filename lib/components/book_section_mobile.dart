import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:cached_network_image/cached_network_image.dart';

class BookSectionMobile extends StatefulWidget {
  final void Function(dynamic book)? onBookTap;
  final String nodePath;

  const BookSectionMobile({
    super.key,
    this.onBookTap,
    this.nodePath = 'books', // Default node path, override if needed
  });

  @override
  State<BookSectionMobile> createState() => _BookSectionMobileState();
}

class _BookSectionMobileState extends State<BookSectionMobile> {
  final List<Map<String, String>> categories = [
    {'label': 'All', 'query': ''},
    {'label': 'Fiction', 'query': 'Fiction'},
    {'label': 'Business', 'query': 'Business'},
    {'label': 'Sci-Fi', 'query': 'Science Fiction'},
    {'label': 'Education', 'query': 'Education'},
    {'label': 'Technology', 'query': 'Technology'},
  ];

  String selectedTag = '';

  Query _booksQuery() {
    // Fetch only published books and filter by tags (client-side)
    return FirebaseDatabase.instance
        .ref(widget.nodePath)
        .orderByChild('status')
        .equalTo('published');
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final double cardWidth = 140.0;
    final double cardHeight = 152.0;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Section title
          Text(
            "Books",
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
              fontSize: 20,
            ),
          ),
          const SizedBox(height: 12),

          // Category chips for filtering
          // SingleChildScrollView(
          //   scrollDirection: Axis.horizontal,
          //   child: Row(
          //     children: categories.map((category) {
          //       final isSelected = selectedTag == (category['query'] ?? '');
          //       return Padding(
          //         padding: const EdgeInsets.only(right: 8),
          //         child: ChoiceChip(
          //           label: Text(category['label']!),
          //           selected: isSelected,
          //           onSelected: (_) => setState(() {
          //             selectedTag = category['query']!;
          //           }),
          //         ),
          //       );
          //     }).toList(),
          //   ),
          // ),
          // const SizedBox(height: 8),

          // Main book list
          SizedBox(
            height: cardHeight + 86,
            child: StreamBuilder<DatabaseEvent>(
              stream: _booksQuery().onValue,
              builder: (context, snap) {
                if (snap.connectionState == ConnectionState.waiting) {
                  return const Center(
                      child: Padding(
                          padding: EdgeInsets.symmetric(vertical: 32),
                          child: CircularProgressIndicator()));
                }
                if (snap.hasError) {
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    child: Center(
                      child: Text('Failed to load books',
                          style: TextStyle(color: theme.colorScheme.error)),
                    ),
                  );
                }
                if (!snap.hasData || snap.data!.snapshot.value == null) {
                  return const Padding(
                    padding: EdgeInsets.symmetric(vertical: 16),
                    child: Center(
                        child: Text('No books found',
                            style: TextStyle(color: Colors.grey))),
                  );
                }

                // Data mapping and filtering
                final map = Map<dynamic, dynamic>.from(
                    snap.data!.snapshot.value as Map);

                final items = map.entries.map((e) {
                  final v = Map<String, dynamic>.from(e.value as Map);
                  v['id'] = e.key;
                  return v;
                }).where((b) {
                  if ((b['status'] ?? '') != 'published') return false;
                  if (selectedTag.isEmpty) return true;
                  final tags = (b['tags'] ?? '').toString();
                  return tags.toLowerCase().contains(selectedTag.toLowerCase());
                }).toList();

                // Optional: sort by updatedAt
                items.sort((a, b) =>
                    (b['updatedAt'] ?? '').toString().compareTo(
                      (a['updatedAt'] ?? '').toString(),
                    ));

                if (items.isEmpty) {
                  return const Padding(
                    padding: EdgeInsets.symmetric(vertical: 16),
                    child: Center(
                        child: Text('No books found',
                            style: TextStyle(color: Colors.grey))),
                  );
                }

                return ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: items.length,
                  separatorBuilder: (_, __) => const SizedBox(width: 14),
                  itemBuilder: (_, i) {
                    final book = items[i];

                    final String titleRaw =
                    (book['bookName'] ?? '').toString();
                    final String title =
                    titleRaw.trim().isEmpty ? 'Untitled' : titleRaw;
                    final String authors =
                    (book['authorName'] ?? 'Unknown').toString();
                    String thumb = (book['coverUrl'] ?? '').toString();
                    if (thumb.startsWith('http://')) {
                      thumb = thumb.replaceFirst('http://', 'https://');
                    }
                    if (thumb.isEmpty) {
                      thumb =
                      'https://via.placeholder.com/120x192.png?text=No+Cover';
                    }
                    final String tags = (book['tags'] ?? '').toString();
                    final String publishedAt =
                    (book['publishedAt'] ?? '').toString();
                    final String description =
                    (book['bookDescription'] ?? '').toString();

                    // Compatible volumeInfo shape
                    final gbCompatible = {
                      'volumeInfo': {
                        'title': title,
                        'authors': [authors],
                        'description': description,
                        'publishedDate': publishedAt,
                        'categories': tags.isNotEmpty ? [tags] : [],
                        'imageLinks': {'thumbnail': thumb},
                        'industryIdentifiers': [
                          {'identifier': 'N/A'}
                        ],
                        'language': 'en',
                        'pageCount': 0,
                      },
                    };

                    return GestureDetector(
                      onTap: () => widget.onBookTap?.call(gbCompatible),
                      child: Container(
                        width: cardWidth,
                        decoration: BoxDecoration(
                          color: theme.cardColor,
                          borderRadius: BorderRadius.circular(14),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.10),
                              blurRadius: 7,
                              spreadRadius: 1,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            ClipRRect(
                              borderRadius: const BorderRadius.vertical(
                                  top: Radius.circular(14)),
                              child: CachedNetworkImage(
                                imageUrl: thumb,
                                width: cardWidth,
                                height: cardHeight,
                                fit: BoxFit.cover,
                                errorWidget: (context, _, __) => Container(
                                  color: Colors.grey.shade200,
                                  width: cardWidth,
                                  height: cardHeight,
                                  alignment: Alignment.center,
                                  child: Icon(Icons.broken_image,
                                      size: 36, color: Colors.grey),
                                ),
                              ),
                            ),
                            Padding(
                              padding: const EdgeInsets.only(
                                  left: 8, top: 7, right: 8),
                              child: Text(
                                title,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 13),
                              ),
                            ),
                            Padding(
                              padding: const EdgeInsets.only(
                                  left: 8, right: 8, top: 2),
                              child: Text(
                                authors,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                    color: Colors.grey.shade700, fontSize: 11),
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
