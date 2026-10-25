import 'dart:async';
import 'dart:convert';

import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'package:xml/xml.dart';
import 'package:firebase_database/firebase_database.dart';

import 'package:Marketing_Fruit/screens/dashboard/main_layout.dart';

class ExploreContentSection extends StatefulWidget {
  final double width;
  const ExploreContentSection({super.key, required this.width});

  @override
  State<ExploreContentSection> createState() => _ExploreContentSectionState();
}

class _ExploreContentSectionState extends State<ExploreContentSection> {
  final ScrollController _scrollController = ScrollController();

  List<_ExploreItem> _items = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadContent();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _loadContent() async {
    setState(() => _loading = true);
    try {
      final results = await Future.wait([
        _fetchVideos(),
        _fetchLibsynEpisodes(),
        _fetchBooksOnce(),
        _fetchResearchReports(),
      ]);

      final videos = (results[0]).cast<dynamic>();
      final podcasts = (results[1] as List<Map<String, dynamic>>).cast<Map<String,dynamic>>();
      final books = (results[2] as List<Map<String, dynamic>>).cast<Map<String,dynamic>>();
      final reports = (results[3] as List<Map<String, dynamic>>).cast<Map<String,dynamic>>();

      const takeN = 3;
      final v = videos.take(takeN).map<_ExploreItem>((e) => _ExploreItem.video(e)).toList();
      final p = podcasts.take(takeN).map<_ExploreItem>((e) => _ExploreItem.podcast(e)).toList();
      final b = books.take(takeN).map<_ExploreItem>((e) => _ExploreItem.book(e)).toList();
      final r = reports.take(takeN).map<_ExploreItem>((e) => _ExploreItem.research(e)).toList();

      final out = <_ExploreItem>[];
      final maxLen = [v.length, p.length, b.length, r.length].reduce((a, c) => a > c ? a : c);
      for (var i = 0; i < maxLen; i++) {
        if (i < v.length) out.add(v[i]);
        if (i < p.length) out.add(p[i]);
        if (i < b.length) out.add(b[i]);
        if (i < r.length) out.add(r[i]);
      }

      if (!mounted) return;
      setState(() {
        _items = out;
        _loading = false;
      });
    } catch (e, stack) {
      debugPrint('Error loading content: $e\n$stack');
      if (!mounted) return;
      setState(() {
        _items = [];
        _loading = false;
      });
    }
  }

  // Fetch YouTube videos - make sure YOUTUBE_API_KEY is defined correctly in environment
  Future<List<dynamic>> _fetchVideos() async {
    const channelId = 'UCXD2w9cm2BKLxkCzCk_rTLg';
    final apiKey = const String.fromEnvironment('YOUTUBE_API_KEY', defaultValue: '');
    if (apiKey.isEmpty) {
      debugPrint('YouTube API key is missing');
      return [];
    }
    final url =
        'https://www.googleapis.com/youtube/v3/search?part=snippet&channelId=$channelId&order=date&maxResults=40&type=video&key=$apiKey';

    try {
      final response = await http.get(Uri.parse(url));
      if (response.statusCode == 200) {
        final items = json.decode(response.body)['items'] as List<dynamic>;
        final filtered = items.where((item) => item['id']?['videoId'] != null).toList();
        debugPrint('Fetched ${filtered.length} videos');
        return filtered;
      } else {
        debugPrint('Failed to fetch videos: ${response.statusCode}');
        return [];
      }
    } catch (e, stack) {
      debugPrint('Error fetching videos: $e\n$stack');
      return [];
    }
  }

