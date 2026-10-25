import 'dart:async';
import 'dart:convert';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:xml/xml.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:path/path.dart' as path;
import '../../components/book_section.dart';
// import '../../components/category_filter_bar.dart'; // removed – replaced with inline header
import '../../components/youtube_section.dart';
import '../../components/spotify_section.dart';

// If you use these elsewhere on this screen, keep them.

class ContentScreen extends StatefulWidget {
  final void Function(String videoId)? onVideoTap;
  final void Function(dynamic book)? onBookTap;
  final void Function(Map<String, dynamic>)? onPodcastTap;
  final void Function(Map<String, dynamic>)? onResearchTap;

  const ContentScreen({
    super.key,
    this.onVideoTap,
    this.onBookTap,
    this.onPodcastTap,
    this.onResearchTap,
  });

  @override
  State<ContentScreen> createState() => _ContentScreenState();
}

class _ContentScreenState extends State<ContentScreen> {
  
  final List<String> categories = const [
    'All',
    'Books',
    'Podcast',
    'Videos',
    'Blogs',
  ];

  String selectedCategory = 'All';

  /// Per-category fetched lists (non-Books categories).
  List<dynamic> categoryItems = [];
  List<dynamic> _rawCategoryItems = [];

  /// Global search state (All tab).
  List<_UnifiedItem> _globalResults = [];
  List<_UnifiedItem> _globalRaw = [];
  bool _globalSearching = false;
  int _globalItemsToShow = 18;

  /// Common UI state.
  int itemsToShow = 18;
  bool isLoading = false;

  /// Search state + debounce.
  final TextEditingController _searchCtrl = TextEditingController();
  String _searchQuery = '';
  Timer? _searchDebounce;
  String? _currentlyFetchingCategory;


  @override
  void initState() {
    super.initState();
    // final playerDetails = PlayerDetails();
    // final balance = playerDetails.fetchBalance();
    // if (balance == null) {
    //   playerDetails.initWallet();
    // }
  }

  @override
  void dispose() {
    _searchDebounce?.cancel();
    _searchCtrl.dispose();
    super.dispose();
  }

  // ----------------------
  // Category switching
  // ----------------------

  Future<void> onCategorySelected(String category) async {
    if (selectedCategory == category) return;

    setState(() {
      selectedCategory = category;
      itemsToShow = 18;
      categoryItems = [];
      _rawCategoryItems = [];
      isLoading = category != 'All'; // Load indicator for specific categories except 'All'
    });

    _currentlyFetchingCategory = category;

    if (category == 'All') {
      // For All, no blocking loader - maybe load curated or global results
      setState(() {
        isLoading = false;
      });
      return;
    }

    List<dynamic> fetched = [];

    try {
      switch (category) {
        case 'Books':
        // Books come from stream builder, not fetched here.
          fetched = [];
          break;
        case 'Blogs':
          fetched = await fetchResearchReports();
          break;
        case 'Videos':
          fetched = await fetchVideos();
          break;
        case 'Podcast':
          fetched = await fetchLibsynEpisodes();
          break;
        default:
          fetched = [];
      }

      // Check if category has changed since fetch started.
      if (!mounted || selectedCategory != _currentlyFetchingCategory) {
        return; // Category changed during fetch, ignore outdated results.
      }

      setState(() {
        _rawCategoryItems = fetched;
        categoryItems = _filterListForCategory(_rawCategoryItems, '', selectedCategory);
        isLoading = false;
      });
    } catch (e) {
      // Handle or log error.
      if (!mounted || selectedCategory != _currentlyFetchingCategory) return;
      setState(() {
        isLoading = false;
      });
    } finally {
      _currentlyFetchingCategory = null;
    }
  }

  // ----------------------
  // Remote fetchers
  // ----------------------

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


  Future<List<Map<String, dynamic>>> fetchLibsynEpisodes() async {
    const proxyUrl = 'https://us-central1-marketingfruit-9e24d.cloudfunctions.net/rssProxy';

    try {
      final resp = await http.get(Uri.parse(proxyUrl));
      if (resp.statusCode != 200) {
        // For debugging purposes
        print('Failed to fetch Libsyn feed: ${resp.body}');
        return [];
      }

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
    } catch (e, stack) {
      // Handles network or parsing errors
      print('Exception fetching/parsing Libsyn feed: $e\n$stack');
      return [];
    }
  }


