import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:Marketing_Fruit/components/categories_section.dart';
import 'package:youtube_player_iframe/youtube_player_iframe.dart';
import 'package:http/http.dart' as http;
import 'package:cached_network_image/cached_network_image.dart';

class VideoPlayerScreen extends StatefulWidget {
  final String videoId;
  final VoidCallback? onCloseTab;

  const VideoPlayerScreen({
    super.key,
    required this.videoId,
    this.onCloseTab,
  });

  @override
  State<VideoPlayerScreen> createState() => _VideoPlayerScreenState();
}

class _VideoPlayerScreenState extends State<VideoPlayerScreen> {
  late YoutubePlayerController _controller;
  String? videoTitle;
  String? channelTitle;
  String? videoDescription;
  List<dynamic> suggestedVideos = [];
  bool isLoadingSuggested = true;
  bool isLoadingDetails = true;

  @override
  void initState() {
    super.initState();
    fetchVideoDetails();
    fetchSuggestedVideos();

    _controller = YoutubePlayerController.fromVideoId(
      videoId: widget.videoId,
      params: const YoutubePlayerParams(
        showFullscreenButton: true,
        showControls: true,
        enableKeyboard: true,
      ),
    );

  }

  Future<void> fetchVideoDetails() async {
    const apiKey = String.fromEnvironment('YOUTUBE_API_KEY');
    final videoId = widget.videoId;
    final url =
        'https://www.googleapis.com/youtube/v3/videos?part=snippet&id=$videoId&key=$apiKey';

    final response = await http.get(Uri.parse(url));
    print('API Response for video details: ${response.body}');
    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      final items = data['items'];
      if (items != null && items.isNotEmpty) {
        final snippet = items[0]['snippet']; // FIXED!
        print(snippet['title']);
        // channelTitle may not be present, use fallback
        print(snippet['channelTitle'] ?? snippet['channelId']);
        print(snippet['description']);
        setState(() {
          videoTitle = snippet['title'];
          channelTitle = snippet['channelTitle'] ?? snippet['channelId'] ?? '';
          videoDescription = snippet['description'];
          isLoadingDetails = false;
        });
        print(isLoadingDetails);
      } else {
        setState(() {
          isLoadingDetails = false;
        });
      }
    } else {
      debugPrint('Failed to fetch video details');
      setState(() {
        isLoadingDetails = false;
      });
    }
  }


  Future<void> fetchSuggestedVideos() async {
    const apiKey = String.fromEnvironment('YOUTUBE_API_KEY');
    const channelId = 'UCXD2w9cm2BKLxkCzCk_rTLg';
    final url =
        'https://www.googleapis.com/youtube/v3/search?part=snippet&channelId=$channelId&order=date&maxResults=10&type=video&key=$apiKey';

    final response = await http.get(Uri.parse(url));
    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      final items = data['items'];
      final filtered = items.where((item) => item['id']?['videoId'] != null).toList();
      setState(() {
        suggestedVideos = filtered;
        isLoadingSuggested = false;
      });
    } else {
      debugPrint('Failed to fetch suggested videos');
      setState(() {
        isLoadingSuggested = false;
      });
    }
  }

  void playNewVideo(String videoId) {
    setState(() {
      // isLoadingDetails = true;
      _controller.loadVideoById(videoId: videoId);
      // videoTitle = null;
      // channelTitle = null;
      // videoDescription = null;
    });
    fetchVideoDetails();
  }

  @override
  void dispose() {
    _controller.close();
    super.dispose();
  }

  bool get isMobile {
    final w = MediaQuery.of(context).size.width;
    return w < 600;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    if (isMobile) {
      return Scaffold(
        backgroundColor: theme.scaffoldBackgroundColor,
        appBar: AppBar(
          backgroundColor: theme.cardColor,
          leading: IconButton(
            icon: Icon(Icons.arrow_back, color: theme.hintColor),
            onPressed: widget.onCloseTab ?? () => Navigator.of(context).maybePop(),
          ),
          title: const Text("Video Player"),
          elevation: 0,
        ),
        body: YoutubePlayerScaffold(
          controller: _controller,
          backgroundColor: theme.scaffoldBackgroundColor,
          builder: (context, player) => SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                /// Video Player
                Padding(
                  padding: const EdgeInsets.only(top: 6, left: 6, right: 6),
                  child: AspectRatio(
                    aspectRatio: 16 / 9,
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(16),
                      child: player,
                    ),
                  ),
                ),
                /// Video info + buttons
                Padding(
                  padding: const EdgeInsets.only(top: 12, left: 10, right: 10),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      isLoadingDetails
                          ? Row(
                        children: [
                          const SizedBox(
                            height: 18,
                            width: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          ),
                          const SizedBox(width: 10),
                          Text('Loading...', style: theme.textTheme.titleMedium),
                        ],
                      )
                          : Text(
                        videoTitle?.isNotEmpty == true
                            ? videoTitle!
                            : "No Title",
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          fontSize: 19,
                        ),
                      ),
                      const SizedBox(height: 2),
                      isLoadingDetails
                          ? SizedBox.shrink()
                          : Text(
                        channelTitle?.isNotEmpty == true ? channelTitle! : '',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.hintColor.withOpacity(0.95),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Row(
                        children: [
                          IconButton(icon: const Icon(Icons.thumb_up_alt_outlined), onPressed: () {}),
                          IconButton(icon: const Icon(Icons.share_outlined), onPressed: () {}),
                          IconButton(icon: const Icon(Icons.bookmark_border), onPressed: () {}),
                        ],
                      ),
                    ],
                  ),
                ),
                /// Video Description
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  child: isLoadingDetails
                      ? Text('Loading description...', style: theme.textTheme.bodyMedium)
                      : Text(
                    videoDescription?.isNotEmpty == true
                        ? videoDescription!
                        : 'No description available',
                    style: theme.textTheme.bodyMedium,
                  ),
                ),
                /// Ad Banner
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  child: Container(
                    width: double.infinity,
                    height: 85,
                    decoration: BoxDecoration(
                      color: Colors.grey.shade200,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.grey.shade300),
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      "Ad Banner Placeholder",
                      style: theme.textTheme.bodyMedium?.copyWith(
                        fontStyle: FontStyle.italic,
                        color: Colors.grey.shade700,
                      ),
                    ),
                  ),
                ),

                /// Suggested videos
                Padding(
                  padding: const EdgeInsets.only(left: 12, top: 6, bottom: 0),
                  child: Text(
                    "Suggested Videos",
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      fontSize: 17,
                    ),
                  ),
                ),
                SizedBox(
                  height: 120,
                  child: isLoadingSuggested
                      ? const Center(child: CircularProgressIndicator())
                      : suggestedVideos.isEmpty
                      ? Center(
                    child: Padding(
                      padding: EdgeInsets.all(18),
                      child:
                      Text('No suggested videos found.', style: TextStyle(color: theme.hintColor)),
                    ),
                  )
                      : ListView.separated(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
                    itemCount: suggestedVideos.length,
                    separatorBuilder: (_, __) => const SizedBox(width: 10),
                    itemBuilder: (ctx, idx) {
                      final video = suggestedVideos[idx];
                      final snippet = video['snippet'] ?? {};
                      final videoId = video['id']?['videoId'] ?? '';
                      final title = snippet['title'] ?? '';
                      final channel = snippet['channelTitle'] ?? '';
                      final thumbnail = snippet['thumbnails']?['medium']?['url'] ?? '';
                      return GestureDetector(
                        onTap: () => playNewVideo(videoId),
                        child: Container(
                          width: 200,
                          decoration: BoxDecoration(
                            color: theme.cardColor,
                            borderRadius: BorderRadius.circular(10),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.10),
                                blurRadius: 3,
                                offset: const Offset(0, 1),
                              ),
                            ],
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              ClipRRect(
                                borderRadius:
                                const BorderRadius.vertical(top: Radius.circular(10)),
                                child: thumbnail.isNotEmpty
                                    ? CachedNetworkImage(
                                  imageUrl: thumbnail,
                                  width: 200,
                                  height: 70,
                                  fit: BoxFit.cover,
                                  errorWidget: (_, __, ___) => Container(
                                    width: 200,
                                    height: 70,
                                    color: Colors.grey.shade300,
                                    alignment: Alignment.center,
                                    child: Icon(Icons.broken_image, color: Colors.grey, size: 36),
                                  ),
                                )
                                    : Container(
                                  width: 200,
                                  height: 70,
                                  color: Colors.grey.shade200,
                                ),
                              ),
                              Padding(
                                padding: const EdgeInsets.fromLTRB(7, 6, 7, 0),
                                child: Text(
                                  title,
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    fontWeight: FontWeight.w600,
                                    fontSize: 13,
                                    color: theme.hintColor,
                                  ),
                                ),
                              ),
                              Padding(
                                padding: const EdgeInsets.only(left: 7, bottom: 4, right: 7, top: 2),
                                child: Text(
                                  channel,
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: theme.hintColor.withOpacity(0.7),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),

                /// Comments Title
                Padding(
                  padding: const EdgeInsets.only(top:16, left: 12, bottom: 4),
                  child: Text(
                    "Comments",
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      fontSize: 17,
                    ),
                  ),
                ),

                /// Add Comment Field
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 4),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      CircleAvatar(
                        radius: 16,
                        child: Text('J'),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: TextField(
                          maxLines: null,
                          decoration: InputDecoration(
                            hintText: 'Add a comment...',
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            contentPadding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                /// Comments List
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12.0),
                  child: Column(children: _buildCommentList(theme)),
                ),

                /// Categories at bottom
                Padding(
                  padding: const EdgeInsets.only(top: 15, left: 4, right: 4, bottom: 14),
                  child: CategoriesSectionWidget(categories: demoCategories),
                ),
              ],
            ),
          ),
        ),
      );
    } else {
      // --- WEB/DESKTOP VIEW UNCHANGED ---
      final width = MediaQuery.of(context).size.width;
      final height = width / (16 / 9);

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
        child: YoutubePlayerScaffold(
          backgroundColor: theme.cardColor,
          controller: _controller,
          builder: (context, player) => Scaffold(
            appBar: AppBar(
              backgroundColor: theme.cardColor,
              leading: IconButton(
                icon: Icon(Icons.arrow_back, color: theme.hintColor),
                onPressed: widget.onCloseTab ?? () => Navigator.of(context).maybePop(),
              ),
              title: const Text("Video Player"),
            ),
            body: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                /// Left: Video + Comments
                Expanded(
                  flex: 3,
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        AspectRatio(
                          aspectRatio: 16 / 9,
                          child: Container(
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(16),
                              color: theme.cardColor,
                            ),
                            child: player,
                          ),
                        ),
                        const SizedBox(height: 16),
                        // Title & Channel
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    videoTitle ?? 'Loading...',
                                    style: theme.textTheme.titleMedium?.copyWith(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 18,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    channelTitle ?? '',
                                    style: theme.textTheme.bodySmall?.copyWith(
                                      color: theme.hintColor,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                IconButton(
                                  icon: const Icon(Icons.thumb_up_alt_outlined),
                                  tooltip: "Like",
                                  onPressed: () {},
                                ),
                                IconButton(
                                  icon: const Icon(Icons.share_outlined),
                                  tooltip: "Share",
                                  onPressed: () {},
                                ),
                                IconButton(
                                  icon: const Icon(Icons.bookmark_border),
                                  tooltip: "Save",
                                  onPressed: () {},
                                ),
                              ],
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        Text(
                          videoDescription ?? 'Loading description...',
                          style: theme.textTheme.bodyMedium,
                        ),
                        const SizedBox(height: 24),
                        Container(
                          height: 100,
                          width: double.infinity,
                          decoration: BoxDecoration(
                            color: Colors.grey.shade300,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.grey.shade400),
                          ),
                          alignment: Alignment.center,
                          child: Text(
                            "Ad Banner Placeholder",
                            style: theme.textTheme.bodyMedium?.copyWith(
                              fontStyle: FontStyle.italic,
                              color: Colors.grey.shade700,
                            ),
                          ),
                        ),
                        const SizedBox(height: 24),
                        Text(
                          "Comments",
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                            fontSize: 18,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const CircleAvatar(child: Text('J')),
                            const SizedBox(width: 12),
                            Expanded(
                              child: TextField(
                                maxLines: null,
                                decoration: InputDecoration(
                                  hintText: 'Add a comment...',
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  contentPadding: const EdgeInsets.symmetric(
                                      vertical: 12, horizontal: 16),
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 24),
                        ..._buildCommentList(theme),
                        CategoriesSectionWidget(categories: demoCategories)
                      ],
                    ),
                  ),
                ),
                /// Right: Suggested Videos
                Expanded(
                  flex: 2,
                  child: Padding(
                    padding: const EdgeInsets.only(right: 62, top: 16, bottom: 16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "Suggested Videos",
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                            fontSize: 18,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Expanded(
                          child: ListView.builder(
                            itemCount: suggestedVideos.length,
                            itemBuilder: (context, index) {
                              final video = suggestedVideos[index];
                              final snippet = video['snippet'] ?? {};
                              final videoId = video['id']?['videoId'] ?? '';
                              final title = snippet['title'] ?? '';
                              final channel = snippet['channelTitle'] ?? '';
                              final thumbnail = snippet['thumbnails']?['medium']?['url'] ?? '';
                              return GestureDetector(
                                onTap: () => playNewVideo(videoId),
                                child: Container(
                                  margin: const EdgeInsets.only(bottom: 12),
                                  height: 90,
                                  decoration: BoxDecoration(
                                    color: theme.cardColor,
                                    borderRadius: BorderRadius.circular(10),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black.withOpacity(0.1),
                                        blurRadius: 4,
                                        offset: const Offset(0, 2),
                                      ),
                                    ],
                                  ),
                                  child: Row(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      ClipRRect(
                                        borderRadius: const BorderRadius.horizontal(left: Radius.circular(10)),
                                        child: thumbnail.isNotEmpty
                                            ? CachedNetworkImage(
                                          imageUrl: thumbnail,
                                          width: 120,
                                          height: 90,
                                          fit: BoxFit.cover,
                                          errorWidget: (_, __, ___) => Container(
                                            width: 120,
                                            height: 90,
                                            color: Colors.grey.shade300,
                                            alignment: Alignment.center,
                                            child: Icon(Icons.broken_image, color: Colors.grey, size: 36),
                                          ),
                                        )
                                            : Container(
                                          width: 120,
                                          height: 90,
                                          color: Colors.grey.shade200,
                                        ),
                                      ),
                                      Expanded(
                                        child: Padding(
                                          padding: const EdgeInsets.all(8.0),
                                          child: Column(
                                            mainAxisAlignment: MainAxisAlignment.center,
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                title,
                                                maxLines: 2,
                                                overflow: TextOverflow.ellipsis,
                                                style: TextStyle(
                                                  fontWeight: FontWeight.w600,
                                                  fontSize: 13,
                                                  color: theme.hintColor,
                                                  height: 1.2,
                                                ),
                                              ),
                                              const SizedBox(height: 4),
                                              Text(
                                                channel,
                                                style: TextStyle(
                                                  fontSize: 12,
                                                  color: theme.hintColor.withOpacity(0.7),
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
                            },
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }
  }

  final List<CategoryItem> demoCategories = [
    CategoryItem(name: "Category 1", imagePath: "assets/Assets/bandar.png"),
    CategoryItem(name: "Category 2", imagePath: "assets/Assets/music.png"),
    CategoryItem(name: "Category 3", imagePath: "assets/Assets/paint.png"),
    CategoryItem(name: "Category 4", imagePath: "assets/Assets/taklu.png"),
    CategoryItem(name: "Category 5", imagePath: "assets/Assets/choti.png"),
  ];

  List<Widget> _buildCommentList(ThemeData theme) {
    final comments = [
      {
        "user": "R",
        "name": "@raviradityaraj1422",
        "time": "6 months ago",
        "comment":
        "Craziest part is that Gukesh is a World Champion now... so proud of him",
        "likes": "12K",
        "replies": "25 replies",
      },
      {
        "user": "N",
        "name": "@NitinKr7",
        "time": "6 months ago",
        "comment":
        "YouTube recommended me after gukesh became world chess champion ❤️",
        "likes": "10K",
        "replies": "31 replies",
      },
      {
        "user": "P",
        "name": "@panchamichatterjee",
        "time": "8 days ago",
        "comment":
        "Chaotic background. Both of them are disturbing them too much.",
        "likes": "363",
        "replies": "5 replies",
      },
      {
        "user": "Y",
        "name": "@yashureddy2",
        "time": "3 months ago",
        "comment":
        "YouTube recommended me after Gukesh becoming world champion and samay's issue 😢",
        "likes": "249",
        "replies": "7 replies",
      },
    ];

    return comments.map((comment) {
      return Padding(
        padding: const EdgeInsets.only(bottom: 16.0),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            CircleAvatar(radius: 16, child: Text(comment["user"]!)),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "${comment["name"]} • ${comment["time"]}",
                    style: theme.textTheme.bodySmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(comment["comment"]!, style: theme.textTheme.bodyMedium),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Icon(Icons.thumb_up_alt_outlined, size: 18, color: theme.iconTheme.color),
                      const SizedBox(width: 4),
                      Text(comment["likes"]!, style: theme.textTheme.bodySmall),
                      const SizedBox(width: 16),
                      Text("Reply", style: theme.textTheme.bodySmall?.copyWith(fontWeight: FontWeight.w500)),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    comment["replies"]!,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.primaryColor,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            )
          ],
        ),
      );
    }).toList();
  }
}
