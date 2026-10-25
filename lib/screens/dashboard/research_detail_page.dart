import 'package:flutter/material.dart';

class ResearchDetailPage extends StatelessWidget {
  /// Expects a post map built from WP /wp-json/wp/v2/posts?_embed=1
  /// Keys we use: title, excerpt, contentHtml, imageUrl, link, date
  final Map<String, dynamic> post;
  final VoidCallback? onCloseTab;

  const ResearchDetailPage({
    super.key,
    required this.post,
    this.onCloseTab,
  });

  String _str(dynamic v, {String or = ''}) => (v == null) ? or : v.toString().trim();

  DateTime? _tryParseDate(String? raw) {
    if (raw == null || raw.trim().isEmpty) return null;
    try {
      return DateTime.tryParse(raw);
    } catch (_) {
      return null;
    }
  }

  String _monthShort(int m) =>
      const ['Jan','Feb','Mar','Apr','May','Jun','Jul','Aug','Sep','Oct','Nov','Dec'][m-1];

  String _formatDate(String? raw) {
    final dt = _tryParseDate(raw);
    if (dt == null) return 'N/A';
    return '${dt.day.toString().padLeft(2, '0')} ${_monthShort(dt.month)} ${dt.year}';
  }

  /// strip HTML quickly to plain text for excerpt if needed
  String _stripHtml(String html) {
    return html.replaceAll(RegExp(r'<[^>]*>|&[^;]+;'), ' ')
               .replaceAll(RegExp(r'\s+'), ' ')
               .trim();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final textTheme = theme.textTheme;

    final title = _str(post['title'], or: 'Untitled');
    final excerpt = _str(post['excerpt']);
    final imageUrl = _str(post['imageUrl']);
    final contentHtml = _str(post['contentHtml']);
    final date = _str(post['date']); // ISO date string
    final link = _str(post['link']);

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
                    if (onCloseTab != null) {
                      onCloseTab!();
                    } else {
                      Navigator.of(context).maybePop();
                    }
                  },
                ),
                const SizedBox(width: 8),
                Text(
                  'Research Detail',
                  style: TextStyle(
                    color: theme.hintColor,
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const Spacer(),
                if (date.isNotEmpty)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: theme.cardColor,
                      borderRadius: BorderRadius.circular(999),
                      border: Border.all(color: theme.dividerColor.withOpacity(0.6)),
                    ),
                    child: Text(
                      _formatDate(date),
                      style: textTheme.labelMedium,
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
                    // Header block
                    Text(title,
                        style: textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                        )),
                    const SizedBox(height: 8),
                    if (excerpt.isNotEmpty)
                      Text(
                        _stripHtml(excerpt),
                        style: textTheme.titleMedium?.copyWith(
                          color: theme.hintColor,
                        ),
                      ),
                    const SizedBox(height: 18),

                    // Cover/featured image
                    if (imageUrl.isNotEmpty)
                      ClipRRect(
                        borderRadius: BorderRadius.circular(16),
                        child: Image.network(
                          imageUrl,
                          width: double.infinity,
                          height: MediaQuery.of(context).size.height * 0.4,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => Container(
                            height: MediaQuery.of(context).size.height * 0.4,
                            color: Colors.grey.shade300,
                            alignment: Alignment.center,
                            child: Icon(Icons.broken_image,
                                size: 40, color: Colors.grey.shade600),
                          ),
                        ),
                      ),
                    const SizedBox(height: 24),

                    // Content — keep it simple as plain text for now
                    // (If you want rich HTML rendering later, plug in flutter_html)
                    if (contentHtml.isNotEmpty) ...[
                      Text(
                        _stripHtml(contentHtml),
                        style: textTheme.bodyLarge?.copyWith(height: 1.6),
                      ),
                      const SizedBox(height: 24),
                    ],

                    // Read original
                    // if (link.isNotEmpty)
                    //   Align(
                    //     alignment: Alignment.centerLeft,
                    //     child: TextButton.icon(
                    //       onPressed: () async {
                    //         final uri = Uri.parse(link);
                    //         if (await canLaunchUrl(uri)) {
                    //           await launchUrl(uri, mode: LaunchMode.externalApplication);
                    //         }
                    //       },
                    //       icon: const Icon(Icons.open_in_new, size: 16),
                    //       label: const Text('Read on Website'),
                    //     ),
                    //   ),
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