  Future<String?> getOrUploadReportImage(String wpImageUrl, String firebaseKey) async {
    if (wpImageUrl.isEmpty) return null;

    final fileName = firebaseKey + path.extension(wpImageUrl).split('?').first;
    final ref = FirebaseStorage.instance.ref().child('report_images/$fileName');

    try {
      // Try fetching download URL (may throw if not present)
      final url = await ref.getDownloadURL();
      return url;
    } catch (e) {
      // Not in Firebase, fetch via AllOrigins
      try {
        final proxyUrl = 'https://api.allorigins.win/raw?url=${Uri.encodeComponent(wpImageUrl)}';
        final response = await http.get(Uri.parse(proxyUrl));
        if (response.statusCode != 200) return null;
        final data = response.bodyBytes;
        final uploadTask = await ref.putData(
          data,
          SettableMetadata(contentType: _getMimeType(wpImageUrl)),
        );
        final downloadUrl = await uploadTask.ref.getDownloadURL();
        return downloadUrl;
      } catch (e) {
        // Could not fetch/upload
        return null;
      }
    }
  }

// Infer mime type from extension for Content-Type
  String _getMimeType(String url) {
    final ext = path.extension(url).toLowerCase();
    switch (ext) {
      case '.png':
        return 'image/png';
      case '.jpg':
      case '.jpeg':
        return 'image/jpeg';
      case '.gif':
        return 'image/gif';
      case '.webp':
        return 'image/webp';
      default:
        return 'application/octet-stream';
    }
  }

  Future<List<Map<String, dynamic>>> fetchResearchReports() async {
    final uri = Uri.parse('https://marketingfruit.net/wp-json/wp/v2/posts?per_page=40&_embed=1');
    try {
      final resp = await http.get(uri);
      if (resp.statusCode != 200) {
        debugPrint("WP posts error ${resp.statusCode} ${resp.body}");
        return [];
      }
      final List data = jsonDecode(resp.body);
      return await Future.wait(data.map<Future<Map<String, dynamic>>>((
          raw,
          ) async {
        final title = _stripHtml(raw['title']?['rendered'] ?? '').toString();
        final excerpt = raw['excerpt']?['rendered'] ?? '';
        final contentHtml = raw['content']?['rendered'] ?? '';
        final date = raw['date'] ?? '';
        final link = raw['link'] ?? '';
        String imageUrl = '';
        try {
          final embedded = raw['_embedded'] as Map<String, dynamic>?;
          if (embedded != null &&
              embedded['wp:featuredmedia'] is List &&
              (embedded['wp:featuredmedia'] as List).isNotEmpty) {
            final media = embedded['wp:featuredmedia'][0] as Map<String, dynamic>;
            imageUrl = media['media_details']?['sizes']?['medium']?['source_url'] ??
                media['source_url'] ??
                '';
          }
        } catch (_) {}

        // New logic: Check/upload to Firebase
        String? finalImageUrl = '';
        if (imageUrl.isNotEmpty) {
          final slugKey = raw['slug'] ?? raw['id'].toString();
          finalImageUrl = await getOrUploadReportImage(imageUrl, slugKey);
        }

        return {
          'title': title,
          'excerpt': excerpt,
          'contentHtml': contentHtml,
          'date': date,
          'link': link,
          'imageUrl': finalImageUrl,
        };
      }).toList());
    } catch (e) {
      debugPrint("WP posts fetch exception $e");
      return [];
    }
  }


  Future<List<Map<String, dynamic>>> fetchBooksOnce() async {
    // One-time RTDB snapshot of published books for global search
    try {
      final snap = await FirebaseDatabase.instance
          .ref('books')
          .orderByChild('status')
          .equalTo('published')
          .get();

      if (!snap.exists) return [];
      final raw = snap.value;
      if (raw is! Map) return [];

      final List<Map<String, dynamic>> list = [];
      raw.forEach((key, value) {
        if (value is Map) {
          final map = value.map((k, v) => MapEntry(k.toString(), v));
          list.add(_extractBookFields(map, key: key.toString()));
        }
      });
      return list;
    } catch (e) {
      debugPrint('Books fetch exception: $e');
      return [];
    }
  }

  // ----------------------
  // Text helpers
  // ----------------------

