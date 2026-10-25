import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'package:cached_network_image/cached_network_image.dart';

class YouTubeSectionMobile extends StatefulWidget {
  final String? heading;
  final void Function(String videoId)? onVideoTap;

  const YouTubeSectionMobile({
    super.key,
    this.heading,
    this.onVideoTap,
  });

  @override
  State<YouTubeSectionMobile> createState() => _YouTubeSectionMobileState();
}

class _YouTubeSectionMobileState extends State<YouTubeSectionMobile> {
  List<dynamic> videos = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    fetchVideos();
  }

  Future<void> fetchVideos() async {
    // Place your actual API key in .env or through --dart-define
    const apiKey = String.fromEnvironment('YOUTUBE_API_KEY');
    const channelId = 'UCXD2w9cm2BKLxkCzCk_rTLg';
    final url =
        'https://www.googleapis.com/youtube/v3/search?part=snippet&channelId=$channelId&order=date&maxResults=10&type=video&key=$apiKey';

    final response = await http.get(Uri.parse(url));
    print(response.body);
    if (response.statusCode == 200) {
      final decoded = json.decode(response.body);
      final items = decoded['items'];
      final validVideos = items.where((item) => item['id']?['videoId'] != null).toList();
      setState(() {
        videos = validVideos;
        isLoading = false;
      });
    } else {
      setState(() => isLoading = false);
    }
  }

  String _stripHtmlTags(String htmlText) {
    final regex = RegExp(r'<[^>]*>', multiLine: true, caseSensitive: false);
    return htmlText.replaceAll(regex, '').replaceAll('&quot;', '?').replaceAll('&amp;', '&').trim();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cardWidth = 190.0;
    final cardHeight = 185.0;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (widget.heading != null && widget.heading!.isNotEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 5.0, horizontal: 2),
              child: Text(
                widget.heading!,
                style: GoogleFonts.poppins(
                  fontWeight: FontWeight.bold,
                  fontSize: 20,
                ),
              ),
            ),
          isLoading
              ? const Padding(
              padding: EdgeInsets.symmetric(vertical: 40),
              child: Center(child: CircularProgressIndicator()))
              : videos.isEmpty
              ? Padding(
            padding: const EdgeInsets.symmetric(vertical: 16),
            child: Center(
                child: Text('No videos found.',
                    style: TextStyle(color: Colors.grey))),
          )
              : SizedBox(
            height: cardHeight,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: videos.length,
              separatorBuilder: (_, __) => const SizedBox(width: 14),
              itemBuilder: (_, idx) {
                final video = videos[idx];
                final snippet = video['snippet'];
                final videoId = video['id']['videoId'];
                final videoTitle = _stripHtmlTags(snippet['title']);
                final channelTitle = snippet['channelTitle'];
                final thumbnailUrl = snippet['thumbnails']['medium']['url'];

                return GestureDetector(
                  onTap: () {
                    if (videoId != null && videoId is String && videoId.isNotEmpty) {
                      widget.onVideoTap?.call(videoId);
                    }
                  },
                  child: Container(
                    width: cardWidth,
                    decoration: BoxDecoration(
                      color: theme.cardColor,
                      borderRadius: BorderRadius.circular(14),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.12),
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
                          borderRadius: const BorderRadius.vertical(top: Radius.circular(14)),
                          child: CachedNetworkImage(
                            imageUrl: thumbnailUrl,
                            width: cardWidth,
                            height: 106,
                            fit: BoxFit.cover,
                            errorWidget: (context, error, stackTrace) =>
                                Container(
                                    width: cardWidth,
                                    height: 106,
                                    color: Colors.grey.shade300,
                                    alignment: Alignment.center,
                                    child: Icon(Icons.broken_image, size: 36, color: Colors.grey)
                                ),
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: Text(
                            videoTitle,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                              color: theme.colorScheme.onSurface,
                            ),
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 8.0),
                          child: Text(
                            channelTitle,
                            style: TextStyle(
                                color: Colors.grey.shade600, fontSize: 12),
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
