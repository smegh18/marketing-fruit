import 'dart:async';
import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';

typedef StatCardTapCallback = void Function(String filterRole);

class StatsOverviewSection extends StatefulWidget {
  final StatCardTapCallback? onStatCardTap;
  final String userRole;
  const StatsOverviewSection({super.key, this.onStatCardTap, required this.userRole});

  @override
  State<StatsOverviewSection> createState() => _StatsOverviewSectionState();
}

class _StatsOverviewSectionState extends State<StatsOverviewSection> {
  int _students = 0, _schools = 0, _brands = 0, _guardians = 0, _merchandise = 0, _nft = 0, _books = 0, _upcomingEvents = 0;
  bool _loading = true;

  final _usersRef = FirebaseDatabase.instance.ref('users');
  final _eventsRef = FirebaseDatabase.instance.ref('events');
  final _nftRef = FirebaseDatabase.instance.ref('nft');
  final _booksRef = FirebaseDatabase.instance.ref('books');
  final _merchRef = FirebaseDatabase.instance.ref('merchandise');

  StreamSubscription<DatabaseEvent>? _usersSub, _eventsSub, _nftSub, _booksSub, _merchSub;

  @override
  void initState() {
    super.initState();
    _listenAll();
  }

  @override
  void dispose() {
    _usersSub?.cancel();
    _eventsSub?.cancel();
    _nftSub?.cancel();
    _booksSub?.cancel();
    _merchSub?.cancel();
    super.dispose();
  }

  void _listenAll() {
    _usersSub = _usersRef.onValue.listen((event) {
      int s = 0, sc = 0, b = 0, g = 0;
      for (final user in event.snapshot.children) {
        final role = (user.child('role').value ?? '').toString();
        switch (role) {
          case 'Student': s++; break;
          case 'School': sc++; break;
          case 'Brand': b++; break;
          case 'Guardian': g++; break;
        }
      }
      setState(() {
        _students = s;
        _schools = sc;
        _brands = b;
        _guardians = g;
        _loading = false;
      });
    });
    _eventsSub = _eventsRef.onValue.listen((event) {
      final nowMs = DateTime.now().millisecondsSinceEpoch;
      int upcoming = 0;
      for (final e in event.snapshot.children) {
        final raw = e.child('start').value;
        int? startMs;
        if (raw is int) {
          startMs = raw;
        } else if (raw is String) startMs = int.tryParse(raw);
        if (startMs != null && startMs >= nowMs) upcoming++;
      }
      setState(() => _upcomingEvents = upcoming);
    });
    _nftSub = _nftRef.onValue.listen((event) => setState(() => _nft = event.snapshot.children.length));
    _booksSub = _booksRef.onValue.listen((event) => setState(() => _books = event.snapshot.exists ? event.snapshot.children.length : 0));
    _merchSub = _merchRef.onValue.listen((event) => setState(() => _merchandise = event.snapshot.exists ? event.snapshot.children.length : 0));
  }

  @override
  Widget build(BuildContext context) {
    final cards = widget.userRole == 'admin' ? <_StatCardData>[
      _StatCardData('Users (Student)', _students, Icons.school, const Color(0xffe8e4ff), const Color(0xff6f3ff2), role: 'Student', clickable: true),
      _StatCardData('School', _schools, Icons.location_city, const Color(0xfffff2d6), const Color(0xfff5b000), role: 'School', clickable: true),
      _StatCardData('Brand', _brands, Icons.storefront, const Color(0xffdff9ec), const Color(0xff2ecc71), role: 'Brand', clickable: true),
      _StatCardData('Guardian', _guardians, Icons.group, const Color(0xffffebe6), const Color(0xffe74c3c), role: 'Guardian', clickable: true),
      _StatCardData('Merchandise', _merchandise, Icons.shopping_bag, const Color(0xffe0f7fa), const Color(0xff00acc1)),
      _StatCardData('NFT', _nft, Icons.image, const Color(0xffffe0f7), const Color(0xffd81b60)),
      _StatCardData('Books', _books, Icons.menu_book, const Color(0xfff3e5f5), const Color(0xff8e24aa)),
      _StatCardData('Upcoming Events', _upcomingEvents, Icons.event, const Color(0xffe8f5e9), const Color(0xff43a047)),
    ] : <_StatCardData>[
      _StatCardData('Users (Student)', _students, Icons.school, const Color(0xffe8e4ff), const Color(0xff6f3ff2), role: 'Student', clickable: true),
      _StatCardData('School', _schools, Icons.location_city, const Color(0xfffff2d6), const Color(0xfff5b000), role: 'School', clickable: true),
      // _StatCardData('Brand', _brands, Icons.storefront, const Color(0xffdff9ec), const Color(0xff2ecc71), role: 'Brand', clickable: true),
      _StatCardData('Guardian', _guardians, Icons.group, const Color(0xffffebe6), const Color(0xffe74c3c), role: 'Guardian', clickable: true),
      _StatCardData('Merchandise', _merchandise, Icons.shopping_bag, const Color(0xffe0f7fa), const Color(0xff00acc1)),
      _StatCardData('NFT', _nft, Icons.image, const Color(0xffffe0f7), const Color(0xffd81b60)),
      _StatCardData('Books', _books, Icons.menu_book, const Color(0xfff3e5f5), const Color(0xff8e24aa)),
      _StatCardData('Upcoming Events', _upcomingEvents, Icons.event, const Color(0xffe8f5e9), const Color(0xff43a047)),
    ];

    return Padding(
      padding: const EdgeInsets.all(20),
      child: LayoutBuilder(builder: (context, constraints) {
        final width = constraints.maxWidth;
        final int cols = width >= 1400 ? 4 : width >= 1050 ? 3 : width >= 680 ? 2 : 1;
        const spacing = 20.0;
        final double cardWidth = (width - spacing * (cols - 1)) / cols;
        const desiredHeight = 170.0;
        final aspect = cardWidth / desiredHeight;

        if (_loading) {
          return GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: 8,
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: cols,
              crossAxisSpacing: spacing,
              mainAxisSpacing: spacing,
              childAspectRatio: aspect,
            ),
            itemBuilder: (_, __) => const _SkeletonCard(),
          );
        }

        return GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: cards.length,
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: cols,
            crossAxisSpacing: spacing,
            mainAxisSpacing: spacing,
            childAspectRatio: aspect,
          ),
          itemBuilder: (context, i) {
            final card = cards[i];
            if (card.clickable && widget.onStatCardTap != null) {
              return _StatCard(
                data: card,
                onTap: () => widget.onStatCardTap?.call(card.role ?? ''),
              );
            } else {
              return _StatCard(data: card);
            }
          },
        );
      }),
    );
  }
}