  String _stripHtml(String html) {
    return html
        .replaceAll(RegExp(r'<[^>]*>|&[^;]+;'), ' ')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
  }

  // ----------------------
  // Aspect ratio helpers
  // ----------------------

  double _getAspectRatioForCategory(String category) {
    switch (category) {
      case 'Videos':
      case 'Podcast':
        return 1.3;
      case 'Books':
        return 0.75;
      case 'Blogs':
        return 0.95;
      default:
        return 1.0;
    }
  }

  // ----------------------
  // Books stream (per-category "Books" tab)
  // ----------------------

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
    final imageUrl =
        (raw['image'] ?? raw['cover'] ?? raw['coverUrl'] ?? raw['thumbnail'] ?? '')
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

  // ----------------------
  // Search (category + global)
  // ----------------------

  void _onSearchChanged(String q) {
    _searchDebounce?.cancel();
    _searchDebounce = Timer(const Duration(milliseconds: 300), () {
      if (!mounted) return;
      final newQuery = q.trim();
      setState(() {
        _searchQuery = newQuery;
      });

      // Global search in All tab
      if (selectedCategory == 'All') {
        if (_searchQuery.isEmpty) {
          // Clear global results, show curated "All"
          setState(() {
            _globalResults = [];
            _globalRaw = [];
            _globalItemsToShow = 18;
            _globalSearching = false;
          });
        } else {
          _triggerGlobalSearch(_searchQuery);
        }
        return;
      }

      // Category-specific filtering (non-Books, non-All)
      if (selectedCategory != 'Books') {
        setState(() {
          categoryItems =
              _filterListForCategory(_rawCategoryItems, _searchQuery, selectedCategory);
          itemsToShow = 18;
        });
      }
      // Books tab is filtered inside StreamBuilder.
    });
  }

  List<dynamic> _filterListForCategory(
    List<dynamic> items,
    String query,
    String category,
  ) {
    if (query.isEmpty) return List<dynamic>.from(items);
    final lowerQ = query.toLowerCase();

    bool matches(dynamic item) {
      switch (category) {
        case 'Videos':
          final title = (item['snippet']?['title'] ?? '').toString().toLowerCase();
          final desc = (item['snippet']?['description'] ?? '').toString().toLowerCase();
          return title.contains(lowerQ) || desc.contains(lowerQ);
        case 'Podcast':
          final title = (item['title'] ?? '').toString().toLowerCase();
          final desc = (item['description'] ?? '').toString().toLowerCase();
          return title.contains(lowerQ) || desc.contains(lowerQ);
        case 'Blogs':
          final title = (item['title'] ?? '').toString().toLowerCase();
          final ex = _stripHtml((item['excerpt'] ?? '').toString()).toLowerCase();
          return title.contains(lowerQ) || ex.contains(lowerQ);
        default:
          return true;
      }
    }

    return items.where(matches).toList();
  }

  bool _bookMatchesQuery(Map<String, dynamic> book, String query) {
    if (query.isEmpty) return true;
    final q = query.toLowerCase();
    final t = (book['title'] ?? '').toString().toLowerCase();
    final a = (book['author'] ?? '').toString().toLowerCase();
    return t.contains(q) || a.contains(q);
  }

  // ---------- Global search (All tab) ----------

  Future<void> _triggerGlobalSearch(String query) async {
    setState(() {
      _globalSearching = true;
      _globalItemsToShow = 18;
    });

    try {
      // Fire all requests concurrently
      final results = await Future.wait([
        fetchVideos(),
        fetchLibsynEpisodes(),
        fetchResearchReports(),
        fetchBooksOnce(),
      ]);

      final videos = results[0];
      final podcasts = results[1];
      final research = results[2] as List<Map<String, dynamic>>;
      final books = results[3] as List<Map<String, dynamic>>;

      // Filter by query for each source
      final vFiltered = _filterListForCategory(videos, query, 'Videos')
          .map<_UnifiedItem>((it) => _UnifiedItem.video(it))
          .toList();

      final pFiltered = _filterListForCategory(podcasts, query, 'Podcast')
          .map<_UnifiedItem>((it) => _UnifiedItem.podcast(Map<String, dynamic>.from(it)))
          .toList();

      final rFiltered = _filterListForCategory(research, query, 'Blogs')
          .map<_UnifiedItem>((it) => _UnifiedItem.research(it))
          .toList();

      final bFiltered = books
          .where((b) => _bookMatchesQuery(b, query))
          .map<_UnifiedItem>((b) => _UnifiedItem.book(b))
          .toList();

      // Merge all, you can sort by recency if you have dates for all
      final merged = <_UnifiedItem>[
        ...vFiltered,
        ...pFiltered,
        ...rFiltered,
        ...bFiltered,
      ];

      setState(() {
        _globalRaw = merged;
        _globalResults = merged;
        _globalSearching = false;
      });
    } catch (e) {
      debugPrint('Global search error: $e');
      setState(() {
        _globalRaw = [];
        _globalResults = [];
        _globalSearching = false;
      });
    }
  }

