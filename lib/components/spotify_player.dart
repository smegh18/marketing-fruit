import 'package:Marketing_Fruit/screens/dashboard/main_layout.dart';
import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';
import 'package:http/http.dart' as http;
import 'package:xml/xml.dart';
import 'package:volume_controller/volume_controller.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'dart:async';

class LibsynPodcastPlayerController extends InheritedWidget {
  final LibsynPodcastPlayerState playerState;

  const LibsynPodcastPlayerController({
    required this.playerState,
    required super.child,
    super.key,
  });

  static LibsynPodcastPlayerState of(BuildContext context) {
    final controller = context.dependOnInheritedWidgetOfExactType<LibsynPodcastPlayerController>();
    assert(controller != null, 'LibsynPodcastPlayerController not found in context');
    return controller!.playerState;
  }

  @override
  bool updateShouldNotify(covariant InheritedWidget oldWidget) => false;
}


class LibsynPodcastPlayerState {
  final player = AudioPlayer();
  List<Map<String, dynamic>> queue = [];
  Map<String, dynamic>? currentEpisode;
  List<Map<String, dynamic>> allEpisodes = [];
  double currentVolume = 0.5;
  Duration duration = Duration.zero;
  Duration position = Duration.zero;
  bool showQueue = false;
  bool showDetails = true;
  bool isDisposed = false;

  StreamSubscription<Duration>? _positionSub;
  StreamSubscription<Duration?>? _durationSub;
  StreamSubscription<PlayerState>? _stateSub;
  void Function(double)? _volumeListener;

  LibsynPodcastPlayerState() {
    _listenStreams();
  }

  void _listenStreams() {
    _positionSub?.cancel();
    _positionSub = player.positionStream.listen((pos) => position = pos);

    _durationSub?.cancel();
    _durationSub = player.durationStream.listen((dur) => duration = dur ?? Duration.zero);

    _stateSub?.cancel();
    _stateSub = player.playerStateStream.listen((state) {
      if (state.processingState == ProcessingState.completed) {
        playNextInQueue();
      }
    });

    if (!kIsWeb) {
      VolumeController.instance.showSystemUI = true;
      _volumeListener = (double v) {
        currentVolume = v;
      };
      VolumeController.instance.addListener(_volumeListener!);
      VolumeController.instance.getVolume().then((v) => currentVolume = v);
    }
  }


  Future<void> initPlayer(String url, {bool autoPlay = true}) async {
    try {
      await player.setUrl(url);
      if (autoPlay) await player.play();
    } catch (e) {
      debugPrint('Error initializing player: $e');
    }
  }

  void playNextInQueue() {
    if (currentEpisode == null) return;
    final currentIndex = queue.indexWhere((ep) => ep['audioUrl'] == currentEpisode!['audioUrl']);
    if (currentIndex != -1 && currentIndex < queue.length - 1) {
      final nextEpisode = queue[currentIndex + 1];
      currentEpisode = nextEpisode;
      initPlayer(nextEpisode['audioUrl']);
    } else {
      // no next -> stop
      player.stop();
    }
  }

  void addToQueue(Map<String, dynamic> episode) {
    if (!queue.any((ep) => ep['audioUrl'] == episode['audioUrl'])) {
      queue.add(episode);
    }
  }

  /// Removes an episode safely from the queue. If it was the currently playing episode,
  /// advance to the next in queue if available, otherwise stop and clear currentEpisode.
  void removeFromQueue(String audioUrl) {
    final removingCurrent = currentEpisode != null && currentEpisode!['audioUrl'] == audioUrl;
    queue.removeWhere((q) => q['audioUrl'] == audioUrl);

    if (removingCurrent) {
      if (queue.isNotEmpty) {
        currentEpisode = queue.first;
        initPlayer(currentEpisode!['audioUrl']);
      } else {
        player.stop();
        currentEpisode = null;
      }
    }
  }

  Future<void> fetchEpisodes() async {
    final resp = await http.get(Uri.parse('https://feeds.libsyn.com/561905/rss'));
    if (resp.statusCode == 200) {
      final doc = XmlDocument.parse(resp.body);
      final items = doc.findAllElements('item');
      final episodes = items.map((item) {
        return {
          'title': item.getElement('title')?.text ?? '',
          'audioUrl': item.getElement('enclosure')?.getAttribute('url') ?? '',
          'imageUrl': item.findElements('itunes:image').isNotEmpty
              ? item.findElements('itunes:image').first.getAttribute('href') ?? ''
              : '',
          'description': item.getElement('description')?.text ?? '',
        };
      }).toList();
      allEpisodes.clear();
      allEpisodes.addAll(episodes);
    }
  }

