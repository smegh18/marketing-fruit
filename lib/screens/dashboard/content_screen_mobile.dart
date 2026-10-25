import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:xml/xml.dart';
import 'package:firebase_database/firebase_database.dart';

import '../../components/book_section_mobile.dart';
import '../../components/spotify_section_mobile.dart';
import '../../components/youtube_section_mobile.dart';
import '../../components/categories_section_mobile.dart';

class ContentScreenMobile extends StatefulWidget {
  final void Function(String videoId)? onVideoTap;
  final void Function(dynamic book)? onBookTap;
  final void Function(Map<String, dynamic>)? onPodcastTap;

  /// NEW: open Research Detail inside app
  final void Function(Map<String, dynamic>)? onResearchTap;

  const ContentScreenMobile({
    super.key,
    this.onVideoTap,
    this.onBookTap,
    this.onPodcastTap,
    this.onResearchTap,
  });

  @override
  State<ContentScreenMobile> createState() => _ContentScreenMobileState();
}

class _ContentScreenMobileState extends State<ContentScreenMobile> {
  final List<String> categories = [
    'All',
    'Books',
    'Podcast',
    'Videos',
    'Research Reports',
  ];
  String selectedCategory = 'All';
  List<dynamic> categoryItems = [];
  int itemsToShow = 12;
  bool isLoading = false;
  final TextEditingController _searchCtrl = TextEditingController();

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<void> onCategorySelected(String category) async {
    setState(() {
      selectedCategory = category;
      categoryItems = [];
      itemsToShow = 12;
      isLoading = true;
    });

    // "All" & "Books" are handled below (Books via RTDB stream).
    if (category == 'All') {
      setState(() => isLoading = false);
      return;
    }

    List<dynamic> fetched = [];
    switch (category) {
      case 'Books':
        // Stream handles Books; nothing to fetch here.
        break;
      case 'Research Reports':
        // NEW: Fetch from WordPress REST API
        fetched = await fetchResearchReports();
        break;
      case 'Videos':
        fetched = await fetchVideos();
        break;
      case 'Podcast':
        fetched = await fetchLibsynEpisodes();
        break;
    }

    if (!mounted) return;
    setState(() {
      categoryItems = fetched;
      isLoading = false;
    });
  }

  Future<List<dynamic>> fetchVideos() async {
    const apiKey = String.fromEnvironment('YOUTUBE_API_KEY');
    const channelId = 'UCXD2w9cm2BKLxkCzCk_rTLg';
    final url =
        'https://www.googleapis.com/youtube/v3/search?part=snippet&channelId=$channelId&order=date&maxResults=40&type=video&key=$apiKey';

    final response = await http.get(Uri.parse(url));
    if (response.statusCode == 200) {
      final items = json.decode(response.body)['items'];
      return items.where((item) => item['id']?['videoId'] != null).toList();
    }
    return [];
  }

  Future<List<dynamic>> fetchLibsynEpisodes() async {
    final resp = await http.get(Uri.parse('https://feeds.libsyn.com/561905/rss'));
    if (resp.statusCode == 200) {
      final doc = XmlDocument.parse(resp.body);
      final items = doc.findAllElements('item');
      return items.map((item) {
        final title = item.getElement('title')?.text ?? '';
        final description = item.getElement('description')?.text ?? '';
        final pubDate = item.getElement('pubDate')?.text ?? '';
        final enclosure = item.getElement('enclosure');
        final audioUrl = enclosure?.getAttribute('url') ?? '';
        final imageUrl = item.findElements('itunes:image').isNotEmpty
            ? item.findElements('itunes:image').first.getAttribute('href') ?? ''
            : '';
        return {
          'title': title,
          'description': description,
          'pubDate': pubDate,
          'audioUrl': audioUrl,
          'imageUrl': imageUrl,
        };
      }).toList();
    } else {
      return [];
    }
  }

