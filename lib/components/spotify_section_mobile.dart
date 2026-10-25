import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:xml/xml.dart';
import 'package:cached_network_image/cached_network_image.dart';

class LibsynPodcastSectionMobile extends StatefulWidget {
  final void Function(Map<String, dynamic>)? onPodcastTap;

  const LibsynPodcastSectionMobile({super.key, this.onPodcastTap});

  @override
  _LibsynPodcastSectionMobileState createState() => _LibsynPodcastSectionMobileState();
}

class _LibsynPodcastSectionMobileState extends State<LibsynPodcastSectionMobile> {
  List<Map<String, dynamic>> episodes = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    fetchLibsynEpisodes();
  }

  Future<void> fetchLibsynEpisodes() async {
    final resp = await http.get(Uri.parse('https://feeds.libsyn.com/561905/rss'));
    if (resp.statusCode == 200) {
      final doc = XmlDocument.parse(resp.body);
      final items = doc.findAllElements('item');
      final episodesList = items.map<Map<String, dynamic>>((item) {
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

      setState(() {
        episodes = episodesList;
        isLoading = false;
      });
    } else {
      setState(() => isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    // You can adjust cardWidth as you like for aspect/visibility
    final double cardWidth = 170;
    final double cardHeight = 205;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "Podcasts",
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
              fontSize: 20,
            ),
          ),
          const SizedBox(height: 10),
          isLoading
              ? Center(child: Padding(
              padding: EdgeInsets.symmetric(vertical: 32),
              child: CircularProgressIndicator()))
              : episodes.isEmpty
              ? Center(child: Text('No podcasts found.',
              style: TextStyle(color: Colors.grey)))
              : SizedBox(
            height: cardHeight,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: episodes.length,
              separatorBuilder: (_, __) => const SizedBox(width: 14),
              itemBuilder: (context, i) {
                final ep = episodes[i];
                return GestureDetector(
                  onTap: () => widget.onPodcastTap?.call(ep),
                  child: Container(
                    width: cardWidth,
                    decoration: BoxDecoration(
                      color: theme.cardColor,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.13),
                          blurRadius: 8,
                          spreadRadius: 1,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        ClipRRect(
                          borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                          child: ep['imageUrl']!.isNotEmpty
                              ? CachedNetworkImage(
                            imageUrl: ep['imageUrl']!,
                            width: cardWidth,
                            height: 112,
                            fit: BoxFit.cover,
                            errorWidget: (context, error, stack) => Container(
                              width: cardWidth,
                              height: 112,
                              color: Colors.grey.shade200,
                              alignment: Alignment.center,
                              child: Icon(Icons.podcasts, size: 36, color: Colors.grey),
                            ),
                          )
                              : Container(
                            width: cardWidth,
                            height: 112,
                            color: Colors.grey.shade300,
                            alignment: Alignment.center,
                            child: Icon(Icons.podcasts, size: 36, color: Colors.grey),
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.all(10),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                ep['title'] ?? '',
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14,
                                  color: theme.colorScheme.onSurface,
                                ),
                              ),
                              const SizedBox(height: 3),
                              Text(
                                ep['pubDate'] ?? '',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                    color: Colors.grey.shade600,
                                    fontSize: 11),
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
          ),
        ],
      ),
    );
  }
}
