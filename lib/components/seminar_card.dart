import 'dart:async';
import 'dart:convert'; // For JSON parsing
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:Marketing_Fruit/screens/dashboard/main_layout.dart';
import 'package:Marketing_Fruit/screens/dashboard/user_event_page.dart';

/// ------------------------------
/// Event model
/// ------------------------------
class Event {
  final String id;
  final String name;
  final String bannerUrl;
  final String description;

  Event({
    required this.id,
    required this.name,
    required this.bannerUrl,
    required this.description,
  });

  factory Event.fromMap(String id, Map<dynamic, dynamic> map) {
    String parsedDescription = "";
    final descRaw = map['eventDescription'];

    if (descRaw is String) {
      try {
        final decoded = json.decode(descRaw);
        if (decoded is Map && decoded.containsKey('insert')) {
          parsedDescription = decoded['insert'].toString();
        } else {
          parsedDescription = descRaw;
        }
      } catch (_) {
        parsedDescription = descRaw;
      }
    } else if (descRaw is Map && descRaw.containsKey('insert')) {
      parsedDescription = descRaw['insert'].toString();
    } else if (descRaw is List) {
      parsedDescription = descRaw.map((e) => e.toString()).join(' ');
    } else {
      parsedDescription = descRaw?.toString() ?? '';
    }

    return Event(
      id: id,
      name: map['eventName'] ?? '',
      bannerUrl: map['bannerUrl'] ?? '',
      description: parsedDescription,
    );
  }
}

/// ------------------------------
/// Carousel
/// ------------------------------
class EventCarousel extends StatefulWidget {
  final double width;

  const EventCarousel({super.key, this.width = 0.3});

  @override
  State<EventCarousel> createState() => _EventCarouselState();
}

class _EventCarouselState extends State<EventCarousel> {
  late final DatabaseReference _ref;
  List<Event> _events = [];
  bool _loading = true;

  late PageController _pageController;
  int _currentPage = 0;
  Timer? _autoSlideTimer;
  bool _isHovering = false;

  @override
  void initState() {
    super.initState();
    _ref = FirebaseDatabase.instance.ref('events');
    _fetchEvents();
    _pageController = PageController(viewportFraction: widget.width);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _startAutoSlide();
    });
  }

  Future<void> _fetchEvents() async {
    final snapshot = await _ref.get();
    final List<Event> events = [];
    if (snapshot.exists) {
      final data = Map<String, dynamic>.from(snapshot.value as Map);
      data.forEach((key, value) {
        events.add(Event.fromMap(key, Map<dynamic, dynamic>.from(value)));
      });
    }
    if (!mounted) return;
    setState(() {
      _events = events;
      _loading = false;
    });
  }

  void _startAutoSlide() {
    _autoSlideTimer?.cancel();
    if (_isHovering || _events.isEmpty) return;
    _autoSlideTimer = Timer.periodic(const Duration(seconds: 3), (_) {
      if (!mounted) return;
      if (_events.isNotEmpty && _pageController.hasClients) {
        _currentPage = (_currentPage + 1) % _events.length;
        _pageController.animateToPage(
          _currentPage,
          duration: const Duration(milliseconds: 400),
          curve: Curves.easeInOut,
        );
      }
    });
  }

  void _pauseAutoSlide() {
    _autoSlideTimer?.cancel();
    _autoSlideTimer = null;
  }

  @override
  void dispose() {
    _pauseAutoSlide();
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) return const Center(child: CircularProgressIndicator());
    if (_events.isEmpty) return const Center(child: Text('No events found'));

    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) {
        _isHovering = true;
        _pauseAutoSlide();
      },
      onExit: (_) {
        _isHovering = false;
        _startAutoSlide();
      },
      child: SizedBox(
        height: 400,
        child: PageView.builder(
          controller: _pageController,
          itemCount: _events.length,
          itemBuilder: (context, index) => SeminarCard(event: _events[index]),
          onPageChanged: (page) => _currentPage = page,
        ),
      ),
    );
  }
}