  /// NEW: Fetch Research Reports (WordPress)
  Future<List<Map<String, dynamic>>> fetchResearchReports() async {
    final uri = Uri.parse(
      'https://marketingfruit.net/wp-json/wp/v2/posts?per_page=40&_embed=1',
    );
    try {
      final resp = await http.get(uri);
      if (resp.statusCode != 200) {
        debugPrint('WP posts error: ${resp.statusCode} ${resp.body}');
        return [];
      }
      final List data = jsonDecode(resp.body);
      return data.map<Map<String, dynamic>>((raw) {
        final title = _stripHtml((raw['title']?['rendered'] ?? '').toString());
        final excerpt = (raw['excerpt']?['rendered'] ?? '').toString();
        final contentHtml = (raw['content']?['rendered'] ?? '').toString();
        final date = (raw['date'] ?? '').toString();
        final link = (raw['link'] ?? '').toString();

        // Try embedded featured image
        String imageUrl = '';
        try {
          final embedded = raw['_embedded'] as Map<String, dynamic>?;
          if (embedded != null &&
              embedded['wp:featuredmedia'] is List &&
              (embedded['wp:featuredmedia'] as List).isNotEmpty) {
            final media = embedded['wp:featuredmedia'][0] as Map<String, dynamic>;
            imageUrl = (media['media_details']?['sizes']?['medium']?['source_url'] ??
                        media['source_url'] ??
                        '')
                .toString();
          }
        } catch (_) {}

        return {
          'title': title,
          'excerpt': excerpt,         // keep HTML; we strip for display on card
          'contentHtml': contentHtml, // HTML
          'date': date,               // ISO
          'link': link,
          'imageUrl': imageUrl,
        };
      }).toList();
    } catch (e) {
      debugPrint('WP posts fetch exception: $e');
      return [];
    }
  }

  String _stripHtml(String html) {
    return html
        .replaceAll(RegExp(r'<[^>]*>|&[^;]+;'), ' ')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
  }

  double _getAspectRatioForCategory(String category) {
    switch (category) {
      case 'Books':
        return 0.7;
      case 'Research Reports':
        return 0.95; // article card
      case 'Videos':
      case 'Podcast':
        return 1.1;
      default:
        return 1.0;
    }
  }

  /// Stream published books from RTDB (Books only on mobile now)
  Stream<List<Map<String, dynamic>>> _booksStream() {
    final ref = FirebaseDatabase.instance.ref('books');
    final stream = ref.orderByChild('status').equalTo('published').onValue;
    return stream.map((event) {
      final data = event.snapshot.value;
      if (data is Map) {
        final all = data.entries.map<Map<String, dynamic>>((e) {
          final raw = (e.value as Map).map((k, v) => MapEntry(k.toString(), v));
          return _extractBookFields(raw, key: e.key.toString());
        }).toList();
        return all;
      }
      return <Map<String, dynamic>>[];
    });
  }

  Map<String, dynamic> _extractBookFields(Map<String, dynamic> raw, {String? key}) {
    final title = (raw['title'] ?? raw['bookName'] ?? raw['name'] ?? '').toString();
    final author = (raw['author'] ?? raw['authorName'] ?? '').toString();
    final imageUrl = (raw['image'] ??
        raw['cover'] ??
        raw['coverImage'] ??
        raw['thumbnail'] ??
        raw['coverUrl'] ??
        '')
        .toString();
    return {
      '_key': key,
      'title': title,
      'author': author,
      'imageUrl': imageUrl,
      'type': raw['type'],
      'contentType': raw['contentType'],
      'isReport': raw['isReport'],
      'raw': raw,
    };
  }