  Future<List<Map<String, dynamic>>> _fetchLibsynEpisodes() async {
    const feedUrl = 'https://feeds.libsyn.com/561905/rss';
    try {
      final resp = await http.get(Uri.parse(feedUrl));
      if (resp.statusCode != 200) {
        debugPrint('Failed to fetch podcasts feed: ${resp.statusCode}');
        return [];
      }
      final doc = XmlDocument.parse(resp.body);
      final items = doc.findAllElements('item');
      final episodes = items.map((item) {
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
      debugPrint('Fetched ${episodes.length} podcasts');
      return episodes;
    } catch (e, stack) {
      debugPrint('Error fetching podcasts: $e\n$stack');
      return [];
    }
  }

  Future<String?> getOrUploadResearchImageUrl({
    required String imageUrl,
    required String researchId,
  }) async {
    final storageRef = FirebaseStorage.instance.ref().child('research_images/$researchId.jpg');
    try {
      return await storageRef.getDownloadURL();
    } on FirebaseException catch (e) {
      if (e.code == 'object-not-found') {
        try {
          final proxyUrl = 'https://api.allorigins.win/raw?url=${Uri.encodeComponent(imageUrl)}';
          final resp = await http.get(Uri.parse(proxyUrl));
          if (resp.statusCode != 200) return null;
          final imgBytes = resp.bodyBytes;
          final uploadTask = await storageRef.putData(
            imgBytes,
            SettableMetadata(contentType: 'image/jpeg'),
          );
          return await uploadTask.ref.getDownloadURL();
        } catch (e, stack) {
          debugPrint('Error uploading image to Firebase: $e\n$stack');
          return null;
        }
      } else {
        debugPrint('Firebase exception: $e');
        return null;
      }
    }
  }

  Future<List<Map<String, dynamic>>> _fetchResearchReports() async {
    final uri = Uri.parse(
      'https://marketingfruit.net/wp-json/wp/v2/posts?per_page=40&_embed=1',
    );
    try {
      final resp = await http.get(uri);
      if (resp.statusCode != 200) {
        debugPrint('Failed to fetch research: ${resp.statusCode}');
        return [];
      }
      final List data = jsonDecode(resp.body);

      return await Future.wait(data.map<Future<Map<String, dynamic>>>((raw) async {
        final id = raw['id']?.toString() ?? '';
        final title = _stripHtml((raw['title']?['rendered'] ?? '').toString());
        final excerpt = (raw['excerpt']?['rendered'] ?? '').toString();
        final contentHtml = (raw['content']?['rendered'] ?? '').toString();
        final date = (raw['date'] ?? '').toString();
        final link = (raw['link'] ?? '').toString();

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

        String? firebaseImageUrl;
        if (imageUrl.isNotEmpty && id.isNotEmpty) {
          firebaseImageUrl = await getOrUploadResearchImageUrl(imageUrl: imageUrl, researchId: id);
        }

        return {
          'id': id,
          'title': title,
          'excerpt': excerpt,
          'contentHtml': contentHtml,
          'date': date,
          'link': link,
          'imageUrl': firebaseImageUrl ?? imageUrl,
        };
      }).toList());
    } catch (e, stack) {
      debugPrint('Error fetching research reports: $e\n$stack');
      return [];
    }
  }

  Future<List<Map<String, dynamic>>> _fetchBooksOnce() async {
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
      debugPrint('Fetched ${list.length} books');
      return list;
    } catch (e, stack) {
      debugPrint('Error fetching books: $e\n$stack');
      return [];
    }
  }

  Map<String, dynamic> _extractBookFields(Map<String, dynamic> raw, {String? key}) {
    final title = (raw['title'] ?? raw['bookName'] ?? raw['name'] ?? '').toString();
    final author = (raw['author'] ?? raw['authorName'] ?? '').toString();
    final imageUrl = (raw['image'] ??
            raw['cover'] ??
            raw['coverUrl'] ??
            raw['thumbnail'] ??
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

  String _stripHtml(String html) {
    return html
        .replaceAll(RegExp(r'<[^>]*>|&[^;]+;'), ' ')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    final dpi = MediaQueryData.fromView(WidgetsBinding.instance.window).devicePixelRatio;
    double scale = 1.0;
    if (dpi > 1.0 && dpi < 2.0) {
      scale = 1.4;
    } else if (dpi >= 2.0) {
      scale = 0.9;
    } else {
      scale = 1.0;
    }

    final containerH = MediaQuery.of(context).size.height * 0.5 * scale;
    final innerH = MediaQuery.of(context).size.height * 0.485 * scale;

    return Container(
      width: widget.width,
      height: containerH,
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.5),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Center(
        child: Container(
          width: widget.width * 0.97,
          height: innerH,
          padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 16),
          decoration: BoxDecoration(
            color: theme.cardColor,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Top bar with title and Explore button
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 14.0, vertical: 12.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.start,
                  children: [
                    Text(
                      'Explore Our Content',
                      style: GoogleFonts.poppins(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: theme.hintColor,
                      ),
                    ),
                    const Spacer(),
                    ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        fixedSize: const Size(250, 60),
                        backgroundColor: theme.cardColor,
                        side: BorderSide(color: Colors.purple.shade700, width: 2.0),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const MainLayout(
                              userRole: 'Student',
                              nftindex: 7,
                            ),
                          ),
                        );
                      },
                      icon: const Icon(Icons.search, color: Colors.purple),
                      label: Text(
                        'Explore',
                        style: GoogleFonts.workSans(
                          color: theme.hintColor,
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 8),
              Expanded(
                child: _loading
                    ? const Center(child: CircularProgressIndicator())
                    : (_items.isEmpty
                        ? const Center(child: Text('No content to show right now.'))
                        : Scrollbar(
                            controller: _scrollController,
                            thumbVisibility: true,
                            child: SingleChildScrollView(
                              controller: _scrollController,
                              scrollDirection: Axis.horizontal,
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              child: Row(
                                children: _items.map((it) {
                                  return Padding(
                                    padding: const EdgeInsets.symmetric(horizontal: 16.0),
                                    child: _buildCardForItem(it, scale),
                                  );
                                }).toList(),
                              ),
                            ),
                          )),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCardForItem(_ExploreItem it, double scale) {
    switch (it.kind) {
      case _Kind.video:
        // return _BaseMiniCard(
        //   height: MediaQuery.of(context).size.height * 0.2 * scale,
        //   image: (it.video?['snippet']?['thumbnails']?['high']?['url'] ?? '').toString(),
        //   chipText: 'VIDEO',
        //   title: (it.video?['snippet']?['title'] ?? '').toString(),
        //   fallbackIcon: Icons.ondemand_video,
        //   onTap: () {
        //     final videoId = it.video?['id']?['videoId']?.toString();
        //     if (videoId == null || videoId.isEmpty) return;
        //     Navigator.push(
        //       context,
        //       MaterialPageRoute(
        //         builder: (_) => MainLayout(
        //           userRole: 'Student',
        //           nftindex: 7,
        //           initialLaunch: ContentLaunch.video(videoId),
        //         ),
        //       ),
        //     );
        //   },
        // );
      case _Kind.podcast:
        return _BaseMiniCard(
          height: MediaQuery.of(context).size.height * 0.3 * scale,
          image: (it.podcast?['imageUrl'] ?? '').toString(),
          chipText: 'PODCAST',
          title: (it.podcast?['title'] ?? '').toString(),
          fallbackIcon: Icons.podcasts,
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => MainLayout(
                  userRole: 'Student',
                  nftindex: 7,
                  initialLaunch: ContentLaunch.podcast(it.podcast!),
                ),
              ),
            );
          },
        );
      case _Kind.book:
        final label = (it.book?['author'] ?? '').toString().isNotEmpty
            ? 'BOOK · ${it.book?['author']}'
            : 'BOOK';
        return _BaseMiniCard(
          height: MediaQuery.of(context).size.height * 0.3 * scale,
          image: (it.book?['imageUrl'] ?? '').toString(),
          chipText: label,
          title: (it.book?['title'] ?? '').toString(),
          fallbackIcon: Icons.menu_book,
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => MainLayout(
                  userRole: 'Student',
                  nftindex: 7,
                  initialLaunch: ContentLaunch.book(it.book!),
                ),
              ),
            );
          },
        );
      case _Kind.research:
        return _BaseMiniCard(
          height: MediaQuery.of(context).size.height * 0.3 * scale,
          image: (it.research?['imageUrl'] ?? '').toString(),
          chipText: 'RESEARCH',
          title: (it.research?['title'] ?? '').toString(),
          fallbackIcon: Icons.article,
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => MainLayout(
                  userRole: 'Student',
                  nftindex: 7,
                  initialLaunch: ContentLaunch.research(it.research!),
                ),
              ),
            );
          },
        );
    }
  }
}

