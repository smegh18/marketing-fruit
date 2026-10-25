import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:table_calendar/table_calendar.dart';

class StreakCalendar extends StatefulWidget {
  final String userId;
  final double width;
  final bool disabled;

  const StreakCalendar({
    super.key,
    required this.userId,
    required this.width,
    this.disabled = false,
  });

  @override
  State<StreakCalendar> createState() => _StreakCalendarState();
}

class _StreakCalendarState extends State<StreakCalendar> {
  final Set<DateTime> _streakSet = <DateTime>{};

  DateTime _focusedDay = DateTime.now();
  final DateTime _firstDay = DateTime.utc(2022, 1, 1);
  final DateTime _lastDay = DateTime.utc(2030, 12, 31);
  PageController? _pageController;

  // Card chrome
  static const double _padH = 20;
  static const double _padV = 20;
  static const double _topBarHeight = 36;
  static const double _topBarGap = 10;

  // Ratio: days-of-week row vs a date row.
  // With k=0.6, DoW row is 60% of a normal row. Change if you want.
  static const double _dowToRowRatio = 0.6;

  static DateTime _d(DateTime dt) => DateTime(dt.year, dt.month, dt.day);

  @override
  void initState() {
    super.initState();
    _loadStreakDates();
  }

  Future<void> _loadStreakDates() async {
    final dbRef = FirebaseDatabase.instance.ref('streaks/${widget.userId}');
    final snapshot = await dbRef.get();
    if (!snapshot.exists) return;

    final raw = Map<String, dynamic>.from(snapshot.value as Map);
    final dates = <DateTime>[];
    for (final key in raw.keys) {
      final parsed = DateTime.tryParse(key);
      if (parsed != null) dates.add(_d(parsed));
    }
    dates.sort();

    setState(() {
      _streakSet
        ..clear()
        ..addAll(dates.map(_d));
    });
  }

  void _goToPrevMonth() {
    _pageController?.previousPage(
      duration: const Duration(milliseconds: 220),
      curve: Curves.easeOut,
    );
  }