  Widget buildCategoryCard(dynamic item, String category) {
    switch (category) {
      case 'Books':
        return BookCard(item: item, onTap: (map) => widget.onBookTap?.call(map['raw'] ?? map));
      case 'Research Reports':
        return ResearchReportCardMobile(
          item: (item as Map<String, dynamic>),
          onTap: widget.onResearchTap,
        );
      case 'Videos':
        return VideoCard(item: item, onTap: widget.onVideoTap);
      case 'Podcast':
        return PodcastCard(item: item, onTap: widget.onPodcastTap);
      default:
        return const SizedBox.shrink();
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final spacing = 18.0;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.only(bottom: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Search & Filter Bar
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: TextField(
                  controller: _searchCtrl,
                  decoration: InputDecoration(
                    hintText: "Search",
                    prefixIcon: const Icon(Icons.search),
                    fillColor: Colors.grey.shade100,
                    filled: true,
                    contentPadding:
                        const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(30),
                      borderSide: BorderSide(color: Colors.grey.shade300),
                    ),
                  ),
                  onChanged: (query) {
                    // (Optional) local filter
                  },
                ),
              ),
              const SizedBox(height: 16),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8.0),
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: categories.map((cat) {
                      final selected = selectedCategory == cat;
                      return Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 4),
                        child: ChoiceChip(
                          selected: selected,
                          label: Text(
                            cat,
                            style: TextStyle(
                              color: selected ? Colors.white : Colors.black87,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          selectedColor: Colors.black87,
                          backgroundColor: Colors.grey.shade200,
                          onSelected: (val) => onCategorySelected(cat),
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ),
              SizedBox(height: spacing),

              // Non-"All" views
              if (selectedCategory != 'All')
                (
                  (selectedCategory == 'Books')
                    // Books: RTDB stream
                    ? StreamBuilder<List<Map<String, dynamic>>>(
                        stream: _booksStream(),
                        builder: (context, snapshot) {
                          if (snapshot.connectionState == ConnectionState.waiting) {
                            return const Center(
                              child: Padding(
                                padding: EdgeInsets.symmetric(vertical: 50),
                                child: CircularProgressIndicator(),
                              ),
                            );
                          }
                          final books = snapshot.data ?? const [];
                          if (books.isEmpty) {
                            return const Padding(
                              padding: EdgeInsets.symmetric(vertical: 24),
                              child: Text('No items found.'),
                            );
                          }
                          final count = itemsToShow.clamp(0, books.length);
                          return Column(
                            children: [
                              GridView.builder(
                                shrinkWrap: true,
                                physics: const NeverScrollableScrollPhysics(),
                                itemCount: count,
                                gridDelegate: SliverGridDelegateWithMaxCrossAxisExtent(
                                  maxCrossAxisExtent: 210,
                                  mainAxisSpacing: 14,
                                  crossAxisSpacing: 10,
                                  childAspectRatio: _getAspectRatioForCategory(selectedCategory),
                                ),
                                itemBuilder: (context, idx) {
                                  final item = books[idx];
                                  return BookCard(
                                    item: item,
                                    onTap: (map) => widget.onBookTap?.call(map['raw'] ?? map),
                                  );
                                },
                              ),
                              if (itemsToShow < books.length)
                                TextButton(
                                  onPressed: () {
                                    setState(() {
                                      itemsToShow += 10;
                                    });
                                  },
                                  child: const Text('Show More'),
                                ),
                            ],
                          );
                        },
                      )
                    // Research/Podcast/Videos: fetched lists
                    : (
                        isLoading
                        ? const Center(
                            child: Padding(
                              padding: EdgeInsets.symmetric(vertical: 50),
                              child: CircularProgressIndicator(),
                            ),
                          )
                        : Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 8.0),
                            child: Column(
                              children: [
                                GridView.builder(
                                  shrinkWrap: true,
                                  physics: const NeverScrollableScrollPhysics(),
                                  itemCount: itemsToShow.clamp(0, categoryItems.length),
                                  gridDelegate: SliverGridDelegateWithMaxCrossAxisExtent(
                                    maxCrossAxisExtent: 210,
                                    mainAxisSpacing: 14,
                                    crossAxisSpacing: 10,
                                    childAspectRatio: _getAspectRatioForCategory(selectedCategory),
                                  ),
                                  itemBuilder: (context, idx) {
                                    final item = categoryItems[idx];
                                    return buildCategoryCard(item, selectedCategory);
                                  },
                                ),
                                if (itemsToShow < categoryItems.length)
                                  TextButton(
                                    onPressed: () {
                                      setState(() {
                                        itemsToShow += 10;
                                      });
                                    },
                                    child: const Text("Show More"),
                                  ),
                              ],
                            ),
                          )
                      )
                ),

              // "All" view
              if (selectedCategory == 'All') ...[
                YouTubeSectionMobile(heading: 'Latest Featured', onVideoTap: widget.onVideoTap),
                SizedBox(height: spacing),
                YouTubeSectionMobile(heading: 'Related Videos', onVideoTap: widget.onVideoTap),
                SizedBox(height: spacing),
                YouTubeSectionMobile(onVideoTap: widget.onVideoTap),
                SizedBox(height: spacing),
                LibsynPodcastSectionMobile(onPodcastTap: widget.onPodcastTap),
                SizedBox(height: spacing),
                BookSectionMobile(onBookTap: widget.onBookTap),
              ],
              Padding(
                padding: const EdgeInsets.only(top: 18.0, left: 10, right: 10),
                child: CategoriesSectionMobile(
                  categories: [
                    CategoryItem(name: "Category 1", imagePath: "assets/Assets/bandar.png"),
                    CategoryItem(name: "Category 2", imagePath: "assets/Assets/music.png"),
                    CategoryItem(name: "Category 3", imagePath: "assets/Assets/paint.png"),
                    CategoryItem(name: "Category 4", imagePath: "assets/Assets/taklu.png"),
                    CategoryItem(name: "Category 5", imagePath: "assets/Assets/choti.png"),
                  ],
                ),
              ),
              const SizedBox(height: 22),
            ],
          ),
        ),
      ),
    );
  }
}