class _StatCardData {
  final String title;
  final int value;
  final IconData icon;
  final Color iconBg;
  final Color iconColor;
  final String? role;
  final bool clickable;
  const _StatCardData(this.title, this.value, this.icon, this.iconBg, this.iconColor,
      {this.role, this.clickable = false});
}

class _StatCard extends StatefulWidget {
  final _StatCardData data;
  final VoidCallback? onTap;
  const _StatCard({required this.data, this.onTap});
  @override
  State<_StatCard> createState() => _StatCardState();
}

class _StatCardState extends State<_StatCard> {
  bool _hover = false;
  @override
  Widget build(BuildContext context) {
    final textScale = MediaQuery.of(context).textScaleFactor;
    Widget child = AnimatedContainer(
      duration: const Duration(milliseconds: 180),
      curve: Curves.easeInOut,
      padding: EdgeInsets.all(16 * textScale),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16 * textScale),
        boxShadow: [
          BoxShadow(
            blurRadius: _hover ? 20 : 10,
            offset: const Offset(0, 6),
            color: _hover ? Colors.grey.withOpacity(0.28)
                : Colors.black.withOpacity(0.06),
          ),
        ],
        border: widget.data.clickable && _hover
            ? Border.all(color: widget.data.iconColor, width: 2.5)
            : null,
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Flexible(
                child: Text(
                  widget.data.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 18 * textScale,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey.shade800,
                  ),
                ),
              ),
              Container(
                decoration: BoxDecoration(
                  color: widget.data.iconBg,
                  shape: BoxShape.circle,
                ),
                padding: EdgeInsets.all(18 * textScale),
                child: Icon(
                  widget.data.icon,
                  color: widget.data.iconColor,
                  size: 40 * textScale,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            widget.data.value.toString(),
            style: TextStyle(
              fontSize: 26 * textScale,
              fontWeight: FontWeight.bold,
              color: Colors.black,
            ),
          ),
        ],
      ),
    );
    if (widget.data.clickable) {
      child = MouseRegion(
        onEnter: (_) => setState(() => _hover = true),
        onExit: (_) => setState(() => _hover = false),
        cursor: SystemMouseCursors.click,
        child: GestureDetector(
          onTap: widget.onTap,
          child: child,
        ),
      );
    } else {
      child = MouseRegion(
        onEnter: (_) => setState(() => _hover = true),
        onExit: (_) => setState(() => _hover = false),
        child: child,
      );
    }
    return child;
  }
}

class _SkeletonCard extends StatelessWidget {
  const _SkeletonCard();
  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            blurRadius: 10,
            offset: const Offset(0, 6),
            color: Colors.black.withOpacity(0.06),
          ),
        ],
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: Container(
                  height: 18,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade200,
                    borderRadius: BorderRadius.circular(6),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              const CircleAvatar(radius: 24, backgroundColor: Color(0xFFEFEFEF)),
            ],
          ),
          const Spacer(),
          Container(
            height: 24,
            decoration: BoxDecoration(
              color: Colors.grey.shade200,
              borderRadius: BorderRadius.circular(6),
            ),
          ),
        ],
      ),
    );
  }
}