class _BaseMiniCard extends StatelessWidget {
  final double height;
  final String image;
  final String chipText;
  final String title;
  final IconData fallbackIcon;
  final VoidCallback onTap;

  const _BaseMiniCard({
    required this.height,
    required this.image,
    required this.chipText,
    required this.title,
    required this.fallbackIcon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      width: 260,
      height: height,
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(20),
        boxShadow: const [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 12,
            offset: Offset(0, 6),
          ),
        ],
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: onTap,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
              child: image.isNotEmpty
                  ? Image.network(
                      image,
                      height: 210,
                      width: double.infinity,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => _fallbackBanner(),
                    )
                  : _fallbackBanner(),
            ),
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12.0),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.purple.shade100,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  chipText,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: Colors.purple,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 10),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12.0),
              child: Text(
                title.isEmpty ? 'Untitled' : title,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Colors.black87,
                ),
              ),
            ),
            const Spacer(),
          ],
        ),
      ),
    );
  }

  Widget _fallbackBanner() {
    return Container(
      height: 120,
      width: double.infinity,
      color: Colors.grey.shade200,
      alignment: Alignment.center,
      child: Icon(fallbackIcon, size: 40, color: Colors.grey.shade600),
    );
  }
}

enum _Kind { video, podcast, research, book }

class _ExploreItem {
  final _Kind kind;
  final dynamic video;
  final Map<String, dynamic>? podcast;
  final Map<String, dynamic>? research;
  final Map<String, dynamic>? book;

  _ExploreItem._(this.kind, {this.video, this.podcast, this.research, this.book});

  factory _ExploreItem.video(dynamic v) => _ExploreItem._(_Kind.video, video: v);
  factory _ExploreItem.podcast(Map<String, dynamic> p) =>
      _ExploreItem._(_Kind.podcast, podcast: p);
  factory _ExploreItem.research(Map<String, dynamic> r) =>
      _ExploreItem._(_Kind.research, research: r);
  factory _ExploreItem.book(Map<String, dynamic> b) => _ExploreItem._(_Kind.book, book: b);
}