/// --------- Helper Cards ---------

class VideoCard extends StatelessWidget {
  final dynamic item;
  final void Function(String videoId)? onTap;
  const VideoCard({super.key, required this.item, this.onTap});
  @override
  Widget build(BuildContext context) {
    final videoId = item['id']['videoId'];
    final snippet = item['snippet'];
    final title = snippet['title'] ?? '';
    final thumbnailUrl = snippet['thumbnails']?['high']?['url'];
    final theme = Theme.of(context);
    return GestureDetector(
      onTap: () => onTap?.call(videoId),
      child: Card(
        elevation: 10,
        shadowColor: Colors.black.withOpacity(0.6),
        color: theme.cardColor,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AspectRatio(
              aspectRatio: 16 / 9,
              child: ClipRRect(
                borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
                child: Image.network(
                  thumbnailUrl ?? '',
                  width: double.infinity,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) => Container(
                    color: Colors.grey.shade300,
                    alignment: Alignment.center,
                    child: Icon(Icons.broken_image, size: 40, color: Colors.grey.shade600),
                  ),
                  loadingBuilder: (context, child, progress) {
                    if (progress == null) return child;
                    return const Center(child: CircularProgressIndicator());
                  },
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(6.0),
              child: Text(
                title,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class PodcastCard extends StatelessWidget {
  final Map<String, dynamic> item;
  final void Function(Map<String, dynamic>)? onTap;
  const PodcastCard({super.key, required this.item, this.onTap});
  @override
  Widget build(BuildContext context) {
    final title = item['title']?.toString() ?? 'Untitled';
    final imageUrl = item['imageUrl']?.toString();
    final theme = Theme.of(context);
    return GestureDetector(
      onTap: () => onTap?.call(item),
      child: Card(
        elevation: 10,
        shadowColor: Colors.black.withOpacity(0.6),
        color: theme.cardColor,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AspectRatio(
              aspectRatio: 16 / 9,
              child: ClipRRect(
                borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
                child: imageUrl != null && imageUrl.isNotEmpty
                    ? Image.network(
                        imageUrl,
                        width: double.infinity,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) => Container(
                          color: Colors.grey.shade300,
                          alignment: Alignment.center,
                          child: Icon(Icons.podcasts, size: 40, color: Colors.grey.shade600),
                        ),
                        loadingBuilder: (context, child, progress) {
                          if (progress == null) return child;
                          return const Center(child: CircularProgressIndicator());
                        },
                      )
                    : Container(
                        width: double.infinity,
                        color: Colors.grey.shade300,
                        alignment: Alignment.center,
                      ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Text(
                title,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class BookCard extends StatelessWidget {
  final Map<String, dynamic> item;
  final void Function(Map<String, dynamic>)? onTap;
  const BookCard({super.key, required this.item, this.onTap});
  @override
  Widget build(BuildContext context) {
    final title = (item['title'] ?? '').toString();
    final author = (item['author'] ?? '').toString();
    final imageUrl = (item['imageUrl'] ?? '').toString();
    final theme = Theme.of(context);

    return InkWell(
      onTap: () => onTap?.call(item),
      borderRadius: BorderRadius.circular(12),
      child: Card(
        elevation: 8,
        shadowColor: Colors.black.withOpacity(0.5),
        color: theme.cardColor,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              flex: 3,
              child: ClipRRect(
                borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
                child: imageUrl.isNotEmpty
                    ? Image.network(
                        imageUrl,
                        width: double.infinity,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => _placeholder(),
                      )
                    : _placeholder(),
              ),
            ),
            Expanded(
              flex: 1,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(8, 8, 8, 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Text(
                        title.isEmpty ? 'Untitled' : title,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                      ),
                    ),
                    if (author.isNotEmpty)
                      Text(
                        author,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 12,
                          color: Theme.of(context)
                              .textTheme
                              .bodySmall
                              ?.color
                              ?.withOpacity(0.75),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _placeholder() => Container(
        width: double.infinity,
        color: Colors.grey.shade300,
        alignment: Alignment.center,
        child: Icon(Icons.menu_book, size: 40, color: Colors.grey.shade600),
      );
}

/// NEW: Research card for mobile
class ResearchReportCardMobile extends StatelessWidget {
  final Map<String, dynamic> item;
  final void Function(Map<String, dynamic>)? onTap;

  const ResearchReportCardMobile({
    super.key,
    required this.item,
    this.onTap,
  });

  String _stripHtml(String html) {
    return html
        .replaceAll(RegExp(r'<[^>]*>|&[^;]+;'), ' ')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final title = (item['title'] ?? '').toString();
    final excerptHtml = (item['excerpt'] ?? '').toString();
    final excerpt = _stripHtml(excerptHtml);
    final imageUrl = (item['imageUrl'] ?? '').toString();

    return Card(
      elevation: 10,
      shadowColor: Colors.black.withOpacity(0.6),
      color: theme.cardColor,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () => onTap?.call(item),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AspectRatio(
              aspectRatio: 16 / 9,
              child: ClipRRect(
                borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
                child: imageUrl.isNotEmpty
                    ? Image.network(
                        imageUrl,
                        width: double.infinity,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => _placeholder(),
                      )
                    : _placeholder(),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(10, 10, 10, 6),
              child: Text(
                title.isEmpty ? 'Untitled' : title,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
              ),
            ),
            // Padding(
            //   padding: const EdgeInsets.fromLTRB(10, 0, 10, 6),
            //   child: Text(
            //     excerpt,
            //     maxLines: 3,
            //     overflow: TextOverflow.ellipsis,
            //     style: TextStyle(
            //       fontSize: 12.5,
            //       color: Theme.of(context).textTheme.bodySmall?.color?.withOpacity(0.8),
            //     ),
            //   ),
            // ),
            // const Spacer(),
            // Padding(
            //   padding: const EdgeInsets.fromLTRB(10, 0, 10, 10),
            //   child: Row(
            //     children: [
            //       TextButton.icon(
            //         onPressed: () => onTap?.call(item),
            //         icon: const Icon(Icons.chrome_reader_mode, size: 16),
            //         label: const Text('Read More'),
            //       ),
            //     ],
            //   ),
            // ),
          ],
        ),
      ),
    );
  }

  Widget _placeholder() => Container(
        width: double.infinity,
        color: Colors.grey.shade300,
        alignment: Alignment.center,
        child: Icon(Icons.article, size: 40, color: Colors.grey.shade600),
      );
}
