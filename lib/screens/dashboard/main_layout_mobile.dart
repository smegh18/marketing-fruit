import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:Marketing_Fruit/components/marketplace_choice_section.dart';
import 'package:Marketing_Fruit/components/more_section.dart';
import 'package:Marketing_Fruit/course/course_detail_screen.dart';
import 'package:Marketing_Fruit/course/curriculum_screen.dart';
import 'package:Marketing_Fruit/screens/dashboard/dashboard_screen_mobile.dart';
import 'package:Marketing_Fruit/course/course_screen.dart';
import '../../components/player_details.dart';
import '../../course/models.dart';
import '../../login_screen.dart';

class MainLayoutMobile extends StatefulWidget {
  final String userRole;

  const MainLayoutMobile({
    super.key,
    required this.userRole,
  });

  @override
  State<MainLayoutMobile> createState() => _MainLayoutMobileState();
}

class _MobileNavItem {
  final IconData icon;
  final String label;
  final Widget Function(Function onNFTtap) pageBuilder;
  final bool isMarketplace;

  const _MobileNavItem({
    required this.icon,
    required this.label,
    required this.pageBuilder,
    this.isMarketplace = false,
  });
}

enum NavTab { Home, Study, Play, Marketplace, More }

class _MainLayoutMobileState extends State<MainLayoutMobile> {
  int _selectedIndex = 0;
  int _tabUniqueKey = 0;
  bool _marketplaceNFTMode = false;
  bool courseTap = false;
  bool lessonTap = false;
  bool students = false;
  int courseId = 1;
  List<SectionItem> litems = [];
  int lessonId = 1;
  String user = '';
  String selectedRole = 'All';

  late final List<_MobileNavItem> _navItemsStudent;
  late final List<_MobileNavItem> _navItems;

