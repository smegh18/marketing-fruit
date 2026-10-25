// ...imports remain unchanged...
import 'package:Marketing_Fruit/components/admin_finance.dart';
import 'package:Marketing_Fruit/components/nftandcrypto.dart';
import 'package:Marketing_Fruit/components/sim_shop_screen.dart';
import 'package:flutter/foundation.dart';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:Marketing_Fruit/screens/dashboard/main_layout_mobile.dart';
import 'package:Marketing_Fruit/components/NFToverview.dart';
import 'package:Marketing_Fruit/components/channel_chat.dart';
import 'package:Marketing_Fruit/components/channel_list.dart';
import 'package:Marketing_Fruit/components/combine%20_curreny_gmes_crypto.dart';
import 'package:Marketing_Fruit/components/event_creation.dart';
import 'package:Marketing_Fruit/components/player_details.dart';
import 'package:Marketing_Fruit/components/setup_presence.dart';
import 'package:Marketing_Fruit/course/course_screen.dart';
import 'package:Marketing_Fruit/ecommerce/homescreen.dart';
import 'package:Marketing_Fruit/marketplace/homepage.dart';
import 'package:Marketing_Fruit/marketplace/top_navigation_bar.dart';
import 'package:Marketing_Fruit/screens/dashboard/admin_books.dart';
import 'package:Marketing_Fruit/screens/dashboard/admin_content.dart';
import 'package:Marketing_Fruit/screens/dashboard/admin_dashboard.dart';
import 'package:Marketing_Fruit/screens/dashboard/book_creation_screen.dart';
import 'package:Marketing_Fruit/screens/dashboard/brand_dashboard.dart';
import 'package:Marketing_Fruit/screens/dashboard/channel_screen.dart';
import 'package:Marketing_Fruit/screens/dashboard/content_screen.dart';
import 'package:Marketing_Fruit/screens/dashboard/event_screen.dart';
import 'package:Marketing_Fruit/screens/dashboard/guardian_dashboard.dart';
import 'package:Marketing_Fruit/screens/dashboard/message_section.dart';
import 'package:Marketing_Fruit/screens/dashboard/product_screen.dart';
import 'package:Marketing_Fruit/screens/dashboard/profile_screen.dart';
import 'package:Marketing_Fruit/screens/dashboard/research_detail_page.dart';
import 'package:Marketing_Fruit/screens/dashboard/school_dashboard.dart';
import 'package:Marketing_Fruit/screens/dashboard/subscription_screen.dart';
import 'package:Marketing_Fruit/screens/dashboard/tikcet_screen.dart';
import 'package:Marketing_Fruit/screens/dashboard/user_event_page.dart';
import 'package:Marketing_Fruit/screens/dashboard/user_event_screen.dart';
import '../../components/add_NFTform.dart';
import '../../components/add_channel.dart';
import '../../components/business_accuracy.dart';
import '../../components/global_rank.dart';
import '../../components/market_forecast.dart';
import '../../components/seminar_card.dart';
import '../../components/simulator_button.dart';
import '../../components/spotify_player.dart';
import '../../components/streak_calender.dart';
import '../../components/student_list.dart';
import '../../components/videoplayer_screen.dart';
import '../../components/users_list.dart';
import '../../course/course_detail_screen.dart';
import '../../course/curriculum_screen.dart';
import '../../course/models.dart';
import 'NFTDetailScreen.dart';
import 'TxnDetailScreen.dart';
import 'book_detail_page.dart';
import 'dashboard_screen.dart';
import 'leaderboard_widget.dart';
import 'sidebar.dart';
import 'tab_menu.dart';


// --- Deep link into Content Section ---
enum ContentType { video, podcast, book, research }

class ContentLaunch {
  final ContentType type;
  final String? videoId;
  final Map<String, dynamic>? podcast;
  final Map<String, dynamic>? book;
  final Map<String, dynamic>? research;

  const ContentLaunch._(this.type, {this.videoId, this.podcast, this.book, this.research});

  const ContentLaunch.video(String id) : this._(ContentType.video, videoId: id);
  const ContentLaunch.podcast(Map<String, dynamic> p) : this._(ContentType.podcast, podcast: p);
  const ContentLaunch.book(Map<String, dynamic> b) : this._(ContentType.book, book: b);
  const ContentLaunch.research(Map<String, dynamic> r) : this._(ContentType.research, research: r);
}


class MainLayout extends StatefulWidget {
  static const String routeName = '/dashboard';

  final String userRole;
  final bool navCollapsed;
  final TextDirection direction;
  final int nftindex;
  final bool fs;
  final int sId;


    // NEW: optional “deep link” into Content Section
  final ContentLaunch? initialLaunch;


  const MainLayout({
    super.key,
    required this.userRole,
    this.navCollapsed = false,
    this.direction = TextDirection.ltr,
    this.nftindex = 0,
    this.initialLaunch,
    this.fs = false,
    this.sId = 0,
  });

  @override
  State<MainLayout> createState() => _MainLayoutState();
}

class _MainLayoutState extends State<MainLayout> {
  static const int profileSidebarIndex = 9999; // Chosen to not collide with other indices
  final GlobalKey tabHostKey = GlobalKey();
  bool isPlaying = false ;


  final ScrollController _scrollController = ScrollController();
  static const double kExpandedHeight = 100.0;
  static const double kCollapsedHeight = 45.0;


  double _topBarHeight = kExpandedHeight;
  // ============== Main (Student) ================
  late final List<String> _mainTitles = [
    _getDashboardName(),
    'Finance',
    'Study',
    'Marketplace',
    'Messages',
    'Community',
    'Event',
    'Content Section',
    'Profile'
  ];

  late final List<Widget> _mainPages = [
    _getDashboardScreenForRole(),
    const Center(child: Text('Finance Overview')),
    widget.fs? CourseDetailScreen(courseId: 3016,courseName: 'Marketing 101',onLessonTap: _openCurriculumTab,sectionId: widget.sId,): CoursesScreen(onCourseTap: _openCourseTab),
    const Center(child: Text('Marketplace')),
    UserMessageSection(onprofileTap: _openProfileTab,),
    ChannelsPage(onChannelTap: _openChannelTab, userRole: widget.userRole),

    UserEventScreen(onEventTap: _openEventTab, onEventCreated: _openAddEventFormTab, userRole: widget.userRole,),
    ContentScreen(
      onVideoTap: _openVideoPlayerTab,
      onBookTap: _openBookDetailTab,
      onPodcastTap: _openPodcastTab,
      onResearchTap: _openResearchDetailTab, // <— ADD THIS
    ),
    ProfileScreen(onOpenConversation: _openDirectMessageTab, userRole: widget.userRole,),
  ];

