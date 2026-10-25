// ... imports remain unchanged
import 'dart:convert';
import 'dart:math';
import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:url_launcher/url_launcher.dart';

class EventCalendarFrontendSection extends StatefulWidget {
  final String userRole;
  final VoidCallback? onEventCreated;
  final void Function(String id, {String? eventName}) onEventTap;

  const EventCalendarFrontendSection({
    super.key,
    this.onEventCreated,
    required this.onEventTap, required this.userRole,
  });

  @override
  State<EventCalendarFrontendSection> createState() => _EventCalendarFrontendSectionState();
}

class _EventCalendarFrontendSectionState extends State<EventCalendarFrontendSection> {
  final DateTime _focusedDay = DateTime.now();
  OverlayEntry? _overlayEntry;
  bool _isHoveringStrip = false;
  bool _isHoveringPopup = false;
  Timer? _hideTimer;
  Timer? _showTimer;
  Rect? _lastTargetRect;

  List<Map<String, dynamic>> _events = [];
  List<Map<String, dynamic>> _recentEvents = [];

  String? _currentUserId;

  @override
  void initState() {
    super.initState();
    _getCurrentUserId();
    _fetchEvents();
  }

  Future<void> _getCurrentUserId() async {
    final user = FirebaseAuth.instance.currentUser;
    setState(() {
      _currentUserId = user?.uid;
    });
  }

  void _fetchEvents() async {
    DatabaseReference ref = FirebaseDatabase.instance.ref('events');
    ref.onValue.listen((event) async {
      final data = event.snapshot.value;
      if (data == null || data is! Map) {
        setState(() {
          _events = [];
          _recentEvents = [];
        });
        return;
      }
      final List<Map<String, dynamic>> items = [];

      for (var entry in (data).entries) {
        final key = entry.key;
        final value = entry.value;
        if (value is Map) {
          DateTime? start, end;
          try {
            if (value['start'] != null) {
              if (value['start'] is String) {
                start = DateTime.parse(value['start']);
              } else if (value['start'] is int) {
                start = DateTime.fromMillisecondsSinceEpoch(value['start']);
              }
            } else if (value['eventTime'] != null && value['eventTime'] is String) {
              start = DateTime.tryParse(value['eventTime']);
            }

            if (value['end'] != null) {
              if (value['end'] is String) {
                end = DateTime.parse(value['end']);
              } else if (value['end'] is int) {
                end = DateTime.fromMillisecondsSinceEpoch(value['end']);
              }
            } else {
              end = start;
            }
          } catch (_) {}
          final registeredUsersRaw = value['registeredUsers'];
          final attendeesCount = (registeredUsersRaw is Map) ? registeredUsersRaw.length : 0;

          items.add({
            ...value,
            'id': key,
            'start': start,
            'end': end ?? start,
            'registeredUsers': registeredUsersRaw is Map ? registeredUsersRaw : {},
            'attendeesCount': attendeesCount,  // Include attendee count for fast display
          });
        }
      }

      items.sort((a, b) {
        final aStart = a['start'] as DateTime? ?? DateTime.fromMillisecondsSinceEpoch(0);
        final bStart = b['start'] as DateTime? ?? DateTime.fromMillisecondsSinceEpoch(0);
        return bStart.compareTo(aStart);
      });

      setState(() {
        _events = items;
        _recentEvents = _generateRecentEvents(items);
      });
    });
  }

  List<Map<String, dynamic>> _generateRecentEvents(List<Map<String, dynamic>> events) {
    return events.take(5).map((e) {
      return {
        'date': e['start'],
        'name': e['eventName'] ?? e['name'] ?? '',
        'location': e['organizedBy'] ?? e['organizer'] ?? '',
        'description': _parseDescription(e['eventDescription'] ?? e['description']),
        'time': 'All Day',
        'color': _parseEventColor(e['color'], e['id'].toString()),
        'banner': e['banner'] ?? e['logoUrl'] ?? "",
      };
    }).toList();
  }

