import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:xml/xml.dart';
import 'package:cached_network_image/cached_network_image.dart';

class LibsynPodcastSectionWidget extends StatefulWidget {
  final void Function(Map<String, dynamic>)? onPodcastTap;


  const LibsynPodcastSectionWidget({super.key, this.onPodcastTap});

  @override
  _LibsynPodcastSectionWidgetState createState() => _LibsynPodcastSectionWidgetState();
}

class _LibsynPodcastSectionWidgetState extends State<LibsynPodcastSectionWidget> {
  List<Map<String, dynamic>> episodes = [];


  @override
  void initState() {
    super.initState();
    fetchLibsynEpisodes();
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

  @override
  Widget build(BuildContext context) {
    final w = MediaQuery.of(context).size.width;
    final h = MediaQuery.of(context).size.height;
    final scale = MediaQuery.of(context).devicePixelRatio * 0.6;
    final theme = Theme.of(context);

    return Container(
      width: w * 0.92,
      padding: EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Container(
          decoration: BoxDecoration(
            color: theme.cardColor,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.5),
                spreadRadius: 2,
                blurRadius: 5,
                offset: Offset(0, 3),
              )
            ],
          ),
          padding: EdgeInsets.all(12),
          child: SizedBox(
            height: h * 0.32,
            child: LayoutBuilder(builder: (c, cons) {
              final ctrl = ScrollController();
              return Scrollbar(
                controller: ctrl,
                thumbVisibility: true,
                trackVisibility: true,
                thickness: 6,
                radius: Radius.circular(8),
                scrollbarOrientation: ScrollbarOrientation.bottom,
                child: ListView.separated(
                  controller: ctrl,
                  scrollDirection: Axis.horizontal,
                  padding: EdgeInsets.only(bottom: 20),
                  itemCount: episodes.length,
                  separatorBuilder: (_, __) => SizedBox(width: 12),
                  itemBuilder: (_, i) {
                    final ep = episodes[i];
                    return GestureDetector(
                      onTap: () {
                        widget.onPodcastTap?.call(ep);
                      },

                      child: Container(
                        width: w * 0.2,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(8),
                          color: theme.cardColor,
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.5),
                              spreadRadius: 2,
                              blurRadius: 5,
                              offset: Offset(0, 3),
                            )
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            if (ep['imageUrl']!.isNotEmpty)
                              ClipRRect(
                                borderRadius: BorderRadius.vertical(top: Radius.circular(8)),
                                child: CachedNetworkImage(
                                  imageUrl: ep['imageUrl']!,
                                  width: double.infinity,
                                  height: cons.maxHeight * 0.7,
                                  fit: BoxFit.contain,
                                ),
                              ),
                            Padding(
                              padding: EdgeInsets.all(8),
                              child: Text(
                                ep['title'] ?? '',
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontSize: scale == 0.6 ? 14 : 14 * scale,
                                  fontWeight: FontWeight.w600,
                                  color: theme.hintColor,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              );
            }),
          ),
        )
      ]),
    );
  }
}