  final List<String> _subTitles = const [
    'Game Finance',
    'NFT & Crypto',
    'Sim Shop',
    'Merchandise',
    'NFT',
  ];

      final List<Widget> _subPages = [
      // Game Finance -> your combined row
      // Wrapped in Align + SingleChildScrollView so it sits at the top and never overflows vertically.
      Align(
        alignment: Alignment.topCenter,
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.only(top: 8.0),
            child: CurrencyGemsCryptoRow(
              cardHeight: 160, // same as your default
              padding: const EdgeInsets.all(20),
            ),
          ),
        ),
      ),

      // Keep the remaining sub-pages as-is (you can replace later if needed)
      LayoutBuilder(
    builder: (context, constraints) {
      return NftAndCryptoSection(
        width: constraints.maxWidth,
        // onNftTap: _openNFTDetailTab, // opens detail in a new tab
      );
    },
  ),
      const SimShopScreen(isWeb: true),
      FashionLandingPage(),
      const NFTLandingScreen(),
    ];


  // ----------------- ADMIN -----------------
  final List<String> _adminMenuTitles = const [
    'Dashboard',
    'Content',
    'Users',
    'NFT',
    'Products',
    'Subscription',
    'Add Game Finance',
    'Events',   // creator/manager view
    'Tickets',
    'Channels',
    'Books'
  ];

  List<Widget> _adminMenuPages() => [
    AdminDashboardScreen(
      onAddNFT: _openAddNFTFormTab,
      onTxnTap: _openTxnDetailTab,
      onNftTap: _openNFTDetailTab,
      onStatCardTap: _openUsersListWithRole,
    ),
    AdminContentScreen(),
    UsersList(
      onLocationTab: _openUserLocationTab,
      onStudentTab: _openStudentPreviewTab,
      onGuardianTab: _openGuardianDashboardTab,
      onSchoolTab: _openSchoolDashboardTab,
      userRole: widget.userRole,
    ),
    // const Center(child: Text('Marketplace')),
    NFTOverviewSection(onTxnTap: _openTxnDetailTab,onNftTap: _openNFTDetailTab,onAddNFT: _openAddNFTFormTab,),
    ProductsListPage(),
    SubscriptionListPage(),

    AddGameFinanceSection(
  initialGemsPrice: 0,
  initialCoinsPrice: 0,
  initialCoins2Price: 0,
  initialPolyPrice: 0,
  onPricesChanged: (data) {
    // Access values as:
    // data['row1']['gems'], data['row1']['coins'], data['row2']['coins'], data['row2']['poly']
    // ScaffoldMessenger.of(context).showSnackBar(
    //   SnackBar(
    //     content: Text('Gems: ${data['row1']['gems']}, Coins: ${data['row1']['coins']}, Coins: ${data['row2']['coins']}, Poly: ${data['row2']['poly']}'),
    //     duration: const Duration(milliseconds: 800),
    //   ),
    // );
  },
),


    EventScreen(onEventCreated: _openAddEventFormTab,onEventTap: _openEventTab,userRole: widget.userRole,),
    TicketsPage(),
    ChannelScreen(onChannelCreated: _openAddChannelFormTab,onChannelTap: _openChannelTab,userRole: widget.userRole,),
    AdminBooksScreen(onAddBook: _openAddBookFormTab,),
  ];

  // ----------------- BRAND -----------------
  final List<String> _brandMenuTitles = const [
    'Dashboard',
    'Users',
    'Events',
    'Messages',
    'Channels',
    // 'Profile', // <-- NEW
  ];

  List<Widget> _brandMenuPages() => [
    BrandDashboardPage(onStatCardTap: _openUsersListWithRole,),
    UsersList(
      onLocationTab: _openUserLocationTab,
      onStudentTab: _openStudentPreviewTab,
      onGuardianTab: _openGuardianDashboardTab,
      onSchoolTab: _openSchoolDashboardTab,
      userRole: widget.userRole,
    ),
    EventScreen(
      onEventCreated: _openAddEventFormTab,
      onEventTap: _openEventTab,
      userRole: widget.userRole,
    ),
    UserMessageSection(onprofileTap: _openProfileTab,),
    ChannelScreen(
      onChannelCreated: _openAddChannelFormTab,
      onChannelTap: _openChannelTab,
      userRole: widget.userRole,
    ),
    // NEW: Brand Profile
    ProfileScreen(
      onOpenConversation: _openDirectMessageTab, userRole: widget.userRole,
    ),
  ];

  // ----------------- GUARDIAN (now with Event + Events) -----------------
  final List<String> _guardianMenuTitles = const [
    'Dashboard',
    'Messages',
    'Channels',
    'Event',   // user-facing list
    'Events',  // creator/manager view
    // 'Profile', // <-- NEW
  ];

  List<Widget> _guardianMenuPages() => [
    GuardianDashboardScreen(
      guardianEmail: '',
      onPreviewRequested: _openStudentPreviewTab,
    ),
    UserMessageSection(onprofileTap: _openProfileTab,),
    ChannelScreen(onChannelTap: _openChannelTab, userRole: widget.userRole, onChannelCreated: _openAddChannelFormTab,),
    UserEventScreen(
      onEventTap: _openEventTab,
      onEventCreated: _openAddEventFormTab,
      userRole: widget.userRole,
    ),
    // EventScreen(
    //   onEventCreated: _openAddEventFormTab,
    //   onEventTap: _openEventTab,
    //   userRole: widget.userRole,
    // ),
    // NEW: Guardian Profile
  ProfileScreen(
    onOpenConversation: _openDirectMessageTab, userRole: widget.userRole,
  ),
  ];

  // ----------------- SCHOOL (now with Event + Events) -----------------
  final List<String> _schoolMenuTitles = const [
    'Dashboard',
    'Messages',
    'Channels',
    'Event',   // user-facing list
    'Events',  // creator/manager view
    // 'Profile', // <-- NEW
  ];

  List<Widget> _schoolMenuPages() => [
    SchoolDashboardScreen(
      onViewAllStudents: _openStudentListTab,
    ),
    UserMessageSection(onprofileTap: _openProfileTab,),
    ChannelScreen(onChannelTap: _openChannelTab, userRole: widget.userRole, onChannelCreated: _openAddChannelFormTab,),
    UserEventScreen(
      onEventTap: _openEventTab,
      onEventCreated: _openAddEventFormTab,
      userRole: widget.userRole,
    ),
    // EventScreen(
    //   onEventCreated: _openAddEventFormTab,
    //   onEventTap: _openEventTab,
    //   userRole: widget.userRole,
    // ),
    // NEW: School Profile
  ProfileScreen(
    onOpenConversation: _openDirectMessageTab, userRole: widget.userRole,
  ),
  ];

  // ----------------- Tabs/State -----------------
  final List<_TabInfo> _openTabs = [];
  int _selectedTabIndex = 0;
  int _selectedSidebarIndex = 0;
  double get sidebarWidth => widget.navCollapsed ? 80 : 250;

  @override
  void initState() {
    super.initState();

    // Always restore portrait when entering the dashboard
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
    ]);

    if (widget.userRole.toLowerCase() != 'admin') {
      setupPresence();
      final playerDetails = PlayerDetails();
      final balance = playerDetails.fetchBalance();
    }
        // After first frame: jump to Content Section and open the requested item in a new tab
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final launch = widget.initialLaunch;
      if (launch == null) return;

      // 1) ensure Content Section is selected (sidebar + tab) for Student role
      final contentIdx = _isAdmin || _isBrand || _isGuardian || _isSchool
          ? -1
          : _mainTitles.indexOf('Content Section');

      if (contentIdx != -1) {
        _openTab(contentIdx); // focuses the Content Section tab (Student role)
      }

      // 2) open the specific detail in its own tab
      switch (launch.type) {
        case ContentType.video:
          if (launch.videoId != null && launch.videoId!.isNotEmpty) {
            _openVideoPlayerTab(launch.videoId!);
          }
          break;
        case ContentType.podcast:
          if (launch.podcast != null) {
            _openPodcastTab(launch.podcast!);
          }
          break;
        case ContentType.book:
          if (launch.book != null) {
            _openBookDetailTab(launch.book!);
          }
          break;
        case ContentType.research:
          if (launch.research != null) {
            _openResearchDetailTab(launch.research!);
          }
          break;
      }
    });


    int idx = widget.nftindex;

    if (_isAdmin) {
      final adminPages = _adminMenuPages();
      idx = (idx >= 0 && idx < adminPages.length) ? idx : 0;
      _openTabs.add(_TabInfo(
        title: _adminMenuTitles[idx],
        page: adminPages[idx],
        sidebarIndex: idx,
      ));
      _selectedSidebarIndex = idx;
    } else if (_isBrand) {
      final brandPages = _brandMenuPages();
      idx = (idx >= 0 && idx < brandPages.length) ? idx : 0;
      _openTabs.add(_TabInfo(
        title: _brandMenuTitles[idx],
        page: brandPages[idx],
        sidebarIndex: idx,
      ));
      _selectedSidebarIndex = idx;
    } else if (_isGuardian) {
      final guardianPages = _guardianMenuPages();
      idx = (idx >= 0 && idx < guardianPages.length) ? idx : 0;
      _openTabs.add(_TabInfo(
        title: _guardianMenuTitles[idx],
        page: guardianPages[idx],
        sidebarIndex: idx,
      ));
      _selectedSidebarIndex = idx;
    } else if (_isSchool) {
      final schoolPages = _schoolMenuPages();
      idx = (idx >= 0 && idx < schoolPages.length) ? idx : 0;
      _openTabs.add(_TabInfo(
        title: _schoolMenuTitles[idx],
        page: schoolPages[idx],
        sidebarIndex: idx,
      ));
      _selectedSidebarIndex = idx;
    } else {
      String title;
      Widget page;
      try {
        if (idx >= 100 && idx < 100 + _subTitles.length) {
          final subIndex = idx - 100;
          title = _subTitles[subIndex];
          page = _subPages[subIndex];
        } else if (idx >= 200 && idx < 200 + _subTitles.length) {
          final subIndex = idx - 200 + 2; // offset for Marketplace subitems
          title = _subTitles[subIndex];
          page = _subPages[subIndex];
        } else {
          title = _mainTitles[idx];
          page = _mainPages[idx];
        }
        _openTabs.add(_TabInfo(
          title: title,
          page: page,
          sidebarIndex: idx,
        ));
        _selectedSidebarIndex = idx;
      } catch (e) {
        debugPrint('Error during init: $e');
        _openTabs.add(_TabInfo(
          title: _mainTitles[0],
          page: _mainPages[0],
          sidebarIndex: 0,
        ));
        _selectedSidebarIndex = 0;
      }
    }
  }

  void _handleScroll(double offset) {
    final calculatedHeight = (kExpandedHeight - offset).clamp(kCollapsedHeight, kExpandedHeight);
    if ((calculatedHeight - _topBarHeight).abs() > 0.5) {
      setState(() {
        _topBarHeight = calculatedHeight;
      });
    }
  }
  
  
  

  bool get _isAdmin => widget.userRole.trim().toLowerCase() == "admin";
  bool get _isBrand => widget.userRole.trim().toLowerCase() == "brand";
  bool get _isGuardian => widget.userRole.trim().toLowerCase() == "guardian";
  bool get _isSchool => widget.userRole.trim().toLowerCase() == "school";
  bool get _isStudent => !(_isAdmin || _isBrand || _isGuardian || _isSchool);

  @override
  Widget build(BuildContext context) {
    if (!kIsWeb) {
      final shortestSide = MediaQuery.of(context).size.shortestSide;
      if (shortestSide < 600) {
        return MainLayoutMobile(userRole: widget.userRole);
      }
    }

    final pixelRatio = MediaQuery.of(context).devicePixelRatio;
    const baselinePixelRatio = 1.0;
    double scaleFactor = 1.0;
    final theme = Theme.of(context);
    final title = _openTabs[_selectedTabIndex].title;

    if (pixelRatio > baselinePixelRatio) {
      scaleFactor = baselinePixelRatio / pixelRatio;
    }

    final isStudent = widget.userRole.toLowerCase() == 'student';

    return Directionality(
      key: tabHostKey,
      textDirection: widget.direction,
      child: Scaffold(
        body: NotificationListener<ScrollNotification>(
          onNotification: (scrollNotification) {
            if (scrollNotification.metrics.axis == Axis.vertical) {
              _handleScroll(scrollNotification.metrics.pixels);
            }
            return false; // do not stop notification propagation
          },
            child: Row(
              children: [
                SidebarWidget(
                  selectedIndex: _selectedSidebarIndex,
                  onItemSelected: _openTab,
                  userRole: widget.userRole,
                ),
                Expanded(
                  child: Column(
                    children: [
                      TabMenu(
                        tabs: _openTabs.map((tab) => tab.title).toList(),
                        selectedIndex: _selectedTabIndex,
                        onTabClose: closeTab,
                        onTabSelect: (index) {
                          setState(() {
                            _selectedTabIndex = index;
                            _selectedSidebarIndex = _openTabs[index].sidebarIndex;
                          });
                        },
                      ),
                      Container(
                        height: 20,
                        width: double.infinity,
                        decoration: BoxDecoration(
                          color: theme.scaffoldBackgroundColor,
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.05),
                              blurRadius: 4,
                              offset: const Offset(2, 0),
                            ),
                          ],
                        ),
                      ),
                      if (isStudent)
                        Container(
                          color: theme.scaffoldBackgroundColor,
                          padding: const EdgeInsets.symmetric(horizontal: 26, vertical: 2),
                          child: TopNavigationBar(
                            title: title,
                            height: _topBarHeight,
                            // scrollController: _scrollController,
                          ),
                        ),
                      Expanded(
                        child: Container(
                          color: theme.scaffoldBackgroundColor,
                          padding: EdgeInsets.symmetric(
                            horizontal: 26,
                            vertical: MediaQuery.of(context).size.height * 0.02,
                          ),
                          child: isStudent
                              ? ListView(
                            controller: _scrollController,
                            children: [
                              // Place your tab/page here. No internal scrolls for content page.
                              SizedBox(
                                // If you want scroll bar always to work,
                                // you can set height smaller than available body.
                                height: MediaQuery.of(context).size.height * 0.85,
                                child: _openTabs[_selectedTabIndex].page,
                              ),
                            ],
                          )
                              : Column(
                            children: [
                              Expanded(child: _openTabs[_selectedTabIndex].page),
                            ],
                          ),
                        ),
                      ),
                      // const Footer(),
                    ],
                  ),
                ),
              ],
            ),
        )
      ),
    );
  }





  void _openDirectMessageTab(String peerUid, {String? peerName, String? peerRole}) {
  const title = 'Messages';

  int sidebarIndex = -1;
  if (_isStudent) {
    sidebarIndex = _mainTitles.indexOf(title);
  } else if (_isBrand) {
    sidebarIndex = _brandMenuTitles.indexOf(title);
  } else if (_isGuardian) {
    sidebarIndex = _guardianMenuTitles.indexOf(title);
  } else if (_isSchool) {
    sidebarIndex = _schoolMenuTitles.indexOf(title);
  }

  final page = UserMessageSection(
    initialPeerId: peerUid,
    initialPeerName: peerName,
    initialPeerRole: peerRole,
    onprofileTap: _openProfileTab,
  );

  final existingIndex = _openTabs.indexWhere((t) => t.title == title);
  setState(() {
    if (existingIndex != -1) {
      _openTabs[existingIndex] = _TabInfo(
        title: title,
        page: page,
        sidebarIndex: sidebarIndex,
      );
      _selectedTabIndex = existingIndex;
    } else {
      _openTabs.add(_TabInfo(
        title: title,
        page: page,
        sidebarIndex: sidebarIndex,
      ));
      _selectedTabIndex = _openTabs.length - 1;
    }
    if (sidebarIndex != -1) _selectedSidebarIndex = sidebarIndex;
  });
}



  // ============= ROUTING ==============
  void _openTab(int sidebarIndex) {

    if (sidebarIndex == profileSidebarIndex) {
      // Open correct profile page for current role
      setState(() {
        // Replace this with actual profile logic for userRole, e.g.
        _openTabs.add(_TabInfo(
          title: "Profile",
          page: ProfileScreen(userRole: widget.userRole,onOpenConversation: _openDirectMessageTab,uid: '',),
          sidebarIndex: sidebarIndex,
        ));
        _selectedTabIndex = _openTabs.length - 1;
        _selectedSidebarIndex = sidebarIndex;
      });
      return;
    }
    // ADMIN
    if (_isAdmin) {
      final pages = _adminMenuPages();
      if (sidebarIndex < 0 || sidebarIndex >= pages.length) return;
      final title = _adminMenuTitles[sidebarIndex];
      final page = pages[sidebarIndex];
      final existingIndex = _openTabs.indexWhere((tab) => tab.title == title);

      setState(() {
        _selectedSidebarIndex = sidebarIndex;
        if (existingIndex != -1) {
          _selectedTabIndex = existingIndex;
        } else {
          _openTabs.add(_TabInfo(title: title, page: page, sidebarIndex: sidebarIndex));
          _selectedTabIndex = _openTabs.length - 1;
        }
      });
      return;
    }

    // BRAND
    if (_isBrand) {
      final pages = _brandMenuPages();
      if (sidebarIndex < 0 || sidebarIndex >= pages.length) return;
      final title = _brandMenuTitles[sidebarIndex];
      final page = pages[sidebarIndex];
      final existingIndex = _openTabs.indexWhere((tab) => tab.title == title);
      if (sidebarIndex == profileSidebarIndex) {
        // Open correct profile page for current role
        setState(() {
          // Replace this with actual profile logic for userRole, e.g.
          _openTabs.add(_TabInfo(
            title: "Profile",
            page: ProfileScreen(userRole: widget.userRole,onOpenConversation: _openDirectMessageTab,uid: '',),
            sidebarIndex: sidebarIndex,
          ));
          _selectedTabIndex = _openTabs.length - 1;
          _selectedSidebarIndex = sidebarIndex;
        });
        return;
      }
      setState(() {
        _selectedSidebarIndex = sidebarIndex;
        if (existingIndex != -1) {
          _selectedTabIndex = existingIndex;
        } else {
          _openTabs.add(_TabInfo(title: title, page: page, sidebarIndex: sidebarIndex));
          _selectedTabIndex = _openTabs.length - 1;
        }
      });
      return;
    }

    // GUARDIAN
    if (_isGuardian) {
      final pages = _guardianMenuPages();
      if (sidebarIndex < 0 || sidebarIndex >= pages.length) return;
      final title = _guardianMenuTitles[sidebarIndex];
      final page = pages[sidebarIndex];
      final existingIndex = _openTabs.indexWhere((tab) => tab.title == title);
      if (sidebarIndex == profileSidebarIndex) {
        // Open correct profile page for current role
        setState(() {
          // Replace this with actual profile logic for userRole, e.g.
          _openTabs.add(_TabInfo(
            title: "Profile",
            page: ProfileScreen(userRole: widget.userRole,onOpenConversation: _openDirectMessageTab,uid: '',),
            sidebarIndex: sidebarIndex,
          ));
          _selectedTabIndex = _openTabs.length - 1;
          _selectedSidebarIndex = sidebarIndex;
        });
        return;
      }
      setState(() {
        _selectedSidebarIndex = sidebarIndex;
        if (existingIndex != -1) {
          _selectedTabIndex = existingIndex;
        } else {
          _openTabs.add(_TabInfo(title: title, page: page, sidebarIndex: sidebarIndex));
          _selectedTabIndex = _openTabs.length - 1;
        }
      });
      return;
    }

    // SCHOOL
    if (_isSchool) {
      final pages = _schoolMenuPages();
      if (sidebarIndex < 0 || sidebarIndex >= pages.length) return;
      final title = _schoolMenuTitles[sidebarIndex];
      final page = pages[sidebarIndex];
      final existingIndex = _openTabs.indexWhere((tab) => tab.title == title);
      if (sidebarIndex == profileSidebarIndex) {
        // Open correct profile page for current role
        setState(() {
          // Replace this with actual profile logic for userRole, e.g.
          _openTabs.add(_TabInfo(
            title: "Profile",
            page: ProfileScreen(userRole: widget.userRole,onOpenConversation: _openDirectMessageTab,uid: '',),
            sidebarIndex: sidebarIndex,
          ));
          _selectedTabIndex = _openTabs.length - 1;
          _selectedSidebarIndex = sidebarIndex;
        });
        return;
      }
      setState(() {
        _selectedSidebarIndex = sidebarIndex;
        if (existingIndex != -1) {
          _selectedTabIndex = existingIndex;
        } else {
          _openTabs.add(_TabInfo(title: title, page: page, sidebarIndex: sidebarIndex));
          _selectedTabIndex = _openTabs.length - 1;
        }
      });
      return;
    }

    // STUDENT / DEFAULT
    try {
      String title;
      Widget page;
      if (sidebarIndex == profileSidebarIndex) {
        // Open correct profile page for current role
        setState(() {
          // Replace this with actual profile logic for userRole, e.g.
          _openTabs.add(_TabInfo(
            title: "Profile",
            page: ProfileScreen(userRole: widget.userRole,onOpenConversation: _openDirectMessageTab,uid: '',),
            sidebarIndex: sidebarIndex,
          ));
          _selectedTabIndex = _openTabs.length - 1;
          _selectedSidebarIndex = sidebarIndex;
        });
        return;
      }
      if (sidebarIndex >= 100 && sidebarIndex < 100 + _subTitles.length) {
        final subIndex = sidebarIndex - 100;
        title = _subTitles[subIndex];
        page = _subPages[subIndex];
      } else if (sidebarIndex >= 200 && sidebarIndex < 200 + _subTitles.length) {
        final subIndex = sidebarIndex - 200 + 2;
        title = _subTitles[subIndex];
        page = _subPages[subIndex];
      } else {
        if (sidebarIndex >= _mainTitles.length) throw RangeError('Invalid main sidebarIndex: $sidebarIndex');
        title = _mainTitles[sidebarIndex];
        page = _mainPages[sidebarIndex];
      }
      final existingIndex = _openTabs.indexWhere((tab) => tab.title == title);
      setState(() {
        _selectedSidebarIndex = sidebarIndex;
        if (existingIndex != -1) {
          _selectedTabIndex = existingIndex;
        } else {
          _openTabs.add(_TabInfo(title: title, page: page, sidebarIndex: sidebarIndex));
          _selectedTabIndex = _openTabs.length - 1;
        }
      });
    } catch (e) {
      debugPrint('Error opening tab with sidebarIndex $sidebarIndex: $e');
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('Navigation error: ${e.toString()}'),
        backgroundColor: Colors.red,
      ));
    }
  }

  // ================ Tab close ================
  void _closeTab(int tabIndex) {
    setState(() {
      _openTabs.removeAt(tabIndex);
      if (_openTabs.isEmpty) {
        if (_isAdmin) {
          final pages = _adminMenuPages();
          _openTabs.add(_TabInfo(title: _adminMenuTitles[0], page: pages[0], sidebarIndex: 0));
        } else if (_isBrand) {
          final pages = _brandMenuPages();
          _openTabs.add(_TabInfo(title: _brandMenuTitles[0], page: pages[0], sidebarIndex: 0));
        } else if (_isGuardian) {
          final pages = _guardianMenuPages();
          _openTabs.add(_TabInfo(title: _guardianMenuTitles[0], page: pages[0], sidebarIndex: 0));
        } else if (_isSchool) {
          final pages = _schoolMenuPages();
          _openTabs.add(_TabInfo(title: _schoolMenuTitles[0], page: pages[0], sidebarIndex: 0));
        } else {
          _openTabs.add(_TabInfo(title: _mainTitles[0], page: _mainPages[0], sidebarIndex: 0));
        }
        _selectedTabIndex = 0;
        _selectedSidebarIndex = 0;
      } else {
        _selectedTabIndex = _selectedTabIndex.clamp(0, _openTabs.length - 1);
        _selectedSidebarIndex = _openTabs[_selectedTabIndex].sidebarIndex;
      }
    });
  }

  void _openUserLocationTab(String userName, Map<dynamic, dynamic> locationHistory) {
    final tabTitle = 'Location Information - $userName';
    final existingIndex = _openTabs.indexWhere((tab) => tab.title == tabTitle);

    if (existingIndex != -1) {
      setState(() => _selectedTabIndex = existingIndex);
      return;
    }
    setState(() {
      _openTabs.add(_TabInfo(
        title: tabTitle,
        page: LocationInformationTab(userName: userName, history: locationHistory),
        sidebarIndex: -1,
      ));
      _selectedTabIndex = _openTabs.length - 1;
    });
  }

  void _openGuardianDashboardTab(String guardianName, String guardianEmail) {
    final title = "$guardianName Guardian Dashboard";
    final existingIndex = _openTabs.indexWhere((tab) => tab.title == title);
    if (existingIndex != -1) {
      setState(() => _selectedTabIndex = existingIndex);
      return;
    }
    setState(() {
      _openTabs.add(_TabInfo(
        title: title,
        sidebarIndex: -1,
        page: GuardianDashboardScreen(
          guardianEmail: guardianEmail,
          onPreviewRequested: _openStudentPreviewTab,
        ),
      ));
      _selectedTabIndex = _openTabs.length - 1;
    });
  }

  void _openSchoolDashboardTab(String schoolName, String schoolId) {
    final title = "$schoolName School Dashboard";
    final existingIndex = _openTabs.indexWhere((tab) => tab.title == title);
    if (existingIndex != -1) {
      setState(() => _selectedTabIndex = existingIndex);
      return;
    }
    setState(() {
      _openTabs.add(_TabInfo(
        title: title,
        sidebarIndex: -1,
        page: SchoolDashboardScreen(
          onViewAllStudents: _openStudentListTab,
        ),
      ));
      _selectedTabIndex = _openTabs.length - 1;
    });
  }

  void _openStudentPreviewTab(String studentName, String studentId) {
    final title = '$studentName Dashboard';
    final existingIndex = _openTabs.indexWhere((tab) => tab.title == title);
    if (existingIndex != -1) {
      setState(() => _selectedTabIndex = existingIndex);
      return;
    }

    setState(() {
      _openTabs.add(_TabInfo(
        title: title,
        sidebarIndex: -1,
        page: Container(
          width: double.infinity,
          height: double.infinity,
          padding: const EdgeInsets.all(16),
          child: SingleChildScrollView(
            child: Column(
              children: [
                LayoutBuilder(
                  builder: (context, constraints) {
                    double rowSpacing = constraints.maxWidth * 0.02;
                    double itemWidth = (constraints.maxWidth - 2 * rowSpacing) / 3;
                    return Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        SizedBox(width: itemWidth, child: SimulatorButton(disabled: true)),
                        SizedBox(width: rowSpacing),
                        SizedBox(width: itemWidth, child: MarketForecastButton(disabled: true)),
                        SizedBox(width: rowSpacing),
                        SizedBox(width: itemWidth, child: GlobalRankCard(disabled: true)),
                      ],
                    );
                  },
                ),
                const SizedBox(height: 20),
                LayoutBuilder(
                  builder: (context, constraints) {
                    double rowSpacing = constraints.maxWidth * 0.02;
                    double itemWidth = (constraints.maxWidth - 2 * rowSpacing) / 3;
                    return Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        SizedBox(width: itemWidth * 1.3, child: EventCarousel()),
                        SizedBox(width: rowSpacing),
                        SizedBox(width: itemWidth * 0.7, child: BusinessAccuracyWidget(width: 0.17, disabled: true)),
                        SizedBox(width: rowSpacing),
                        SizedBox(width: itemWidth, child: StreakCalendar(userId: studentId, width: 0.22, disabled: true)),
                      ],
                    );
                  },
                ),
                const SizedBox(height: 20),
                LayoutBuilder(
                  builder: (context, constraints) {
                    return LeaderboardWidget(width: constraints.maxWidth, disabled: true);
                  },
                ),
              ],
            ),
          ),
        ),
      ));

      _selectedTabIndex = _openTabs.length - 1;
    });
  }

  void _openUsersListWithRole(String role) {
    final title = 'Users - $role';
    final existingIndex = _openTabs.indexWhere((tab) => tab.title == title);

    if (existingIndex != -1) {
      setState(() => _selectedTabIndex = existingIndex);
      return;
    }
    setState(() {
      _openTabs.add(_TabInfo(
        title: title,
        page: UsersList(
          onLocationTab: _openUserLocationTab,
          onStudentTab: _openStudentPreviewTab,
          onGuardianTab: _openGuardianDashboardTab,
          onSchoolTab: _openSchoolDashboardTab,
          initialRole: role,
          userRole: widget.userRole,
        ),
        sidebarIndex: -1,
      ));
      _selectedTabIndex = _openTabs.length - 1;
    });
  }

  void _openAddEventFormTab() {
    const title = 'Add Event';
    final existingIndex = _openTabs.indexWhere((tab) => tab.title == title);
    if (existingIndex != -1) {
      setState(() => _selectedTabIndex = existingIndex);
      return;
    }
    setState(() {
      _openTabs.add(_TabInfo(
        title: title,
        sidebarIndex: -1,
        page: EventCreationScreen(),
      ));
      _selectedTabIndex = _openTabs.length - 1;
    });
  }

  void _openEventTab(String eventId, {String? eventName}) {
    final title = eventName ?? 'EventDetail';

    final existingIndex = _openTabs.indexWhere((tab) =>
      tab.title == title && tab.page is UserEventDashboardPage && (tab.page as UserEventDashboardPage).eventId == eventId
    );

    if (existingIndex != -1) {
      setState(() {
        _selectedTabIndex = existingIndex;
      });
      return;
    }

    setState(() {
      _openTabs.add(_TabInfo(
        title: title,
        sidebarIndex: -1,
        page: UserEventDashboardPage(eventId: eventId, userRole: widget.userRole, onNFTCardTap: _openNFTDetailTab),
      ));
      _selectedTabIndex = _openTabs.length - 1;
    });
  }

  void _openAddBookFormTab() {
    const title = 'Add Book';
    final existingIndex = _openTabs.indexWhere((tab) => tab.title == title);
    if (existingIndex != -1) {
      setState(() => _selectedTabIndex = existingIndex);
      return;
    }
    setState(() {
      _openTabs.add(_TabInfo(
        title: title,
        sidebarIndex: -1,
        page: BookCreationScreen(),
      ));
      _selectedTabIndex = _openTabs.length - 1;
    });
  }

  void _openAddChannelFormTab() {
    const title = 'Add Channel';
    final existingIndex = _openTabs.indexWhere((tab) => tab.title == title);
    if (existingIndex != -1) {
      setState(() => _selectedTabIndex = existingIndex);
      return;
    }
    setState(() {
      _openTabs.add(_TabInfo(
        title: title,
        sidebarIndex: -1,
        page: AddChannelSection(),
      ));
      _selectedTabIndex = _openTabs.length - 1;
    });
  }

  void _openProfileTab(String id, String name) {
    final title = '$name\'s Profile';
    final existingIndex = _openTabs.indexWhere((tab) => tab.title == title);
    if (existingIndex != -1) {
      setState(() => _selectedTabIndex = existingIndex);
      return;
    }
    setState(() {
      _openTabs.add(_TabInfo(
        title: title,
        sidebarIndex: -1,
        page: ProfileScreen(uid: id, userRole: '',),
      ));
      _selectedTabIndex = _openTabs.length - 1;
    });
  }


  void _openChannelTab(String id, {String? messageId}) {
    const title = 'Channel Chat';
    final existingIndex = _openTabs.indexWhere((tab) => tab.title == title);

    // Force the ChannelSectionPage to remount when channel or message changes
    final tabKey = ValueKey('channel-$id-${messageId ?? ""}');

    final page = ChannelSectionPage(
      key: tabKey,
      channelId: id,
      userRole: widget.userRole,
      onprofileTap: _openProfileTab,
      initialJumpMessageId: messageId, // <— pass the target message here
    );

    if (existingIndex != -1) {
      setState(() {
        _openTabs[existingIndex] = _TabInfo(
          title: title,
          sidebarIndex: -1,
          page: page,
        );
        _selectedTabIndex = existingIndex;
      });
      return;
    }

    setState(() {
      _openTabs.add(_TabInfo(
        title: title,
        sidebarIndex: -1,
        page: page,
      ));
      _selectedTabIndex = _openTabs.length - 1;
    });
  }




  void _openCourseTab(Course course) {
    const title = 'Course Detail';
    final existingIndex = _openTabs.indexWhere((tab) => tab.title == title);

    if (existingIndex != -1) {
      setState(() => _selectedTabIndex = existingIndex);
      return;
    }

    setState(() {
      _openTabs.add(_TabInfo(
        title: title,
        sidebarIndex: -1,
        page: CourseDetailScreen(
          courseId: course.id,
          courseName: course.name,
          onLessonTap: _openCurriculumTab, // updated callback for curriculum entry navigation
        ),
      ));
      _selectedTabIndex = _openTabs.length - 1;
    });
  }