  List<Map<String, dynamic>> _getEventsForDay(DateTime day) {
    return _events.where((event) {
      final DateTime? start = event['start'];
      final DateTime? end = event['end'] ?? event['start'];
      if (start == null || end == null) return false;
      final dayUtc = DateTime.utc(day.year, day.month, day.day);
      final startUtc = DateTime.utc(start.year, start.month, start.day);
      final endUtc = DateTime.utc(end.year, end.month, end.day);
      return !dayUtc.isBefore(startUtc) && !dayUtc.isAfter(endUtc);
    }).toList();
  }

  static Color _parseEventColor(dynamic c, [String? eventId]) {
    if (c is Color) return c;
    if (c is int) return Color(c);
    if (c is String) {
      try {
        if (c.startsWith('#')) {
          return Color(int.parse('FF${c.substring(1)}', radix: 16));
        }
        return Color(int.parse(c.replaceFirst('0x', ''), radix: 16));
      } catch (_) {}
    }
    if (eventId != null) {
      final hash = eventId.hashCode;
      final random = Random(hash);
      return Color(0xFF000000 | random.nextInt(0x00FFFFFF));
    } else {
      final random = Random();
      return Color(0xFF000000 | random.nextInt(0x00FFFFFF));
    }
  }

  static String _parseDescription(dynamic desc) {
    if (desc == null) return '';
    if (desc is String) {
      try {
        final decoded = jsonDecode(desc);
        if (decoded is List) {
          return decoded
              .where((op) => op is Map && op.containsKey('insert'))
              .map((op) => op['insert'] ?? '')
              .join('')
              .toString()
              .trim();
        }
        if (decoded is Map && decoded['ops'] is List) {
          return (decoded['ops'] as List)
              .where((op) => op is Map && op.containsKey('insert'))
              .map((op) => op['insert'] ?? '')
              .join('')
              .toString()
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
          .toString()
          .trim();
    }
    if (desc is Map && desc['ops'] is List) {
      return (desc['ops'] as List)
          .where((op) => op is Map && op.containsKey('insert'))
          .map((op) => op['insert'] ?? '')
          .join('')
          .toString()
          .trim();
    }
    return '';
  }

  // ---------- Popup control with intent timers ----------

  void _scheduleShow(Rect targetRect, Map<String, dynamic> event) {
    _showTimer?.cancel();
    _showTimer = Timer(const Duration(milliseconds: 60), () {
      _showPopupAt(targetRect, event);
    });
  }

  void _scheduleHide() {
    _hideTimer?.cancel();
    _hideTimer = Timer(const Duration(milliseconds: 220), () {
      if (!_isHoveringStrip && !_isHoveringPopup) {
        _hidePopup();
      }
    });
  }

  /// ---------- CORE LOGIC: determine if current user is registered for event ----------
  bool _isUserRegistered(Map<String, dynamic> event) {
    if (_currentUserId == null) return false;
    final registeredUsers = event['registeredUsers'];
    if (registeredUsers == null) return false;
    if (registeredUsers is Map && registeredUsers.containsKey(_currentUserId)) return true;
    return false;
  }

  void _showPopupAt(Rect targetRect, Map<String, dynamic> event) {
    _lastTargetRect = targetRect;
    _overlayEntry?.remove();
    _overlayEntry = _buildOverlay(targetRect, event);
    Overlay.of(context).insert(_overlayEntry!);
  }

  OverlayEntry _buildOverlay(Rect targetRect, Map<String, dynamic> event) {
    const popupSize = Size(250, 250);
    final screenSize = MediaQuery.of(context).size;
    const margin = 8.0;

    double left = targetRect.left;
    if (left + popupSize.width > screenSize.width - margin) {
      left = screenSize.width - margin - popupSize.width;
    }
    if (left < margin) left = margin;

    double top = targetRect.top - popupSize.height - margin;
    if (top < margin) {
      top = targetRect.bottom + margin;
      if (top + popupSize.height > screenSize.height - margin) {
        top = screenSize.height - margin - popupSize.height;
      }
    }

    String banner = event['banner'] ?? event['logoUrl'] ?? "";
    if (banner.startsWith('data:image') && banner.length > 30) {
      banner = '';
    }

    final parsedColor = _parseEventColor(event['color'], event['id'].toString());

    // --- Decide action label ---
    String actionLabel;
    if (widget.userRole == "admin") {
      actionLabel = "View Details";
    } else if (_isUserRegistered(event)) {
      actionLabel = "View Details";
    } else {
      actionLabel = "Register";
    }

    // Get attendee count:
    final attendeesCount = event['attendeesCount'] ?? 0;

    return OverlayEntry(
      builder: (context) => Positioned(
        left: left,
        top: top,
        width: popupSize.width,
        height: popupSize.height,
        child: MouseRegion(
          onEnter: (_) {
            _isHoveringPopup = true;
            _hideTimer?.cancel();
          },
          onExit: (_) {
            _isHoveringPopup = false;
            _scheduleHide();
          },
          child: Material(
            elevation: 8,
            borderRadius: BorderRadius.circular(8),
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(8),
                boxShadow: [BoxShadow(color: Colors.black26, blurRadius: 6)],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  banner.isNotEmpty
                      ? ClipRRect(
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(8)),
                    child: InkWell(
                      onTap: () {
                        final uri = Uri.tryParse(banner);
                        if (uri != null && (uri.isScheme('http') || uri.isScheme('https'))) {
                          launchUrl(uri, mode: LaunchMode.externalApplication);
                        }
                      },
                      child: Image.network(
                        banner,
                        width: popupSize.width,
                        height: 90,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stack) => Container(
                          width: popupSize.width,
                          height: 90,
                          color: Colors.grey[200],
                          child: const Icon(Icons.broken_image, color: Colors.grey, size: 32),
                        ),
                      ),
                    ),
                  )
                      : Container(
                    width: popupSize.width,
                    height: 90,
                    color: Colors.grey[200],
                    child: const Icon(Icons.image, color: Colors.grey, size: 32),
                  ),
                  Container(
                    padding: const EdgeInsets.all(8),
                    height: popupSize.height - 90,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          event['eventName'] ?? event['name'] ?? "",
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: parsedColor,
                            fontSize: 15,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        Text(
                          event['organizedBy'] ?? event['organizer'] ?? "",
                          style: const TextStyle(fontSize: 12, color: Colors.grey),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          _parseDescription(event['eventDescription'] ?? event['description']),
                          style: const TextStyle(fontSize: 12, color: Colors.black87),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const Spacer(),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Row(
                              children: [
                                const Icon(Icons.people, size: 14, color: Colors.grey),
                                const SizedBox(width: 4),
                                Text(
                                  '$attendeesCount Attendees',
                                  style: const TextStyle(fontSize: 11, color: Colors.grey),
                                ),
                              ],
                            ),
                            TextButton(
                              style: TextButton.styleFrom(
                                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                                minimumSize: const Size(60, 30),
                                backgroundColor: Colors.blue,
                                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                              ),
                              onPressed: () {
                                widget.onEventTap(
                                  event['id'].toString(),
                                  eventName: event['eventName'] ?? event['name'] ?? "",
                                );
                              },
                              child: Text(
                                actionLabel,
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: Colors.white,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
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
    );
  }

  void _hidePopup() {
    _showTimer?.cancel();
    _overlayEntry?.remove();
    _overlayEntry = null;
  }

  @override
  void dispose() {
    _hideTimer?.cancel();
    _showTimer?.cancel();
    _hidePopup();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    const containerHeight = 700.0;

    return Container(
      color: Colors.white,
      child: Center(
        child: Container(
          width: screenWidth * 0.90,
          height: containerHeight,
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                flex: 3,
                child: TableCalendar(
                  focusedDay: _focusedDay,
                  firstDay: DateTime.utc(2020, 1, 1),
                  lastDay: DateTime.utc(2030, 12, 31),
                  calendarFormat: CalendarFormat.month,
                  availableGestures: AvailableGestures.all,
                  headerStyle: const HeaderStyle(
                    formatButtonVisible: false,
                    titleCentered: true,
                  ),
                  daysOfWeekHeight: 30,
                  rowHeight: 85,
                  calendarStyle: CalendarStyle(
                    outsideDaysVisible: false,
                    defaultDecoration: BoxDecoration(
                      color: Colors.white,
                      border: Border.all(color: Colors.grey, width: 0.5),
                      borderRadius: BorderRadius.zero,
                    ),
                    weekendDecoration: BoxDecoration(
                      color: Colors.white,
                      border: Border.all(color: Colors.grey, width: 0.5),
                      borderRadius: BorderRadius.zero,
                    ),
                    todayDecoration: const BoxDecoration(),
                    todayTextStyle: const TextStyle(
                      color: Colors.black,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  calendarBuilders: CalendarBuilders(
                    todayBuilder: (context, day, focusedDay) {
                      final events = _getEventsForDay(DateTime.utc(day.year, day.month, day.day));
                      const double visibleStripArea = 55.0;
                      final int eventCount = events.length;
                      final double stripHeight =
                      eventCount > 0 ? (visibleStripArea / eventCount) - 2 : visibleStripArea;

                      return _DayCell(
                        borderColor: Colors.grey.shade300,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Padding(
                              padding: const EdgeInsets.only(left: 4, top: 2),
                              child: Container(
                                width: 24,
                                height: 24,
                                alignment: Alignment.center,
                                decoration: const BoxDecoration(
                                  color: Color(0xFF0B3D91),
                                  shape: BoxShape.circle,
                                ),
                                child: Text(
                                  '${day.day}',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 12,
                                  ),
                                ),
                              ),
                            ),
                            Expanded(
                              child: events.isNotEmpty
                                  ? Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: events.asMap().entries.map<Widget>((entry) {
                                  final event = entry.value;
                                  final isStartDay =
                                  DateTime.utc(day.year, day.month, day.day).isAtSameMomentAs(
                                    DateTime.utc(
                                      (event['start'] as DateTime).year,
                                      (event['start'] as DateTime).month,
                                      (event['start'] as DateTime).day,
                                    ),
                                  );

                                  return _EventStrip(
                                    event: event,
                                    color: _parseEventColor(event['color'], event['id'].toString()),
                                    label: event['eventName'] ?? event['name'] ?? "",
                                    isStartDay: isStartDay,
                                    height: stripHeight,
                                    onEnter: (enterEvent, ctx) {
                                      _isHoveringStrip = true;
                                      _hideTimer?.cancel();

                                      final renderBox = ctx.findRenderObject() as RenderBox;
                                      final offset = renderBox.localToGlobal(Offset.zero);
                                      final rect = Rect.fromLTWH(
                                        offset.dx,
                                        offset.dy,
                                        renderBox.size.width,
                                        renderBox.size.height,
                                      );

                                      if (_overlayEntry != null &&
                                          _lastTargetRect != null &&
                                          rect != _lastTargetRect) {
                                        _showPopupAt(rect, event);
                                      } else {
                                        _scheduleShow(rect, event);
                                      }
                                    },
                                    onExit: (_) {
                                      _isHoveringStrip = false;
                                      _scheduleHide();
                                    },
                                  );
                                }).toList(),
                              )
                                  : const SizedBox.shrink(),
                            ),
                          ],
                        ),
                      );
                    },
                    defaultBuilder: (context, day, focusedDay) {
                      final events = _getEventsForDay(DateTime.utc(day.year, day.month, day.day));
                      const double visibleStripArea = 55.0;
                      final int eventCount = events.length;
                      final double stripHeight =
                      eventCount > 0 ? (visibleStripArea / eventCount) - 2 : visibleStripArea;

                      return _DayCell(
                        borderColor: Colors.grey.shade300,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Padding(
                              padding: const EdgeInsets.only(left: 4, top: 2),
                              child: Text(
                                '${day.day}',
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: Colors.black,
                                ),
                              ),
                            ),
                            Expanded(
                              child: events.isNotEmpty
                                  ? Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: events.asMap().entries.map<Widget>((entry) {
                                  final event = entry.value;
                                  final isStartDay =
                                  DateTime.utc(day.year, day.month, day.day).isAtSameMomentAs(
                                    DateTime.utc(
                                      (event['start'] as DateTime).year,
                                      (event['start'] as DateTime).month,
                                      (event['start'] as DateTime).day,
                                    ),
                                  );
                                  return _EventStrip(
                                    event: event,
                                    color: _parseEventColor(event['color'], event['id'].toString()),
                                    label: event['eventName'] ?? event['name'] ?? "",
                                    isStartDay: isStartDay,
                                    height: stripHeight,
                                    onEnter: (enterEvent, ctx) {
                                      _isHoveringStrip = true;
                                      _hideTimer?.cancel();

                                      final renderBox = ctx.findRenderObject() as RenderBox;
                                      final offset = renderBox.localToGlobal(Offset.zero);
                                      final rect = Rect.fromLTWH(
                                        offset.dx,
                                        offset.dy,
                                        renderBox.size.width,
                                        renderBox.size.height,
                                      );

                                      if (_overlayEntry != null &&
                                          _lastTargetRect != null &&
                                          rect != _lastTargetRect) {
                                        _showPopupAt(rect, event);
                                      } else {
                                        _scheduleShow(rect, event);
                                      }
                                    },
                                    onExit: (_) {
                                      _isHoveringStrip = false;
                                      _scheduleHide();
                                    },
                                  );
                                }).toList(),
                              )
                                  : const SizedBox.shrink(),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
              ),
              const SizedBox(width: 24),
              SizedBox(
                width: screenWidth * 0.25,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Align(
                      alignment: Alignment.centerLeft,
                      child: widget.userRole == "Student" || widget.userRole == "Guardian"
                          ? const SizedBox()
                          : ElevatedButton.icon(
                        icon: const Icon(Icons.add, size: 18),
                        label: const Text(
                          "Add New Event",
                          style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                        ),
                        onPressed: widget.onEventCreated,
                        style: ElevatedButton.styleFrom(
                          elevation: 0,
                          backgroundColor: const Color.fromARGB(255, 12, 122, 211),
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(9)),
                          padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 7),
                          textStyle: const TextStyle(fontSize: 14),
                        ),
                      ),
                    ),
                    const SizedBox(height: 14),
                    const Text(
                      'Recently Added Events',
                      style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
                    ),
                    const SizedBox(height: 8),
                    Expanded(
                      child: ListView.builder(
                        itemCount: _recentEvents.length,
                        itemBuilder: (context, index) {
                          final event = _recentEvents[index];
                          return InkWell(
                            child: Container(
                              margin: const EdgeInsets.only(bottom: 8),
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                border: Border.all(color: Colors.grey.shade300),
                                borderRadius: BorderRadius.circular(12),
                                color: (event['color'] as Color).withOpacity(0.1),
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Flexible(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          event['name'],
                                          style: TextStyle(
                                            fontWeight: FontWeight.bold,
                                            color: (event['color'] as Color),
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(event['location']),
                                      ],
                                    ),
                                  ),
                                  Text(event['time']),
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
            ],
          ),
        ),
      ),
    );
  }
}

class _DayCell extends StatelessWidget {
  final Widget child;
  final Color borderColor;

  const _DayCell({
    required this.child,
    required this.borderColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: borderColor, width: 0.5),
        borderRadius: BorderRadius.zero,
      ),
      child: SizedBox.expand(child: child),
    );
  }
}

class _EventStrip extends StatelessWidget {
  final Map<String, dynamic> event;
  final Color color;
  final String label;
  final bool isStartDay;
  final void Function(PointerEnterEvent, BuildContext) onEnter;
  final void Function(PointerExitEvent) onExit;
  final double height;

  const _EventStrip({
    required this.event,
    required this.color,
    required this.label,
    required this.isStartDay,
    required this.onEnter,
    required this.onExit,
    required this.height,
  });

  @override
  Widget build(BuildContext context) {
    return Listener(
      onPointerDown: (_) {},
      child: Builder(
        builder: (ctx) {
          return MouseRegion(
            opaque: false,
            onEnter: (e) => onEnter(e, ctx),
            onExit: onExit,
            child: Padding(
              padding: const EdgeInsets.only(bottom: 2),
              child: Container(
                height: height,
                width: double.infinity,
                decoration: BoxDecoration(
                  color: color.withOpacity(0.5),
                  borderRadius: BorderRadius.circular(3),
                ),
                child: Row(
                  children: [
                    if (isStartDay)
                      Container(
                        width: 4,
                        height: double.infinity,
                        decoration: BoxDecoration(
                          color: color,
                          borderRadius: const BorderRadius.only(
                            topLeft: Radius.circular(3),
                            bottomLeft: Radius.circular(3),
                          ),
                        ),
                      ),
                    if (isStartDay) const SizedBox(width: 3),
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 2),
                        child: Text(
                          label,
                          style: const TextStyle(
                            fontSize: 8,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