/// ------------------------------
/// SeminarCard
/// ------------------------------
class SeminarCard extends StatelessWidget {
  final Event event;
  const SeminarCard({super.key, required this.event});

  String _parseDescription(dynamic desc) {
    if (desc == null) return '';
    if (desc is String) {
      try {
        final decoded = jsonDecode(desc);
        if (decoded is List) {
          return decoded
              .where((op) => op is Map && op.containsKey('insert'))
              .map((op) => op['insert'] ?? '')
              .join('')
              .trim();
        }
        if (decoded is Map && decoded['ops'] is List) {
          return (decoded['ops'] as List)
              .where((op) => op is Map && op.containsKey('insert'))
              .map((op) => op['insert'] ?? '')
              .join('')
              .trim();
        }
      } catch (_) {
        return desc;
      }
      return desc;
    }
    if (desc is List) {
      return desc
          .where((op) => op is Map && op.containsKey('insert'))
          .map((op) => op['insert'] ?? '')
          .join('')
          .trim();
    }
    if (desc is Map && desc['ops'] is List) {
      return (desc['ops'] as List)
          .where((op) => op is Map && op.containsKey('insert'))
          .map((op) => op['insert'] ?? '')
          .join('')
          .trim();
    }
    return '';
  }

  void _goToDetails(BuildContext context) {
    // If it's a mobile device, navigate to the specific event page
    if (!kIsWeb && MediaQuery.of(context).size.shortestSide < 600) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => UserEventDashboardPage(eventId: event.id, userRole: 'student'),
        ),
      );
    } else {
      // Otherwise navigate to the desktop events tab
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => MainLayout(userRole: 'student', nftindex: 6),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final dpi = MediaQueryData.fromView(WidgetsBinding.instance.window).devicePixelRatio;
    double scale = (dpi > 1.0 && dpi < 2.0) ? 1.16 : (dpi >= 2.0 ? 0.9 : 1.0);

    return LayoutBuilder(
      builder: (context, constraints) {
        final cardWidth = constraints.maxWidth * 1.0;

        return SizedBox(
          width: cardWidth * 0.3,
          height: 400 * scale,
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: () => _goToDetails(context),
            child: Container(
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
              child: ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: Center(
                  child: FractionallySizedBox(
                    widthFactor: 0.94,
                    heightFactor: 0.92,
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(16),
                          child: event.bannerUrl.isNotEmpty
                              ? Image.network(
                                  event.bannerUrl,
                                  fit: BoxFit.cover,
                                  errorBuilder: (_, __, ___) =>
                                      Container(color: Colors.grey[300]),
                                )
                              : Image.asset(
                                  'assets/seminar_bg.png',
                                  fit: BoxFit.cover,
                                ),
                        ),
                        Container(
                          padding: const EdgeInsets.all(20),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                event.name.isNotEmpty
                                    ? event.name
                                    : "Upcoming Seminars",
                                style: GoogleFonts.poppins(
                                  fontSize: 22,
                                  fontWeight: FontWeight.w700,
                                  color: Colors.white,
                                ),
                              ),
                              const SizedBox(height: 16),
                              Text(
                                event.description.isNotEmpty
                                    ? _parseDescription(event.description)
                                    : "Collaboration is an evolutionarily recent positive-\nsum game.\nIt is all about who take the opportunity first.",
                                style: const TextStyle(
                                  fontSize: 16,
                                  color: Colors.white,
                                  height: 1.5,
                                ),
                                maxLines: 4,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const Spacer(),
                              Row(
                                mainAxisSize: MainAxisSize.min,
                                children: const [
                                  Text(
                                    "Read more",
                                    style: TextStyle(
                                      fontSize: 16,
                                      color: Colors.white,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                  SizedBox(width: 6),
                                  Icon(Icons.arrow_forward,
                                      color: Colors.white, size: 18),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