  @override
  void initState() {
    super.initState();
    // Always restore portrait when entering the mobile dashboard
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
    ]);
    _loadUserName();
    _navItemsStudent = [
      _MobileNavItem(
        icon: Icons.home,
        label: 'Home',
        pageBuilder: (_) => DashboardScreenMobile(userRole: widget.userRole),
      ),
      _MobileNavItem(
        icon: Icons.school,
        label: 'Study',
        pageBuilder: (_) => courseTap
            ? (lessonTap
            ? CurriculumInteractiveScreen(
            curriculum: litems, courseId: lessonId)
            : CourseDetailScreen(
            courseId: courseId, onLessonTap: _onLessonTap))
            : CoursesScreen(onCourseTap: _onCourseTap),
      ),
      _MobileNavItem(
        icon: Icons.play_circle_fill,
        label: 'Play',
        pageBuilder: (_) => const Center(
          child: Text('Play',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
        ),
      ),
      _MobileNavItem(
        icon: Icons.store,
        label: 'Marketplace',
        pageBuilder: (dynamic onNFTtap) =>
            MarketplaceChoiceSection(onNFTtap: onNFTtap),
        isMarketplace: true,
      ),
      _MobileNavItem(
        icon: Icons.more_horiz,
        label: 'More',
        pageBuilder: (_) => MoreSection(userId: user, userRole: widget.userRole),
      ),
    ];
    _navItems = _navItemsStudent;
  }

  void _onCourseTap(Course course) {
    courseId = course.id;
    if (!mounted) return;
    setState(() {
      courseTap = true;
    });
  }

  void _onLessonTap(List<SectionItem> items, int id,[int index = 0]) {
    litems = items;
    lessonId = id;
    if (!mounted) return;
    setState(() {
      lessonTap = true;
    });
  }

  void _onMarketplaceNFTtap() {
    if (!mounted) return;
    setState(() {
      _marketplaceNFTMode = true;
    });
  }

  void _onNavTap(NavTab tab) {
    if (!mounted) return;
    setState(() {
      if (_selectedIndex == tab.index) _tabUniqueKey++;
      _selectedIndex = tab.index;
      if (_selectedIndex == 0) {
        students = false;
        courseTap = false;
        lessonTap = false;
      }
      if (!_navItems[_selectedIndex].isMarketplace || !_marketplaceNFTMode) {
        _marketplaceNFTMode = false;
      }
    });
  }

  Future<void> _loadUserName() async {
    final name = await PlayerDetails().fetchUserName();
    if (!mounted) return;
    setState(() {
      user = name;
    });
  }

  bool get _isMarketplaceTab => _navItems[_selectedIndex].isMarketplace;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final bool useDarkNav = _isMarketplaceTab && _marketplaceNFTMode == true;
    final Color navBgColor =
    useDarkNav ? const Color(0xFF2B2B2B) : Colors.white;
    final Color selectedItemColor =
    useDarkNav ? const Color(0xFFA259FF) : Colors.purple;
    final Color unselectedItemColor =
    useDarkNav ? Colors.white : Colors.black87;

    return SafeArea(
      child: Scaffold(
        appBar: useDarkNav
            ? null
            : AppBar(
          elevation: 0,
          backgroundColor: theme.scaffoldBackgroundColor,
          leading: IconButton(
            icon: const Icon(Icons.account_circle, size: 28),
            onPressed: () => _onNavTap(NavTab.More),
            tooltip: "Profile",
          ),
          title: Text(
            'Hello, $user',
            style: theme.textTheme.titleLarge
                ?.copyWith(fontWeight: FontWeight.w600),
          ),
          actions: [
            IconButton(
              icon: const Icon(Icons.notifications_none),
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Open notifications')),
                );
              },
              tooltip: "Notifications",
            ),
            IconButton(
              icon: const Icon(Icons.logout),
              onPressed: () {
                FirebaseAuth.instance.signOut();
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(
                      builder: (context) => const LoginScreen()),
                );
              },
              tooltip: "Log out",
            ),
            const SizedBox(width: 8),
          ],
        ),
        floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
        floatingActionButton: AnimatedContainer(
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeOut,
          child: Material(
            elevation: 32.0,
            color: Colors.transparent,
            shape: const CircleBorder(),
            child: InkWell(
              onTap: () => _onNavTap(NavTab.Play),
              customBorder: const CircleBorder(),
              child: Container(
                width: _selectedIndex == NavTab.Play.index ? 74 : 62,
                height: _selectedIndex == NavTab.Play.index ? 74 : 62,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Colors.deepPurple, Colors.purpleAccent],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.purple.withOpacity(0.3),
                      blurRadius: 12,
                      spreadRadius: 2,
                      offset: const Offset(0, 8),
                    ),
                  ],
                  border: Border.all(
                    color: Colors.purple,
                    width: 3,
                  ),
                ),
                child: const Icon(
                  Icons.play_circle_fill,
                  color: Colors.white,
                  size: 40,
                  shadows: [
                    Shadow(
                      offset: Offset(0, 4),
                      blurRadius: 16,
                      color: Colors.black26,
                    )
                  ],
                ),
              ),
            ),
          ),
        ),
        bottomNavigationBar: BottomAppBar(
          shape: const CircularNotchedRectangle(),
          notchMargin: 10,
          color: navBgColor,
          elevation: 24,
          // BottomAppBar enforces ~56px. Keep our content <= 56.
          child: SizedBox(
            height: 56,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildTabItem(NavTab.Home, Icons.home, 'Home',
                    selectedItemColor, unselectedItemColor),
                _buildTabItem(NavTab.Study, Icons.school, 'Study',
                    selectedItemColor, unselectedItemColor),
                const SizedBox(width: 46), // notch spacer for FAB
                _buildTabItem(NavTab.Marketplace, Icons.store, 'Market',
                    selectedItemColor, unselectedItemColor),
                _buildTabItem(NavTab.More, Icons.more_horiz, 'More',
                    selectedItemColor, unselectedItemColor),
              ],
            ),
          ),
        ),
        body: KeyedSubtree(
          key: ValueKey('$_selectedIndex$_tabUniqueKey'),
          child: _navItems[_selectedIndex].pageBuilder(
            _isMarketplaceTab ? _onMarketplaceNFTtap : () {},
          ),
        ),
      ),
    );
  }

  Widget _buildTabItem(NavTab tab, IconData icon, String label,
      Color selectedColor, Color unselectedColor) {
    final bool isSelected = _selectedIndex == tab.index;

    // Kept small so Column never overflows the BottomAppBar (56px)
    const double iconSize = 24; // <= 24 is safe
    const double fontSize = 11; // small, consistent across devices

    return Expanded(
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () => _onNavTap(tab),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center, // centers within 56px
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              color: isSelected ? selectedColor : unselectedColor,
              size: iconSize,
            ),
            const SizedBox(height: 2),
            Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textScaler: const TextScaler.linear(1.0),
              style: TextStyle(
                color: isSelected ? selectedColor : unselectedColor,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                fontSize: fontSize,
                height: 1.1, // tight line height
              ),
            ),
          ],
        ),
      ),
    );
  }
}
