import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:url_launcher/url_launcher.dart';

class BookDetailPage extends StatefulWidget {
  /// Accepts either:
  /// 1) A Google-Books-like map { volumeInfo: {...}, ... }, or
  /// 2) An RTDB-like map mirroring your "books" node fields,
  /// 3) Or a wrapper { raw: {...rtdb...}, title:..., imageUrl:... } from ContentScreen.
  final Map<String, dynamic> book;
  final bool hasStartedReading;
  final VoidCallback? onCloseTab;

  const BookDetailPage({
    super.key,
    required this.book,
    this.hasStartedReading = false,
    this.onCloseTab,
  });

  @override
  State<BookDetailPage> createState() => _BookDetailPageState();
}

class _BookDetailPageState extends State<BookDetailPage> {
  // Hardcoded rating (non-interactive)
  static const double kStaticRating = 4.5;

  // ---------------------------
  // Normalization
  // ---------------------------

  /// Convert any Map<dynamic,dynamic> to Map<String,dynamic> recursively.
  Map<String, dynamic> _stringifyKeys(dynamic v) {
    if (v is Map) {
      return Map<String, dynamic>.fromEntries(
        v.entries.map((e) => MapEntry(e.key.toString(), _stringifyValue(e.value))),
      );
    }
    return {};
  }

  dynamic _stringifyValue(dynamic v) {
    if (v is Map) return _stringifyKeys(v);
    if (v is List) return v.map(_stringifyValue).toList();
    return v;
  }

  /// Unwrap `{ raw: {...} }` if present, and stringify all keys.
  Map<String, dynamic> get _b {
    final src = (widget.book['raw'] is Map)
        ? widget.book['raw']
        : widget.book;
    return _stringifyKeys(src);
  }

  // ---------------------------
  // Utilities / Field Resolvers
  // ---------------------------

  String _str(dynamic v, {String or = ''}) =>
      (v == null) ? or : v.toString().trim();

  List<String> _splitTags(String raw) {
    return raw
        .split(',')
        .map((e) => e.trim())
        .where((e) => e.isNotEmpty)
        .toList(growable: false);
  }

  String? _firstNonEmptyUrl(List<dynamic> candidates) {
    for (final c in candidates) {
      if (c is String && c.trim().isNotEmpty) {
        final t = c.trim();
        final uri = Uri.tryParse(t);
        if (uri != null && uri.hasScheme && uri.hasAuthority) {
          // force https to avoid mixed-content issues
          final https = uri.scheme == 'http'
              ? uri.replace(scheme: 'https')
              : uri;
          return https.toString();
        }
      }
    }
    return null;
  }

  // Resolve a cover image URL from many possible keys
  String _resolveCover(Map<String, dynamic> b) {
    final v = (b['volumeInfo'] as Map?) ?? const {};
    final imageLinks = (v is Map) ? (v['imageLinks'] as Map?) : null;

    final direct = _firstNonEmptyUrl([
      b['coverUrl'],
      b['imageUrl'],
      b['image'],
      b['cover'],
      b['coverImage'],
      b['thumbnail'],
      imageLinks != null ? imageLinks['thumbnail'] : null,
    ]);

    if (direct == null || direct.isEmpty) {
      return 'https://via.placeholder.com/150x220.png?text=No+Cover';
    }
    return direct;
  }

  // Resolve fields with preference order: RTDB → volumeInfo → fallback
  String _resolveTitle(Map<String, dynamic> b) {
    final v = (b['volumeInfo'] as Map?) ?? const {};
    final rt = _str(b['bookName']);
    if (rt.isNotEmpty) return rt;
    final vt = _str(v['title']);
    return vt.isNotEmpty ? vt : 'Untitled';
  }

  String _resolveAuthors(Map<String, dynamic> b) {
    final v = (b['volumeInfo'] as Map?) ?? const {};
    final ra = _str(b['authorName']);
    if (ra.isNotEmpty) return ra;
    final authors = v['authors'];
    if (authors is List && authors.isNotEmpty) {
      return authors.join(', ');
    }
    return 'Unknown';
  }