// Can open at a specific index when coming from CourseDetailScreen
  void _openCurriculumTab(List<SectionItem> items, int courseId, [int startIndex = 0]) {
    const title = 'Curriculum';

    final existingIndex = _openTabs.indexWhere((tab) => tab.title == title);
    if (existingIndex != -1) {
      setState(() => _selectedTabIndex = existingIndex);
      return;
    }

    // Now include both lessons and quizzes in the full sequence (do not filter)
    if (items.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No lessons or quizzes available in this section'))
      );
      return;
    }
    setState(() {
      _openTabs.add(_TabInfo(
        title: title,
        sidebarIndex: -1,
        page: CurriculumInteractiveScreen(
          curriculum: items,
          courseId: courseId,
          startIndex: startIndex, // start at the correct curriculum item
          onProgressUpdate: (progress) {
            // Optionally handle curriculum progress updates for this tab/session here.
          },
        ),
      ));
      _selectedTabIndex = _openTabs.length - 1;
    });
  }



  void _openAddNFTFormTab() {
    const title = 'Add NFT';
    final existingIndex = _openTabs.indexWhere((tab) => tab.title == title);
    if (existingIndex != -1) {
      setState(() => _selectedTabIndex = existingIndex);
      return;
    }
    setState(() {
      _openTabs.add(_TabInfo(
        title: title,
        sidebarIndex: -1,
        page: AddNFTFormScreen(
          onCancel: () => _closeTabByTitle(title),
          onComplete: () => _closeTabByTitle(title),
        ),
      ));
      _selectedTabIndex = _openTabs.length - 1;
    });
  }

  void _openNFTDetailTab(Map<String, dynamic> nftData) {
    final nftId = nftData['id'] ?? '';
    final title = 'NFT: ${nftData['name'] ?? nftId}';
    final existingIndex = _openTabs.indexWhere((tab) => tab.title == title);
    if (existingIndex != -1) {
      setState(() => _selectedTabIndex = existingIndex);
      return;
    }
    setState(() {
      _openTabs.add(_TabInfo(
        title: title,
        sidebarIndex: -1,
        page: NFTDetailScreen(
          nftId: nftId,
          onClose: () => _closeTabByTitle(title),
          onTxnTap: _openTxnDetailTab,
        ),
      ));
      _selectedTabIndex = _openTabs.length - 1;
    });
  }

  void _openTxnDetailTab(String txnHash) {
    final title = 'Txn: ${txnHash.substring(0, 8)}...';
    final existingIndex = _openTabs.indexWhere((tab) => tab.title == title);
    if (existingIndex != -1) {
      setState(() => _selectedTabIndex = existingIndex);
      return;
    }
    setState(() {
      _openTabs.add(_TabInfo(
        title: title,
        sidebarIndex: -1,
        page: TxnDetailScreen(
          txnHash: txnHash,
          onClose: () => _closeTabByTitle(title),
        ),
      ));
      _selectedTabIndex = _openTabs.length - 1;
    });
  }

  void _closeTabByTitle(String title) {
    final tabIndex = _openTabs.indexWhere((t) => t.title == title);
    if (tabIndex != -1) {
      _closeTab(tabIndex);
    }
  }

    void _openBookDetailTab(dynamic book) {
    final m = (book is Map<String, dynamic>) ? book : <String, dynamic>{};
    final vol = (m['volumeInfo'] as Map?) ?? const {};
    final name = (vol['title'] ?? m['bookName'] ?? 'Unknown').toString();
    final title = 'Book: $name';

    debugPrint('[MainLayout] _openBookDetailTab -> $name');

    // If a tab with the same title exists, replace its page so it remounts.
    final existingIndex = _openTabs.indexWhere((tab) => tab.title == title);
    final page = BookDetailPage(
      key: ValueKey('book-$name-${DateTime.now().millisecondsSinceEpoch}'),
      book: m,
      onCloseTab: () {
        final tabIndex = _openTabs.indexWhere((t) => t.title == title);
        if (tabIndex != -1) _closeTab(tabIndex);
      },
    );
    


  setState(() {
    if (existingIndex != -1) {
      _openTabs[existingIndex] = _TabInfo(
        title: title,
        page: page,
        sidebarIndex: _selectedSidebarIndex,
      );
      _selectedTabIndex = existingIndex;
    } else {
      _openTabs.add(_TabInfo(
        title: title,
        page: page,
        sidebarIndex: _selectedSidebarIndex,
      ));
      _selectedTabIndex = _openTabs.length - 1;
    }
  });
}



  void _openVideoPlayerTab(String videoId) {
    const title = 'Video Player';
    final existingIndex = _openTabs.indexWhere((tab) => tab.title == title);
    if (existingIndex != -1) {
      setState(() => _selectedTabIndex = existingIndex);
      return;
    }
    setState(() {
      _openTabs.add(_TabInfo(
        title: title,
        sidebarIndex: _selectedSidebarIndex,
        page: VideoPlayerScreen(
          videoId: videoId,
          onCloseTab: () {
            final tabIndex = _openTabs.indexWhere((t) => t.title == title);
            if (tabIndex != -1) {
              _closeTab(tabIndex);
            }
          },
        ),
      ));
      _selectedTabIndex = _openTabs.length - 1;
    });
  }
  void _openResearchDetailTab(Map<String, dynamic> post) {
  final name = (post['title'] ?? 'Untitled').toString();
  final title = 'Research: $name';

  final existingIndex = _openTabs.indexWhere((tab) => tab.title == title);

  final page = ResearchDetailPage(
    key: ValueKey('research-$name-${DateTime.now().millisecondsSinceEpoch}'),
    post: post,
    onCloseTab: () {
      final tabIndex = _openTabs.indexWhere((t) => t.title == title);
      if (tabIndex != -1) _closeTab(tabIndex);
    },
  );

  setState(() {
    if (existingIndex != -1) {
      _openTabs[existingIndex] = _TabInfo(
        title: title,
        page: page,
        sidebarIndex: _selectedSidebarIndex,
      );
      _selectedTabIndex = existingIndex;
    } else {
      _openTabs.add(_TabInfo(
        title: title,
        page: page,
        sidebarIndex: _selectedSidebarIndex,
      ));
      _selectedTabIndex = _openTabs.length - 1;
    }
  });
}


  void _openPodcastTab(Map<String, dynamic> episode) {
    final title = 'Podcast: ${episode['title']}';
    final existingIndex = _openTabs.indexWhere(
            (tab) => tab.title == title && tab.page is LibsynPodcastPlayerController
    );
    if (existingIndex != -1) {
      setState(() => _selectedTabIndex = existingIndex);
      return;
    }

    final podcastState = LibsynPodcastPlayerState();
    _openTabs.add(_TabInfo(
      title: title,
      sidebarIndex: _selectedSidebarIndex,
      page: LibsynPodcastPlayerController(
        playerState: podcastState,
        child: LibsynPodcastPlayerScreen(
          episode: episode,
          playerState: podcastState,
          onExplicitCloseTab: () async {
            await podcastState.player.stop();
            podcastState.disposeController();
          },
          onSwitchEpisode: _openPodcastTab,
        ),
      ),
      podcastPlayerState: podcastState,
    ));



    setState(() {
      _selectedTabIndex = _openTabs.length - 1;
    });
  }



  Future<void> closeTab(int tabIndex) async {
    if (tabIndex < 0 || tabIndex >= _openTabs.length) return;

    final tab = _openTabs[tabIndex];

    if (tab.podcastPlayerState != null) {
      try {
        await tab.podcastPlayerState!.player.stop();
        tab.podcastPlayerState!.disposeController();
      } catch (_) {}
    }

    setState(() {
      _openTabs.removeAt(tabIndex);
      if (_openTabs.isEmpty) {
        if (_isAdmin) {
          final pages = _adminMenuPages();
          _openTabs.add(_TabInfo(title: _adminMenuTitles[0], page: pages[0], sidebarIndex: 0));
        } else if (_isBrand) {
          final pages = _brandMenuPages();
          _openTabs.add(_TabInfo(title: _brandMenuTitles[0], page: pages[0], sidebarIndex: 0));
        } else if (_isGuardian) {
          final pages = _guardianMenuPages();
          _openTabs.add(_TabInfo(title: _guardianMenuTitles[0], page: pages[0], sidebarIndex: 0));
        } else if (_isSchool) {
          final pages = _schoolMenuPages();
          _openTabs.add(_TabInfo(title: _schoolMenuTitles[0], page: pages[0], sidebarIndex: 0));
        } else {
          _openTabs.add(_TabInfo(title: _mainTitles[0], page: _mainPages[0], sidebarIndex: 0));
        }
        _selectedTabIndex = 0;
        _selectedSidebarIndex = 0;
      } else {
        _selectedTabIndex = _selectedTabIndex.clamp(0, _openTabs.length - 1);
        _selectedSidebarIndex = _openTabs[_selectedTabIndex].sidebarIndex;
      }
    });
  }





  Future<void> _closePodcastTabIfNeeded(int tabIndex) async {
    if (tabIndex < 0 || tabIndex >= _openTabs.length) return;
    final page = _openTabs[tabIndex].page;
    // If the page subtree includes a LibsynPodcastPlayerController, stop/cleanup
    // Use the current context for lookup; if tabs render with unique keys/contexts,
    // you can store a GlobalKey for each tab page to access its context.
    final ctx = tabHostKey.currentContext; // Ensure _tabHostKey is the parent hosting pages
    if (ctx != null) {
      try {
        final state = LibsynPodcastPlayerController.of(ctx);
        try { await state.player.stop(); } catch (_) {}
        state.disposeController();
      } catch (_) {
        // Not a podcast tab or no controller found; ignore
      }
    }
  }

  Future<void> _closeTabExplicit(int tabIndex) async {
    await _closePodcastTabIfNeeded(tabIndex);
    if (LibsynPodcastPlayerController.of(tabHostKey.currentContext!).player.playing){
      await LibsynPodcastPlayerController.of(context).player.stop();
    }
    setState(() {
      _openTabs.removeAt(tabIndex);
      if (_selectedTabIndex >= _openTabs.length) {
        _selectedTabIndex = _openTabs.isEmpty ? 0 : _openTabs.length - 1;
      }
    });
  }




  void _openStudentListTab() {
  const title = 'Student List';
  final existingIndex = _openTabs.indexWhere((tab) => tab.title == title);
  if (existingIndex != -1) {
    setState(() => _selectedTabIndex = existingIndex);
    return;
  }
  setState(() {
    _openTabs.add(_TabInfo(
      title: title,
      sidebarIndex: -1,
      page: StudentListTab(
        onStudentTap: _openStudentPreviewTab,
        // 👇 NEW: when Chat is clicked in the list, jump straight to DMs
        onChatTap: (studentName, studentId) {
          _openDirectMessageTab(
            studentId,
            peerName: studentName,
            peerRole: 'Student',
          );
        },
      ),
    ));
    _selectedTabIndex = _openTabs.length - 1;
  });
}


  String _getDashboardName() {
    switch (widget.userRole.toLowerCase()) {
      case 'student':
        return 'Dashboard';
      case 'guardian':
        return 'Guardian Dashboard';
      case 'brand':
        return 'Brand Dashboard';
      case 'school':
        return 'School Dashboard';
      case 'admin':
        return 'Admin Dashboard';
      default:
        return 'Dashboard';
    }
  }

  Widget _getDashboardScreenForRole() {
    switch (widget.userRole.toLowerCase()) {
      case 'student':
        return const DashboardScreen();
      case 'guardian':
        return GuardianDashboardScreen(
          onPreviewRequested: _openStudentPreviewTab,
          guardianEmail: '',
        );
      case 'brand':
        return BrandDashboardPage();
      case 'school':
        return SchoolDashboardScreen(
          onViewAllStudents: _openStudentListTab,
        );
      case 'admin':
        return AdminDashboardScreen(
          onAddNFT: _openAddNFTFormTab,
          onTxnTap: _openTxnDetailTab,
          onNftTap: _openNFTDetailTab,
        );
      default:
        return const DashboardScreen();
    }
  }
}

class _TabInfo {
  final String title;
  final int sidebarIndex;
  final Widget page;
  final LibsynPodcastPlayerState? podcastPlayerState; // New nullable reference

  _TabInfo({
    required this.title,
    required this.sidebarIndex,
    required this.page,
    this.podcastPlayerState,
  });
}