  void disposeController() {
    if (isDisposed) return;
    player.stop();
    player.dispose();
    _positionSub?.cancel();
    _durationSub?.cancel();
    _stateSub?.cancel();
    if (!kIsWeb && _volumeListener != null) {
      VolumeController.instance.removeListener();
    }
    queue.clear();
    currentEpisode = null;
    allEpisodes.clear();
    isDisposed = true;
  }

  String stripHtmlTags(String htmlText) {
    final regex = RegExp(r'<[^>]*>', multiLine: true, caseSensitive: false);
    return htmlText.replaceAll(regex, '').replaceAll('&nbsp;', ' ').replaceAll('&amp;', '&').trim();
  }

  String format(Duration d) => "${d.inMinutes.remainder(60).toString().padLeft(2, '0')}:${d.inSeconds.remainder(60).toString().padLeft(2, '0')}";
}

class LibsynPodcastPlayerScreen extends StatefulWidget {
  final Map<String, dynamic> episode;
  final LibsynPodcastPlayerState playerState;
  final Future<void> Function()? onExplicitCloseTab;
  final void Function(Map<String, dynamic> episode)? onSwitchEpisode;

  const LibsynPodcastPlayerScreen({
    super.key,
    required this.episode,
    required this.playerState,
    this.onExplicitCloseTab,
    this.onSwitchEpisode,
  });

  @override
  State<LibsynPodcastPlayerScreen> createState() => _LibsynPodcastPlayerScreenState();
}