  String _resolveBookDesc(Map<String, dynamic> b) {
    final v = (b['volumeInfo'] as Map?) ?? const {};
    final rd = _str(b['bookDescription']);
    if (rd.isNotEmpty) return rd;
    return _str(v['description'], or: 'No description available.');
  }

  String _resolveAuthorDesc(Map<String, dynamic> b) {
    return _str(b['authorDescription'], or: 'No author bio available.');
  }

  String _resolveTagsRaw(Map<String, dynamic> b) {
    final v = (b['volumeInfo'] as Map?) ?? const {};
    final rtdbTags = _str(b['tags']);
    if (rtdbTags.isNotEmpty) return rtdbTags;
    final cats = v['categories'];
    if (cats is List && cats.isNotEmpty) {
      return cats.join(', ');
    }
    return 'General';
  }

  String _resolveStatus(Map<String, dynamic> b) => _str(b['status'], or: 'N/A');

  // PDF / Amazon links: check RTDB first; then Google Books-like fallbacks.
  String? _resolvePdfUrl(Map<String, dynamic> b) {
    final v = (b['volumeInfo'] as Map?) ?? const {};
    final accessInfo = (b['accessInfo'] as Map?) ?? const {};
    final pdfMap = (accessInfo['pdf'] as Map?) ?? const {};

    return _firstNonEmptyUrl([
      // RTDB
      b['pdfUrl'],
      v['pdfUrl'],
      // Google Books
      pdfMap['downloadLink'],
      pdfMap['acsTokenLink'],
      accessInfo['webReaderLink'],
      v['previewLink'],
      b['previewLink'],
    ]);
  }

  String? _resolveAmazonUrl(Map<String, dynamic> b) {
    final v = (b['volumeInfo'] as Map?) ?? const {};
    final saleInfo = (b['saleInfo'] as Map?) ?? const {};
    return _firstNonEmptyUrl([
      // RTDB primary
      b['amazonLink'],
      v['amazonLink'],
      // alternates
      b['amazonUrl'],
      v['amazonUrl'],
      b['buyUrl'],
      v['buyUrl'],
      // Google Books fallbacks
      saleInfo['buyLink'],
      v['infoLink'],
      v['canonicalVolumeLink'],
    ]);
  }

  // ---------------------------
  // Open external links (Web-safe)
  // ---------------------------

