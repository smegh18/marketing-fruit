import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:cached_network_image/cached_network_image.dart';

import 'category_filter_bar.dart';

class YouTubeSectionWidget extends StatefulWidget {
  final String? heading;
  final bool showFilters;
  final void Function(String videoId)? onVideoTap;

  const YouTubeSectionWidget({
    super.key,
    this.heading,
    this.showFilters = true,
    this.onVideoTap,
  });

  @override
  _YouTubeSectionWidgetState createState() => _YouTubeSectionWidgetState();
}

class _YouTubeSectionWidgetState extends State<YouTubeSectionWidget> {
  final List<String> categories = ['All', 'Books', 'Podcast', 'Videos', 'Research Reports'];
  String selectedCategory = 'All';
  List<dynamic> videos = [];

  @override
  void initState() {
    super.initState();
    fetchVideos(); // Fetch default (All)
  }

  Future<void> fetchVideos() async {
    final apikey = dotenv.env['YOUTUBE_API_KEY'];
    const apiKey = String.fromEnvironment('YOUTUBE_API_KEY');
    const channelId = 'UCXD2w9cm2BKLxkCzCk_rTLg'; // <-- Replace with real channel ID

    final url =
        'https://www.googleapis.com/youtube/v3/search?part=snippet&channelId=$channelId&order=date&maxResults=10&type=video&key=$apiKey';

    final response = await http.get(Uri.parse(url));
    print(response.statusCode);
    if (response.statusCode == 200) {
      final decoded = json.decode(response.body);
      final items = decoded['items'];
      final validVideos = items.where((item) => item['id']?['videoId'] != null).toList();

      setState(() {
        videos = validVideos;
      });
    } else {
      print("Failed to fetch channel videos");
    }
  }


  void onSearchChanged(String query) {
    fetchVideos();
  }

  void onVoiceSearch() {
    // Placeholder for voice search logic
    debugPrint('Voice search triggered');
  }

  String _stripHtmlTags(String htmlText) {
    final regex = RegExp(r'<[^>]*>', multiLine: true, caseSensitive: false);
    return htmlText.replaceAll(regex, '').replaceAll('&quot;', '?').replaceAll('&amp;', '&').trim();
  }


  void onCategorySelected(String category) {
    setState(() {
      selectedCategory = category;
    });
    String query = category == 'All' ? 'trending' : category.toLowerCase();
    fetchVideos();
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;
    final scale = MediaQuery.of(context).devicePixelRatio * 0.6;
    final theme = Theme.of(context);

    return Container(
      width: screenWidth * 0.92,
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          /// Filters (Optional)
          if (widget.showFilters)
            CategoryFilterBar(
              categories: categories,
              selectedCategory: selectedCategory,
              onCategorySelected: onCategorySelected,
              onSearchChanged: onSearchChanged,
              onVoiceSearch: onVoiceSearch,
            ),
          if (widget.showFilters) const SizedBox(height: 12),

          /// Optional Heading
          // if (widget.heading != null && widget.heading!.isNotEmpty)
          //   Padding(
          //     padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 4),
          //     child: Text(
          //       widget.heading!,
          //       style: GoogleFonts.poppins(
          //         fontSize: 22 * scale.clamp(1.0, 1.2),
          //         fontWeight: FontWeight.bold,
          //         color: theme.hintColor,
          //       ),
          //     ),
          //   ),

          /// Video Cards
          /// Video Cards with Heading inside
          Container(
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
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                /// Optional Heading (moved inside container)
                if (widget.heading != null && widget.heading!.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 8.0),
                    child: Text(
                      widget.heading!,
                      style: GoogleFonts.poppins(
                        fontSize: 22 * scale.clamp(1.0, 1.2),
                        fontWeight: FontWeight.bold,
                        color: theme.hintColor,
                      ),
                    ),
                  ),

                /// Video List
                SizedBox(
                  height: screenHeight * 0.33, // adjusted to fit heading
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      final scrollController = ScrollController();

                      return Scrollbar(
                        controller: scrollController,
                        thumbVisibility: true,
                        trackVisibility: true,
                        radius: const Radius.circular(8),
                        thickness: 6,
                        scrollbarOrientation: ScrollbarOrientation.bottom,
                        child: ListView.separated(
                          controller: scrollController,
                          scrollDirection: Axis.horizontal,
                          padding: const EdgeInsets.only(bottom: 20),
                          itemCount: videos.length,
                          separatorBuilder: (_, __) => const SizedBox(width: 12),
                          itemBuilder: (_, index) {
                            final video = videos[index];
                            final snippet = video['snippet'];
                            final videoTitle = _stripHtmlTags(snippet['title']);
                            final channelTitle = snippet['channelTitle'];
                            final thumbnailUrl = snippet['thumbnails']['medium']['url'];

                            return GestureDetector(
                              onTap: () {
                                final videoId = video['id']?['videoId'];
                                if (videoId != null && videoId is String && videoId.isNotEmpty) {
                                  widget.onVideoTap?.call(videoId);
                                } else {
                                  debugPrint('Invalid videoId: $videoId');
                                }
                              },
                              child: Container(
                                width: screenWidth * 0.2,
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(8),
                                  color: theme.cardColor,
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withOpacity(0.5),
                                      spreadRadius: 2,
                                      blurRadius: 5,
                                      offset: const Offset(0, 3),
                                    ),
                                  ],
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    ClipRRect(
                                      borderRadius: const BorderRadius.vertical(top: Radius.circular(8)),
                                      child: CachedNetworkImage(
                                        imageUrl: thumbnailUrl,
                                        width: double.infinity,
                                        height: constraints.maxHeight * 0.7,
                                        fit: BoxFit.fitWidth,
                                      ),
                                    ),
                                    Padding(
                                      padding: const EdgeInsets.all(5.0),
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            videoTitle,
                                            maxLines: 2,
                                            overflow: TextOverflow.ellipsis,
                                            style: TextStyle(
                                              fontSize: scale == 0.6 ? 14 : 14 * scale,
                                              fontWeight: FontWeight.w600,
                                              color: theme.hintColor,
                                            ),
                                          ),
                                          const SizedBox(height: 2),
                                          Text(
                                            channelTitle,
                                            style: TextStyle(
                                              color: theme.hintColor,
                                              fontSize: scale == 0.6 ? 12 : 12 * scale,
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
              ],
            ),
          ),
        ],
      ),
    );
  }
}