  // ----------------------
  // Build
  // ----------------------

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;
    final horizontalPadding = screenWidth * 0.01;
    final verticalPadding = screenHeight * 0.03;
    final spacing = screenHeight * 0.02;

    final showGridLike = selectedCategory == 'Videos' ||
        selectedCategory == 'Podcast' ||
        selectedCategory == 'Books' ||
        selectedCategory == 'Blogs' ||
        (selectedCategory == 'All' && _searchQuery.isNotEmpty);

    return Container(
      width: double.infinity, // full width container
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.5),
            spreadRadius: 2,
            blurRadius: 5,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: SingleChildScrollView(
        padding: EdgeInsets.symmetric(
          horizontal: horizontalPadding,
          vertical: verticalPadding,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // NEW: Tabs (left) + Search (right) in a single full-width header
            _TabsAndSearchBar(
              categories: categories,
              selected: selectedCategory,
              controller: _searchCtrl,
              onCategoryTap: onCategorySelected,
              onChanged: _onSearchChanged,
            ),

            SizedBox(height: spacing * 0.8),

            // ----------- ALL tab: Global Search Results -----------
            if (selectedCategory == 'All' && _searchQuery.isNotEmpty) ...[
              if (_globalSearching) const CircularProgressIndicator(),
              if (!_globalSearching && _globalResults.isEmpty)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 24),
                  child: Text('No results found.'),
                ),
              if (!_globalSearching && _globalResults.isNotEmpty)
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.only(bottom: 8.0),
                      child: Text(
                        'Search Results',
                        style: Theme.of(context)
                            .textTheme
                            .titleMedium
                            ?.copyWith(fontWeight: FontWeight.bold),
                      ),
                    ),
                    GridView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: _globalItemsToShow.clamp(0, _globalResults.length),
                      gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                        maxCrossAxisExtent: 320,
                        mainAxisSpacing: 12,
                        crossAxisSpacing: 12,
                        childAspectRatio: 1.05,
                      ),
                      itemBuilder: (context, index) {
                        final u = _globalResults[index];
                        return _buildUnifiedCard(u);
                      },
                    ),
                    if (_globalItemsToShow < _globalResults.length)
                      TextButton(
                        onPressed: () {
                          setState(() => _globalItemsToShow += 15);
                        },
                        child: const Text('Show More'),
                      ),
                  ],
                ),
            ],

            // ----------- Category tabs -----------
            if (selectedCategory != 'All')
              isLoading &&
                      (selectedCategory == 'Videos' ||
                          selectedCategory == 'Podcast' ||
                          selectedCategory == 'Blogs')
                  ? const CircularProgressIndicator()
                  : Column(
                      children: [
                        if (selectedCategory == 'Videos' ||
                            selectedCategory == 'Podcast' ||
                            selectedCategory == 'Blogs')
                          GridView.builder(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            itemCount: itemsToShow.clamp(0, categoryItems.length),
                            gridDelegate: SliverGridDelegateWithMaxCrossAxisExtent(
                              maxCrossAxisExtent:
                                  selectedCategory == 'Blogs' ? 360 : 320,
                              mainAxisSpacing: 12,
                              crossAxisSpacing: 12,
                              childAspectRatio:
                                  _getAspectRatioForCategory(selectedCategory),
                            ),
                            itemBuilder: (context, index) {
                              final item = categoryItems[index];
                              return buildCategoryCard(item, selectedCategory);
                            },
                          ),

                        if ((selectedCategory == 'Videos' ||
                                selectedCategory == 'Podcast' ||
                                selectedCategory == 'Blogs') &&
                            itemsToShow < categoryItems.length)
                          TextButton(
                            onPressed: () {
                              setState(() {
                                itemsToShow += 15;
                              });
                            },
                            child: const Text("Show More"),
                          ),

                        if (selectedCategory == 'Books')
                          StreamBuilder<List<Map<String, dynamic>>>(
                            stream: _booksStream(),
                            builder: (context, snapshot) {
                              if (snapshot.connectionState == ConnectionState.waiting) {
                                return const Center(child: CircularProgressIndicator());
                              }
                              final allBooks = snapshot.data ?? const [];
                              final filtered = _searchQuery.isEmpty
                                  ? allBooks
                                  : allBooks
                                      .where((b) => _bookMatchesQuery(b, _searchQuery))
                                      .toList();
                              if (filtered.isEmpty) {
                                return const Padding(
                                  padding: EdgeInsets.symmetric(vertical: 24),
                                  child: Text('No items found.'),
                                );
                              }

                              final count = itemsToShow.clamp(0, filtered.length);
                              return Column(
                                children: [
                                  GridView.builder(
                                    shrinkWrap: true,
                                    physics: const NeverScrollableScrollPhysics(),
                                    itemCount: count,
                                    gridDelegate:
                                        const SliverGridDelegateWithMaxCrossAxisExtent(
                                      maxCrossAxisExtent: 220,
                                      mainAxisSpacing: 12,
                                      crossAxisSpacing: 12,
                                      childAspectRatio: 0.62,
                                    ),
                                    itemBuilder: (context, index) {
                                      final item = filtered[index];
                                      return BookCard(
                                        item: item,
                                        onTap: (map) =>
                                            widget.onBookTap?.call(map['raw'] ?? map),
                                      );
                                    },
                                  ),
                                  if (itemsToShow < filtered.length)
                                    TextButton(
                                      onPressed: () {
                                        setState(() {
                                          itemsToShow += 15;
                                        });
                                      },
                                      child: const Text('Show More'),
                                    ),
                                ],
                              );
                            },
                          ),
                      ],
                    ),

            // ----------- Curated ALL view (no search) -----------
            if (selectedCategory == 'All' && _searchQuery.isEmpty) ...[
              YouTubeSectionWidget(onVideoTap: widget.onVideoTap, showFilters: false),
              SizedBox(height: spacing),
              LibsynPodcastSectionWidget(onPodcastTap: widget.onPodcastTap),
              SizedBox(height: spacing),
              YouTubeSectionWidget(
                heading: 'Latest Featured',
                showFilters: false,
                onVideoTap: widget.onVideoTap,
              ),
              SizedBox(height: spacing),
              YouTubeSectionWidget(
                heading: 'Related Videos',
                showFilters: false,
                onVideoTap: widget.onVideoTap,
              ),
              SizedBox(height: spacing),
              BookSectionWidget(onBookTap: widget.onBookTap),
            ],

            SizedBox(height: spacing),
          ],
        ),
      ),
    );
  }

  // ----------------------
  // Card delegates
  // ----------------------

  Widget buildCategoryCard(dynamic item, String category) {
    switch (category) {
      case 'Videos':
        return VideoCard(item: item, onTap: widget.onVideoTap);
      case 'Podcast':
        return PodcastCard(
            item: Map<String, dynamic>.from(item), onTap: widget.onPodcastTap);
      case 'Blogs':
        return ResearchReportCard(
            item: (item as Map<String, dynamic>), onTap: widget.onResearchTap);
      default:
        return const SizedBox.shrink();
    }
  }

  Widget _buildUnifiedCard(_UnifiedItem u) {
    switch (u.kind) {
      case _Kind.video:
        return VideoCard(item: u.video!, onTap: widget.onVideoTap);
      case _Kind.podcast:
        return PodcastCard(item: u.podcast!, onTap: widget.onPodcastTap);
      case _Kind.research:
        return ResearchReportCard(item: u.research!, onTap: widget.onResearchTap);
      case _Kind.book:
        return BookCard(
            item: u.book!, onTap: (map) => widget.onBookTap?.call(map['raw'] ?? map));
    }
  }
}

