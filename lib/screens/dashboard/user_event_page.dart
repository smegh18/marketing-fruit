import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';

import '../../components/event_overview_section.dart';
import 'event_frontend_section.dart';
import 'package:Marketing_Fruit/components/event_attendees_count.dart'; // AttendiesCountSection

class UserEventDashboardPage extends StatefulWidget {
  final String eventId;
  final String userRole;
  final bool jk;
  final void Function(Map<String, dynamic> nftData)? onNFTCardTap;
  const UserEventDashboardPage({super.key, required this.eventId, required this.userRole, this.onNFTCardTap,this.jk = false});

  @override
  State<UserEventDashboardPage> createState() => _UserEventDashboardPageState();
}

class _UserEventDashboardPageState extends State<UserEventDashboardPage> {
  Map<String, dynamic>? eventData;
  bool loading = true;
  String error = '';

  bool _attendFlowActive = false;
  int _tabIndex = 0; // 0 = Overview, 1 = Attendees

  @override
  void initState() {
    super.initState();
    _fetchEvent();
    print(widget.jk);
  }

  Future<void> _fetchEvent() async {
    setState(() {
      loading = true;
      error = '';
    });

    try {
      final ref = FirebaseDatabase.instance.ref('events/${widget.eventId}');
      final snapshot = await ref.get();
      if (snapshot.exists) {
        setState(() {
          eventData = Map<String, dynamic>.from(snapshot.value as Map);
          loading = false;
        });
      } else {
        setState(() {
          error = "Event not found.";
          loading = false;
        });
      }
    } catch (e) {
      setState(() {
        error = e.toString();
        loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenW = MediaQuery.of(context).size.width;
    final contentW = screenW * 0.95; // match top card width

    final mainContent = Row(
      children: [
        Expanded(
          child: Column(
            children: [
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.only(bottom: 24),
                  child: loading
                      ? const Center(
                    child: Padding(
                      padding: EdgeInsets.all(64.0),
                      child: CircularProgressIndicator(),
                    ),
                  )
                      : error.isNotEmpty
                      ? Padding(
                    padding: const EdgeInsets.all(32.0),
                    child: Center(child: Text(error)),
                  )
                      : Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Top section
                      EventFrontendSection(
                        eventId: widget.eventId,
                        userRole: widget.userRole,
                        eventData: eventData ?? {},
                        jk: widget.jk,
                        onAttendFlowActive: (active) {
                          setState(() => _attendFlowActive = active);
                        },
                      ),
                      const SizedBox(height: 16),

                      if (!_attendFlowActive) ...[
                        // Safari-like tab bar (only for admin)
                        if (widget.userRole == 'admin') ...[
                          Center(
                            child: Container(
                              width: contentW,
                              margin: const EdgeInsets.only(right: 8),
                              child: _SafariTabsBar(
                                index: _tabIndex,
                                onChanged: (i) => setState(() => _tabIndex = i),
                                items: const [
                                  _SafariTabItem(
                                    icon: Icons.description_outlined,
                                    label: 'Event Overview',
                                  ),
                                  _SafariTabItem(
                                    icon: Icons.people_outline,
                                    label: 'Attendees Count',
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                        const SizedBox(height: 12),

                        // Selected tab content
                        Center(
                          child: Container(
                            width: contentW,
                            margin: const EdgeInsets.only(right: 8),
                            child: _tabIndex == 0
                                ? EventOverviewSection(eventData: eventData ?? {},onNFTCardTap: widget.onNFTCardTap,)
                                : AttendiesCountSection(eventId: widget.eventId),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: kIsWeb ? mainContent : SafeArea(child: mainContent),
    );
  }
}

/// Data class for a Safari-style tab
class _SafariTabItem {
  final IconData icon;
  final String label;
  const _SafariTabItem({required this.icon, required this.label});
}

/// Safari-like tab bar:
/// - rounded capsules
/// - selected tab floats (white + subtle shadow)
/// - unselected tabs are light gray, flat
/// - smooth hover/press highlight
class _SafariTabsBar extends StatelessWidget {
  final int index;
  final ValueChanged<int> onChanged;
  final List<_SafariTabItem> items;

  const _SafariTabsBar({
    required this.index,
    required this.onChanged,
    required this.items,
  });

  @override
  Widget build(BuildContext context) {
    final bg = const Color(0xFFF7F7F9); // toolbar-ish
    final radius = BorderRadius.circular(12);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE5E6EA)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x11000000),
            blurRadius: 10,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          for (int i = 0; i < items.length; i++) ...[
            Expanded(
              child: _SafariTabButton(
                selected: i == index,
                item: items[i],
                onTap: () => onChanged(i),
                radius: radius,
              ),
            ),
            if (i != items.length - 1) const SizedBox(width: 8),
          ],
        ],
      ),
    );
  }
}

class _SafariTabButton extends StatefulWidget {
  final bool selected;
  final _SafariTabItem item;
  final VoidCallback onTap;
  final BorderRadius radius;

  const _SafariTabButton({
    required this.selected,
    required this.item,
    required this.onTap,
    required this.radius,
  });

  @override
  State<_SafariTabButton> createState() => _SafariTabButtonState();
}

class _SafariTabButtonState extends State<_SafariTabButton> {
  bool _hover = false;
  bool _down = false;

  @override
  Widget build(BuildContext context) {
    final sel = widget.selected;

    final baseFill =
        sel ? Colors.white : (_hover ? const Color(0xFFF0F1F4) : const Color(0xFFF6F7F9));
    final baseBorder = sel ? const Color(0xFFDADCE2) : const Color(0xFFE6E7EB);

    return MouseRegion(
      cursor: SystemMouseCursors.click, // 👈 show hand cursor on hover (web/desktop)
      onEnter: (_) => setState(() => _hover = true),
      onExit: (_) => setState(() {
        _hover = false;
        _down = false;
      }),
      child: GestureDetector(
        onTapDown: (_) => setState(() => _down = true),
        onTapCancel: () => setState(() => _down = false),
        onTapUp: (_) => setState(() => _down = false),
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 140),
          curve: Curves.easeOut,
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            color: baseFill.withOpacity(_down ? 0.95 : 1),
            borderRadius: widget.radius,
            border: Border.all(color: baseBorder),
            boxShadow: sel
                ? const [
                    BoxShadow(
                      color: Color(0x14000000),
                      blurRadius: 10,
                      offset: Offset(0, 3),
                    ),
                  ]
                : null,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                widget.item.icon,
                size: 16,
                color: sel ? Colors.black87 : Colors.black54,
              ),
              const SizedBox(width: 8),
              Flexible(
                child: Text(
                  widget.item.label,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 13.5,
                    fontWeight: FontWeight.w600,
                    color: sel ? Colors.black87 : Colors.black87,
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
