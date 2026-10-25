import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../components/player_details.dart';

class TopNavigationBar extends StatefulWidget {
  final String title;
  final double height;

  const TopNavigationBar({
    super.key,
    required this.title,
    required this.height,
  });

  @override
  State<TopNavigationBar> createState() => _TopNavigationBarState();
}

class _TopNavigationBarState extends State<TopNavigationBar>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _rotationAnimation;
  String? user;

  static const double kExpandedHeight = 100;
  static const double kCollapsedHeight = 58;

  @override
  void initState() {
    super.initState();
    _loadUserName();

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    )..repeat(reverse: true);

    _rotationAnimation = Tween<double>(begin: -0.2, end: 0.2).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  Future<void> _loadUserName() async {
    final name = await PlayerDetails().fetchUserName();
    setState(() {
      user = name;
    });
  }

  bool get showSubHeader => widget.height > kCollapsedHeight + 5;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return AnimatedContainer(
      duration: const Duration(milliseconds: 150),
      height: widget.height,
      curve: Curves.easeOut,
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: const BorderRadius.all(Radius.circular(20)),
        boxShadow: [
          if (widget.height < kExpandedHeight)
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 8,
              offset: const Offset(0, 3),
            ),
        ],
      ),
      padding: const EdgeInsets.symmetric(horizontal: 32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Flexible(
                child: Text(
                  'Hello ${user ?? ""},',
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.workSans(
                    fontWeight: FontWeight.w600,
                    fontSize: widget.height <= kCollapsedHeight + 5 ? 24 : 28,
                    color: theme.hintColor,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              AnimatedBuilder(
                animation: _rotationAnimation,
                builder: (context, child) {
                  return Transform.rotate(
                    angle: _rotationAnimation.value,
                    child: Text(
                      '👋',
                      style: TextStyle(fontSize: widget.height <= kCollapsedHeight + 5 ? 24 : 28,),
                    ),
                  );
                },
              ),
            ],
          ),
          AnimatedOpacity(
            opacity: showSubHeader ? 1 : 0,
            duration: const Duration(milliseconds: 150),
            child: Padding(
              padding: const EdgeInsets.only(left: 12.0, top: 4.0),
              child: Text(
                showSubHeader ? "Let's Explore ${widget.title}" : "",
                textAlign: TextAlign.left,
                style: GoogleFonts.workSans(
                  fontWeight: FontWeight.w600,
                  fontSize: 22,
                  color: theme.hintColor,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