/// ---------------------------------------------------------------------------
/// Header: Tabs (left) + Search (right) in the same full-width container
/// ---------------------------------------------------------------------------

class _TabsAndSearchBar extends StatelessWidget {
  final List<String> categories;
  final String selected;
  final TextEditingController controller;
  final void Function(String) onCategoryTap;
  final void Function(String) onChanged;

  const _TabsAndSearchBar({
    required this.categories,
    required this.selected,
    required this.controller,
    required this.onCategoryTap,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return LayoutBuilder(
      builder: (context, constraints) {
        final isNarrow = constraints.maxWidth < 760;

        final chipsRow = Wrap(
          spacing: 8,
          runSpacing: 8,
          children: categories.map((c) {
            final bool isSel = c == selected;
            return ChoiceChip(
              label: Text(c),
              selected: isSel,
              onSelected: (_) => onCategoryTap(c),
              labelStyle: TextStyle(
                color: isSel ? Colors.white : Theme.of(context).textTheme.bodyMedium?.color,
                fontWeight: isSel ? FontWeight.w700 : FontWeight.w500,
              ),
              selectedColor: Colors.black,
              backgroundColor: theme.cardColor,
              labelPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              shape: StadiumBorder(
                side: BorderSide(
                  color: isSel ? Colors.black : theme.dividerColor.withOpacity(0.6),
                ),
              ),
            );
          }).toList(),
        );

        final searchField = ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 420, minWidth: 240),
          child: _SearchField(
            controller: controller,
            onChanged: onChanged,
          ),
        );

        return Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: theme.colorScheme.surface,
            borderRadius: BorderRadius.circular(28),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.12),
                blurRadius: 14,
                spreadRadius: 1,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: isNarrow
              ? Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    chipsRow,
                    const SizedBox(height: 12),
                    Align(alignment: Alignment.centerRight, child: searchField),
                  ],
                )
              : Row(
                  children: [
                    Expanded(
                      child: Align(
                        alignment: Alignment.centerLeft,
                        child: chipsRow,
                      ),
                    ),
                    const SizedBox(width: 12),
                    searchField,
                  ],
                ),
        );
      },
    );
  }
}