  void _goToNextMonth() {
    _pageController?.nextPage(
      duration: const Duration(milliseconds: 220),
      curve: Curves.easeOut,
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return IgnorePointer(
      ignoring: widget.disabled,
      child: Opacity(
        opacity: widget.disabled ? 0.85 : 1,
        child: LayoutBuilder(
          builder: (context, constraints) {
            // Outer card takes the height it needs from our computed internals.
            // We let the parent give us any height; we then PARTITION that height
            // so the calendar fills exactly with no gap below.
            // If parent gives infinite height, fall back to a nice default.
            final maxH = constraints.hasBoundedHeight
                ? constraints.maxHeight
                : (_topBarHeight + _topBarGap + 320 + _padV * 2);

            // Available height left for calendar (below the top bar).
            final availableCalendarH =
                (maxH - _padV * 2 - _topBarHeight - _topBarGap).clamp(240.0, 1000.0);

            // Solve for rowHeight using: available = dowH + 6*rowH, where dowH = k*rowH.
            // => rowH = available / (6 + k)
            final rowHeight = availableCalendarH / (6.0 + _dowToRowRatio);
            final dowHeight = rowHeight * _dowToRowRatio;

            // For aesthetics, clamp logical font sizes to row height.
            final dayFontSize = (rowHeight * 0.38).clamp(12.0, 18.0).toDouble();
            final dowFontSize = (rowHeight * 0.32).clamp(11.0, 16.0).toDouble();

            // Streak chip vertical padding scales with row height.
            final streakVPad = (rowHeight * 0.25).clamp(8.0, 18.0);
            final streakChipH = (rowHeight * 0.58);

            return Container(
              width: widget.width,
              height: maxH, // match parent’s given height; internals will fill it exactly
              padding: const EdgeInsets.symmetric(horizontal: _padH, vertical: _padV),
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
              child: Column(
                children: [
                  // Top bar with label + month navigator
                  SizedBox(
                    height: _topBarHeight,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Streaks',
                          style: GoogleFonts.poppins(
                            color: theme.hintColor,
                            fontSize: 22,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        Row(
                          children: [
                            IconButton(
                              tooltip: 'Previous month',
                              splashRadius: 15,
                              onPressed: _goToPrevMonth,
                              icon: const Icon(Icons.chevron_left),
                            ),
                            Text(
                              '${_focusedDay.month.toString().padLeft(2, '0')} / ${_focusedDay.year}',
                              style: TextStyle(
                                color: theme.hintColor,
                                fontSize: 22,
                                fontWeight: FontWeight.w100,
                              ),
                            ),
                            IconButton(
                              tooltip: 'Next month',
                              splashRadius: 15,
                              onPressed: _goToNextMonth,
                              icon: const Icon(Icons.chevron_right),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: _topBarGap),

                  // The calendar fills EXACT available height:
                  SizedBox(
                    height: availableCalendarH,
                    child: TableCalendar(
                      firstDay: _firstDay,
                      lastDay: _lastDay,
                      focusedDay: _focusedDay,
                      headerVisible: false,
                      pageAnimationEnabled: true,
                      pageJumpingEnabled: true,
                      onCalendarCreated: (c) => _pageController = c,
                      onPageChanged: (d) => setState(() => _focusedDay = d),

                      // These two are *derived* from available height:
                      rowHeight: rowHeight,
                      daysOfWeekHeight: dowHeight,

                      calendarStyle: CalendarStyle(
                        outsideDaysVisible: false,
                        defaultTextStyle: TextStyle(
                          color: theme.hintColor,
                          fontSize: dayFontSize,
                          fontWeight: FontWeight.w500,
                        ),
                        weekendTextStyle: TextStyle(
                          color: theme.hintColor,
                          fontSize: dayFontSize,
                          fontWeight: FontWeight.w500,
                        ),
                        todayDecoration: const BoxDecoration(
                          color: Colors.blue,
                          shape: BoxShape.circle,
                        ),
                      ),
                      daysOfWeekStyle: DaysOfWeekStyle(
                        weekdayStyle: TextStyle(
                          color: theme.hintColor,
                          fontSize: dowFontSize,
                          fontWeight: FontWeight.w600,
                        ),
                        weekendStyle: TextStyle(
                          color: theme.hintColor,
                          fontSize: dowFontSize,
                          fontWeight: FontWeight.w600,
                        ),
                      ),

                      calendarBuilders: CalendarBuilders(
                        defaultBuilder: (context, date, _) {
                          final day = _d(date);
                          final isStreak = _streakSet.contains(day);
                          if (!isStreak) return null;

                          final hasPrev = _streakSet.contains(_d(day.subtract(const Duration(days: 1))));
                          final hasNext = _streakSet.contains(_d(day.add(const Duration(days: 1))));

                          BorderRadius radius;
                          if (hasPrev && hasNext) {
                            radius = BorderRadius.zero;
                          } else if (hasPrev) {
                            radius =
                                const BorderRadius.horizontal(right: Radius.circular(50));
                          } else if (hasNext) {
                            radius =
                                const BorderRadius.horizontal(left: Radius.circular(50));
                          } else {
                            radius = BorderRadius.circular(50);
                          }

                          return Padding(
                            padding: EdgeInsets.symmetric(vertical: streakVPad),
                            child: Container(
                              height: streakChipH,
                              decoration: BoxDecoration(
                                color: const Color(0xFFFFD54F),
                                borderRadius: radius,
                              ),
                              alignment: Alignment.center,
                              child: Text(
                                '${day.day}',
                                style: TextStyle(
                                  color: Colors.black,
                                  fontWeight: FontWeight.w700,
                                  fontSize: dayFontSize,
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}