class _LibsynPodcastPlayerScreenState extends State<LibsynPodcastPlayerScreen> with AutomaticKeepAliveClientMixin {
  bool _initialized = false;
  bool _explicitlyClosing = false;
  LibsynPodcastPlayerState get state => widget.playerState;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_initialized) {
      if (state.currentEpisode == null || state.queue.isEmpty) {
        state.currentEpisode = widget.episode;
        state.queue.clear();
        state.queue.add(widget.episode);
        state.initPlayer(widget.episode['audioUrl']);
      }
      if (state.allEpisodes.isEmpty) {
        state.fetchEpisodes().then((_) => setState(() {}));
      }
      _initialized = true;
    }
  }

  @override
  void dispose() {
    if (_explicitlyClosing && widget.onExplicitCloseTab != null) {
      widget.onExplicitCloseTab!();
    }
    super.dispose();
  }

  void _switchEpisode(Map<String, dynamic> newEpisode) {
    setState(() {
      state.currentEpisode = newEpisode;
      // ensure current episode is in the queue (if not already)
      if (!state.queue.any((q) => q['audioUrl'] == newEpisode['audioUrl'])) {
        state.queue.insert(0, newEpisode);
      }
      state.initPlayer(newEpisode['audioUrl']);
    });
    widget.onSwitchEpisode?.call(newEpisode);
  }

  void _handleExplicitClose() {
    setState(() => _explicitlyClosing = true);
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => MainLayout(userRole: 'Student',nftindex: 7,),
      ),
    );
  }

  @override
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final theme = Theme.of(context);
    final media = MediaQuery.of(context);
    final episode = state.currentEpisode ?? widget.episode;

    return Scaffold(
      appBar: AppBar(
        title: Text(episode['title'] ?? 'Episode'),
        // leading: IconButton(
        //   icon: const Icon(Icons.arrow_back),
        //   onPressed: _handleExplicitClose,
        // ),
      ),
      body: Stack(
        children: [
          Row(
            children: [
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 30),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      GestureDetector(
                        onTap: () => setState(() => state.showDetails = !state.showDetails),
                        child: Container(
                          width: media.size.width * 0.4,
                          height: media.size.height * 0.4,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(16),
                            image: DecorationImage(
                              image: NetworkImage(episode['imageUrl'] ?? ''),
                              fit: kIsWeb ? BoxFit.fitHeight : BoxFit.cover,
                            ),
                            boxShadow: [BoxShadow(color: Colors.black26, blurRadius: 10)],
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),
                      if (state.showDetails) ...[
                        Align(
                          alignment: Alignment.centerLeft,
                          child: Text("Description", style: theme.textTheme.titleMedium),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          state.stripHtmlTags(episode['description'] ?? ''),
                          style: const TextStyle(fontSize: 14),
                        ),
                        const SizedBox(height: 24),
                        Align(
                          alignment: Alignment.centerLeft,
                          child: Text("Related Podcasts", style: theme.textTheme.titleMedium),
                        ),
                        ListView.separated(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: state.allEpisodes.length,
                          separatorBuilder: (_, __) => const Divider(),
                          itemBuilder: (context, index) {
                            final ep = state.allEpisodes[index];
                            final inQueue = state.queue.any((q) => q['audioUrl'] == ep['audioUrl']);

                            return ListTile(
                              leading: SizedBox(
                                width: 40,
                                height: 40,
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(8),
                                  child: Image.network(ep['imageUrl'] ?? '', fit: BoxFit.cover),
                                ),
                              ),
                              title: Text(ep['title'] ?? ''),
                              onTap: () => _switchEpisode(ep),
                              trailing: IconButton(
                                icon: Icon(
                                  inQueue ? Icons.queue : Icons.queue,
                                  color: inQueue ? Colors.green : null, // green when in queue
                                ),
                                onPressed: () {
                                  setState(() {
                                    if (inQueue) {
                                      state.removeFromQueue(ep['audioUrl']);
                                    } else {
                                      state.addToQueue(ep);
                                    }
                                  });
                                },
                              ),
                            );
                          },
                        ),
                        const SizedBox(height: 100),
                      ],
                    ],
                  ),
                ),
              ),
              if (kIsWeb)
                AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  width: state.showQueue ? 300 : 0,
                  height: media.size.height - 100,
                  decoration: BoxDecoration(
                    color: theme.cardColor,
                    boxShadow: [BoxShadow(color: Colors.black26, blurRadius: 8)],
                    border: Border(left: BorderSide(color: Colors.grey.shade300)),
                  ),
                  child: state.showQueue
                      ? Column(
                    children: [
                      Padding(
                        padding: const EdgeInsets.all(16),
                        child: Row(
                          children: [
                            Text("Queue", style: theme.textTheme.titleMedium),
                            const Spacer(),
                            IconButton(
                              icon: const Icon(Icons.close),
                              onPressed: () => setState(() => state.showQueue = false),
                            ),
                          ],
                        ),
                      ),
                      Expanded(
                        child: ListView.builder(
                          itemCount: state.queue.length,
                          itemBuilder: (_, index) {
                            final item = state.queue[index];
                            final isPlaying = item['audioUrl'] == episode['audioUrl'];
                            return ListTile(
                              minLeadingWidth: 48,
                              leading: SizedBox(
                                width: 40,
                                height: 40,
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(8),
                                  child: Image.network(item['imageUrl'] ?? '', fit: BoxFit.cover),
                                ),
                              ),
                              title: Text(item['title'] ?? ''),
                              trailing: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  if (isPlaying) const Icon(Icons.equalizer, color: Colors.green),
                                  IconButton(
                                    icon: const Icon(Icons.delete_outline),
                                    onPressed: () {
                                      setState(() {
                                        state.removeFromQueue(item['audioUrl']);
                                      });
                                    },
                                  ),
                                ],
                              ),
                              onTap: () => _switchEpisode(item),
                            );
                          },
                        ),
                      ),
                    ],
                  )
                      : null,
                )
            ],
          ),
          Positioned(
            left: 0,
            right: 0,
            bottom: 40,
            child: Material(
              elevation: 10,
              color: theme.scaffoldBackgroundColor,
              child: Container(
                padding: const EdgeInsets.fromLTRB(24, 12, 24, 12),
                constraints: const BoxConstraints(minHeight: 120),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Reactive progress and duration
                    StreamBuilder<Duration>(stream: state.player.positionStream, builder: (context, snapshot) {
                      final position = snapshot.data ?? Duration.zero;
                      final duration = state.duration > Duration.zero
                          ? state.duration
                          : (state.player.duration ?? Duration.zero);
                      final maxSeconds = duration.inSeconds > 0 ? duration.inSeconds.toDouble() : 1.0;
                      final valueSeconds = position.inSeconds.toDouble().clamp(0.0, maxSeconds);

                      return Column(
                        children: [
                          Slider(
                            activeColor: theme.cardColor,
                            inactiveColor: theme.hintColor,
                            value: valueSeconds,
                            min: 0.0,
                            max: maxSeconds,
                            onChanged: (val) {
                              state.player.seek(Duration(seconds: val.toInt()));
                              setState(() {});
                            },
                          ),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(state.format(position)),
                              Text(state.format(duration)),
                            ],
                          ),
                        ],
                      );
                    }),
                    const SizedBox(height: 4),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        IconButton(
                            icon: const Icon(Icons.replay_10),
                            onPressed: () => state.player.seek(
                              Duration(
                                  seconds: (state.position.inSeconds - 10).clamp(0, state.duration.inSeconds)),
                            )
                        ),
                        StreamBuilder<PlayerState>(
                          stream: state.player.playerStateStream,
                          builder: (_, snapshot) {
                            final playing = snapshot.data?.playing ?? false;
                            return IconButton(
                              iconSize: 48,
                              icon: Icon(playing ? Icons.pause_circle : Icons.play_circle),
                              onPressed: () => playing
                                  ? state.player.pause()
                                  : state.player.play(),
                            );
                          },
                        ),
                        IconButton(
                            icon: const Icon(Icons.forward_10),
                            onPressed: () => state.player.seek(
                              Duration(
                                  seconds: (state.position.inSeconds + 10).clamp(0, state.duration.inSeconds)),
                            )
                        ),
                        const SizedBox(width: 20),
                        if (kIsWeb) ...[
                          const Icon(Icons.volume_up),
                          const SizedBox(width: 16),
                          SizedBox(
                            width: 200,
                            child: Slider(
                              value: state.currentVolume,
                              min: 0.0,
                              max: 1.0,
                              onChanged: (val) {
                                if (kIsWeb) {
                                  state.player.setVolume(val);
                                } else {
                                  VolumeController.instance.setVolume(val);
                                }
                                setState(() => state.currentVolume = val);
                              },
                            ),
                          ),
                        ],
                        IconButton(
                          icon: const Icon(Icons.queue_music),
                          onPressed: () {
                            if (!kIsWeb) {
                              showModalBottomSheet(
                                context: context,
                                shape: const RoundedRectangleBorder(
                                  borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
                                ),
                                builder: (sheetContext) => SafeArea(
                                  child: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Padding(
                                        padding: const EdgeInsets.all(16),
                                        child: Row(
                                          children: [
                                            Text("Queue", style: theme.textTheme.titleMedium),
                                            const Spacer(),
                                            IconButton(
                                              icon: const Icon(Icons.close),
                                              onPressed: () => Navigator.of(sheetContext).pop(),
                                            ),
                                          ],
                                        ),
                                      ),
                                      SizedBox(
                                        height: 300,
                                        child: ListView.builder(
                                          shrinkWrap: true,
                                          itemCount: state.queue.length,
                                          itemBuilder: (_, index) {
                                            final item = state.queue[index];
                                            final isPlaying = item['audioUrl'] == episode['audioUrl'];
                                            return ListTile(
                                              minLeadingWidth: 48,
                                              leading: SizedBox(
                                                width: 40,
                                                height: 40,
                                                child: ClipRRect(
                                                  borderRadius: BorderRadius.circular(8),
                                                  child: Image.network(item['imageUrl'] ?? '', fit: BoxFit.cover),
                                                ),
                                              ),
                                              title: Text(item['title'] ?? ''),
                                              trailing: Row(
                                                mainAxisSize: MainAxisSize.min,
                                                children: [
                                                  if (isPlaying) const Icon(Icons.equalizer, color: Colors.green),
                                                  IconButton(
                                                    icon: const Icon(Icons.remove_circle_outline),
                                                    onPressed: () {
                                                      setState(() {
                                                        state.removeFromQueue(item['audioUrl']);
                                                      });
                                                      // keep the sheet open but update its contents
                                                    },
                                                  ),
                                                ],
                                              ),
                                              onTap: () {
                                                Navigator.of(sheetContext).pop();
                                                _switchEpisode(item);
                                              },
                                            );
                                          },
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            } else {
                              setState(() => state.showQueue = !state.showQueue);
                            }
                          },
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