class _SearchField extends StatelessWidget {
  final TextEditingController controller;
  final void Function(String) onChanged;

  const _SearchField({
    required this.controller,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return TextField(
      controller: controller,
      onChanged: onChanged,
      textInputAction: TextInputAction.search,
      decoration: InputDecoration(
        hintText: 'Search',
        prefixIcon: const Icon(Icons.search),
        isDense: true,
        filled: true,
        fillColor: theme.cardColor,
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(28),
          borderSide: BorderSide(color: theme.dividerColor.withOpacity(0.6)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(28),
          borderSide: BorderSide(color: theme.dividerColor.withOpacity(0.6)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(28),
          borderSide: const BorderSide(color: Colors.black),
        ),
      ),
    );
  }
}

/// ----------------------
/// Helper Cards (unchanged)
/// ----------------------

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

  const PodcastCard({
    super.key,
    required this.item,
    this.onTap,
  });

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

class ResearchReportCard extends StatelessWidget {
  final Map<String, dynamic> item;
  final void Function(Map<String, dynamic>)? onTap;

  const ResearchReportCard({
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
            Padding(
              padding: const EdgeInsets.fromLTRB(10, 0, 10, 6),
              child: Text(
                excerpt,
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 12.5,
                  color:
                      Theme.of(context).textTheme.bodySmall?.color?.withOpacity(0.8),
                ),
              ),
            ),
            const Spacer(),
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

/// ----------------------
/// Unified item model for global search
/// ----------------------

enum _Kind { video, podcast, research, book }

class _UnifiedItem {
  final _Kind kind;
  final dynamic video;
  final Map<String, dynamic>? podcast;
  final Map<String, dynamic>? research;
  final Map<String, dynamic>? book;

  _UnifiedItem._(this.kind, {this.video, this.podcast, this.research, this.book});

  factory _UnifiedItem.video(dynamic v) => _UnifiedItem._(_Kind.video, video: v);
  factory _UnifiedItem.podcast(Map<String, dynamic> p) =>
      _UnifiedItem._(_Kind.podcast, podcast: p);
  factory _UnifiedItem.research(Map<String, dynamic> r) =>
      _UnifiedItem._(_Kind.research, research: r);
  factory _UnifiedItem.book(Map<String, dynamic> b) =>
      _UnifiedItem._(_Kind.book, book: b);
}