  Future<void> _openExternal(String url) async {
    final uri = Uri.parse(url);
    final can = await canLaunchUrl(uri);
    if (!can) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not launch: $url')),
      );
      return;
    }

    // On web, let the browser open in a new tab. On mobile/desktop, external app.
    final ok = await launchUrl(
      uri,
      mode: kIsWeb ? LaunchMode.platformDefault : LaunchMode.externalApplication,
      webOnlyWindowName: '_blank',
    );

    if (!ok && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to open: $url')),
      );
    }
  }

  void _handleStartReading() {
    final pdfUrl = _resolvePdfUrl(_b);
    if (pdfUrl != null) {
      _openExternal(pdfUrl);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No PDF available for this book.')),
      );
    }
  }

  void _handleOrderPhysical() {
    final buyUrl = _resolveAmazonUrl(_b);
    if (buyUrl != null) {
      _openExternal(buyUrl);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Purchase link not available.')),
      );
    }
  }

  // --------------------------------------------
  // Fetch "other editions" (same bookName) RTDB
  // --------------------------------------------
  Future<List<Map<String, dynamic>>> _fetchOtherEditionsFromRTDB(String title) async {
    final q = FirebaseDatabase.instance
        .ref('books')
        .orderByChild('bookName')
        .equalTo(title);

    final snap = await q.get();
    if (!snap.exists || snap.value == null) return [];

    final raw = Map<dynamic, dynamic>.from(snap.value as Map);
    final editions = <Map<String, dynamic>>[];

    for (final entry in raw.entries) {
      final data = Map<String, dynamic>.from(entry.value as Map);

      if (_str(data['status']) != 'published') continue;

      final bookName = _str(data['bookName']);
      final authorName = _str(data['authorName'], or: 'Unknown');
      final coverUrl = _str(data['coverUrl']);
      final description = _str(data['bookDescription']);
      final tags = _str(data['tags']);
      final publishedAt = _str(data['publishedAt']);

      final pdfUrl = _str(data['pdfUrl']);
      final amazonLink = _str(data['amazonLink']);
      final buyUrl = _str(data['buyUrl']);
      final authorDesc = _str(data['authorDescription']);

      final gbLike = {
        'volumeInfo': {
          'title': bookName,
          'authors': [authorName],
          'description': description,
          'publishedDate': publishedAt,
          'categories': tags.isNotEmpty ? [tags] : [],
          'imageLinks': {'thumbnail': coverUrl},
          'industryIdentifiers': [
            {'identifier': 'N/A'}
          ],
          'language': 'en',
          'pageCount': 0,
          'pdfUrl': pdfUrl,
          'amazonLink': amazonLink.isNotEmpty ? amazonLink : buyUrl,
          'buyUrl': buyUrl,
          'authorDescription': authorDesc,
        },
        'pdfUrl': pdfUrl,
        'amazonLink': amazonLink.isNotEmpty ? amazonLink : buyUrl,
        'buyUrl': buyUrl,
        'authorDescription': authorDesc,
        'bookName': bookName,
        'authorName': authorName,
        'tags': tags,
        'status': data['status'],
        'publishedAt': publishedAt,
        'coverUrl': coverUrl,
        'bookDescription': description,
      };

      editions.add(_stringifyKeys(gbLike));
    }

    // Filter out the current edition
    final currentTitle = _resolveTitle(_b);
    final currentAuthors = _resolveAuthors(_b);
    editions.removeWhere((e) {
      final v = e['volumeInfo'] ?? {};
      final t = _str(v['title']);
      final a = (v['authors'] is List && (v['authors'] as List).isNotEmpty)
          ? (v['authors'] as List).join(', ')
          : '';
      return t == currentTitle && a == currentAuthors;
    });

    return editions;
  }

  // ---------------------------
  // Build
  // ---------------------------

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final textTheme = theme.textTheme;

    // Resolve everything from the normalized map
    final title = _resolveTitle(_b);
    final authors = _resolveAuthors(_b);
    final bookDesc = _resolveBookDesc(_b);
    final authorDesc = _resolveAuthorDesc(_b);
    final tagsRaw = _resolveTagsRaw(_b);
    final status = _resolveStatus(_b);
    final coverUrl = _resolveCover(_b);

    final tags = _splitTags(tagsRaw);

    return Container(
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
      child: Scaffold(
        appBar: PreferredSize(
          preferredSize: const Size.fromHeight(50),
          child: Container(
            color: theme.cardColor,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            alignment: Alignment.centerLeft,
            child: Row(
              children: [
                IconButton(
                  icon: Icon(Icons.arrow_back, color: theme.hintColor),
                  onPressed: () {
                    if (widget.onCloseTab != null) {
                      widget.onCloseTab!();
                    } else {
                      Navigator.of(context).maybePop();
                    }
                  },
                ),
                const SizedBox(width: 8),
                Text(
                  'Book Detail',
                  style: TextStyle(
                    color: theme.hintColor,
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const Spacer(),
                // Status badge
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: status.toLowerCase() == 'published'
                        ? Colors.green.withOpacity(0.12)
                        : Colors.orange.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(999),
                    border: Border.all(
                      color: status.toLowerCase() == 'published'
                          ? Colors.green
                          : Colors.orange,
                      width: 0.8,
                    ),
                  ),
                  child: Text(
                    status.toUpperCase(),
                    style: TextStyle(
                      color: status.toLowerCase() == 'published'
                          ? Colors.green.shade700
                          : Colors.orange.shade700,
                      fontWeight: FontWeight.w600,
                      fontSize: 12,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
              ],
            ),
          ),
        ),
        body: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Center(
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  maxWidth: MediaQuery.of(context).size.width * 0.85,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // ----------------- Header Row -----------------
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Cover + Actions
                        Column(
                          children: [
                            ClipRRect(
                              borderRadius: BorderRadius.circular(16),
                              child: Image.network(
                                coverUrl,
                                width: MediaQuery.of(context).size.width * 0.28,
                                height: MediaQuery.of(context).size.height * 0.55,
                                fit: BoxFit.contain,
                                errorBuilder: (_, __, ___) => Container(
                                  width: MediaQuery.of(context).size.width * 0.28,
                                  height: MediaQuery.of(context).size.height * 0.55,
                                  color: Colors.grey.shade300,
                                  alignment: Alignment.center,
                                  child: Icon(Icons.broken_image,
                                      size: 40, color: Colors.grey.shade600),
                                ),
                                loadingBuilder: (context, child, progress) {
                                  if (progress == null) return child;
                                  return const Center(child: CircularProgressIndicator());
                                },
                              ),
                            ),
                            const SizedBox(height: 20),

                            // Start / Continue reading (opens PDF)
                            ElevatedButton(
                              onPressed: _handleStartReading,
                              style: ElevatedButton.styleFrom(
                                elevation: 8,
                                shape: const StadiumBorder(),
                                backgroundColor: theme.cardColor,
                                shadowColor: Colors.black.withOpacity(0.5),
                                fixedSize: Size(
                                  MediaQuery.of(context).size.width * 0.24,
                                  MediaQuery.of(context).size.height * 0.05,
                                ),
                                side: BorderSide(color: theme.scaffoldBackgroundColor),
                              ),
                              child: Text(
                                widget.hasStartedReading ? "Continue Reading" : "Start Reading",
                                style: TextStyle(color: theme.hintColor),
                              ),
                            ),

                            const SizedBox(height: 12),

                            // Order physical copy (opens Amazon / buy link)
                            OutlinedButton(
                              onPressed: _handleOrderPhysical,
                              style: OutlinedButton.styleFrom(
                                elevation: 8,
                                backgroundColor: theme.cardColor,
                                shadowColor: Colors.black.withOpacity(0.5),
                                fixedSize: Size(
                                  MediaQuery.of(context).size.width * 0.24,
                                  MediaQuery.of(context).size.height * 0.05,
                                ),
                                shape: const StadiumBorder(),
                                side: BorderSide(color: theme.scaffoldBackgroundColor),
                              ),
                              child: Text(
                                "Order a Physical Copy",
                                style: TextStyle(color: theme.hintColor),
                              ),
                            ),

                            const SizedBox(height: 20),

                            // Hardcoded 4.5-star rating (non-interactive)
                            _StaticRating(rating: kStaticRating),
                          ],
                        ),

                        const SizedBox(width: 32),

                        // Right-side details
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(title,
                                  style: textTheme.headlineSmall?.copyWith(
                                    fontWeight: FontWeight.bold,
                                  )),
                              const SizedBox(height: 8),
                              Text(authors,
                                  style: textTheme.titleMedium?.copyWith(fontSize: 18)),
                              const SizedBox(height: 16),

                              // Tags
                              Text("Categories / Tags:",
                                  style: textTheme.titleMedium
                                      ?.copyWith(fontWeight: FontWeight.bold)),
                              const SizedBox(height: 8),
                              Wrap(
                                spacing: 8,
                                runSpacing: 8,
                                children: (tags.isNotEmpty ? tags : ['General'])
                                    .map((t) => Chip(label: Text(t)))
                                    .toList(),
                              ),
                              const SizedBox(height: 18),

                              // Book Description
                              Text("About this Book",
                                  style: textTheme.titleMedium
                                      ?.copyWith(fontWeight: FontWeight.bold)),
                              const SizedBox(height: 8),
                              Text(
                                bookDesc,
                                style: textTheme.bodyMedium?.copyWith(fontSize: 16, height: 1.6),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 32),

                    // ---------------- About the Author ----------------
                    Container(
                      decoration: BoxDecoration(
                        color: theme.cardColor,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.1),
                            blurRadius: 4,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('About the Author',
                              style: textTheme.titleLarge
                                  ?.copyWith(fontWeight: FontWeight.bold)),
                          const SizedBox(height: 16),
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              CircleAvatar(
                                radius: 40,
                                backgroundImage: NetworkImage(
                                  'https://api.dicebear.com/7.x/adventurer-neutral/png?seed=${Uri.encodeComponent(authors)}',
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Text(
                                  authorDesc,
                                  style: textTheme.bodyMedium?.copyWith(height: 1.6),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),

                    // ---------------- More Editions ----------------
                    const SizedBox(height: 32),
                    FutureBuilder<List<Map<String, dynamic>>>(
                      future: _fetchOtherEditionsFromRTDB(title),
                      builder: (context, snapshot) {
                        if (snapshot.connectionState == ConnectionState.waiting) {
                          return const Padding(
                            padding: EdgeInsets.only(top: 16),
                            child: Center(child: CircularProgressIndicator()),
                          );
                        }
                        if (!snapshot.hasData || snapshot.data!.isEmpty) {
                          return const SizedBox();
                        }

                        final editions = snapshot.data!;
                        return Container(
                          decoration: BoxDecoration(
                            color: theme.cardColor,
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.5),
                                blurRadius: 4,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          padding: const EdgeInsets.fromLTRB(20, 24, 20, 16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text("More Edition",
                                  style: theme.textTheme.headlineSmall
                                      ?.copyWith(fontWeight: FontWeight.bold)),
                              const SizedBox(height: 12),
                              SizedBox(
                                height: 260,
                                child: ListView.separated(
                                  scrollDirection: Axis.horizontal,
                                  itemCount: editions.length,
                                  separatorBuilder: (_, __) => const SizedBox(width: 16),
                                  itemBuilder: (context, index) {
                                    final ed = editions[index];
                                    final info =
                                        Map<String, dynamic>.from(ed['volumeInfo'] ?? {});
                                    final cover = _resolveCover(ed);
                                    final editionTitle = _str(info['title'], or: 'Edition');
                                    final year = _str(info['publishedDate']).isNotEmpty
                                        ? _str(info['publishedDate']).split('-').first
                                        : 'Year';
                                    final format = _str(info['printType'], or: 'Format');

                                    return GestureDetector(
                                      onTap: () {
                                        Navigator.pushReplacement(
                                          context,
                                          MaterialPageRoute(
                                            builder: (_) => BookDetailPage(book: ed),
                                          ),
                                        );
                                      },
                                      child: SizedBox(
                                        width: 140,
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            ClipRRect(
                                              borderRadius: BorderRadius.circular(12),
                                              child: Image.network(
                                                cover,
                                                width: 140,
                                                height: 180,
                                                fit: BoxFit.cover,
                                                errorBuilder: (_, __, ___) => Container(
                                                  width: 140,
                                                  height: 180,
                                                  color: Colors.grey.shade300,
                                                  alignment: Alignment.center,
                                                  child: Icon(Icons.broken_image,
                                                      size: 40, color: Colors.grey.shade600),
                                                ),
                                              ),
                                            ),
                                            const SizedBox(height: 8),
                                            Text(format, style: textTheme.titleSmall),
                                            Text(
                                              editionTitle,
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                              style: textTheme.bodySmall,
                                            ),
                                            Text(year, style: textTheme.labelSmall),
                                          ],
                                        ),
                                      ),
                                    );
                                  },
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ----------------- Small UI Helpers -----------------

class _StaticRating extends StatelessWidget {
  final double rating; // e.g., 4.5
  const _StaticRating({required this.rating});

  @override
  Widget build(BuildContext context) {
    final fullStars = rating.floor(); // 4
    final hasHalf = (rating - fullStars) >= 0.5; // true for 4.5
    final totalStars = 5;

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        ...List.generate(fullStars, (_) => const Icon(Icons.star, color: Colors.amber, size: 28)),
        if (hasHalf) const Icon(Icons.star_half, color: Colors.amber, size: 28),
        ...List.generate(
          totalStars - fullStars - (hasHalf ? 1 : 0),
          (_) => const Icon(Icons.star_border, color: Colors.amber, size: 28),
        ),
        const SizedBox(width: 8),
        Text(
          rating.toStringAsFixed(1),
          style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
        ),
      ],
    );
  }
}
