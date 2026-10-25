import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:Marketing_Fruit/components/channel_list.dart';
import 'package:Marketing_Fruit/components/spotify_player.dart';
import 'package:Marketing_Fruit/components/videoplayer_screen.dart';
import 'package:Marketing_Fruit/screens/dashboard/book_detail_page_mobile.dart';
import 'package:Marketing_Fruit/screens/dashboard/content_screen_mobile.dart';
import 'package:Marketing_Fruit/screens/dashboard/message_section.dart';
import 'package:Marketing_Fruit/screens/dashboard/research_detail_page.dart';
import '../screens/dashboard/dashboard_screen_mobile.dart';
import '../screens/dashboard/profile_screen_mobile.dart';
import 'package:Marketing_Fruit/components/combine _curreny_gmes_crypto.dart';
import 'channel_chat.dart';

// Replace with your EventData model
// class EventData { ... }

class MoreSection extends StatefulWidget {
  final String userId;
  final String userRole;
  const MoreSection({
    super.key,
    required this.userId,
    required this.userRole,
  });

  @override
  State<MoreSection> createState() => _MoreSectionState();
}

class _MoreSectionState extends State<MoreSection> {
  bool showEvents = false;
  bool showProfile = false;
  bool showMessages = false;
  bool showCommunity = false;
  bool showContent = false;
  bool showPodcast = false;
  bool showBook = false;
  bool showFinance = false;

  Stream<List<EventData>> eventsStream(String userId) {
    final DatabaseReference eventsRef = FirebaseDatabase.instance.ref('events');
    return eventsRef.onValue.map((DatabaseEvent event) {
      final data = event.snapshot.value;

      if (data == null || (data is Map && data.isEmpty)) {
        return <EventData>[];
      }

      final eventsMap = Map<String, dynamic>.from(data as Map);
      final filteredEventsList = eventsMap.entries.where((e) {
        final valueMap = e.value as Map;
        final regUsers = valueMap['registeredUsers'];
        // Only include event if registeredUsers is a Map and contains userId
        return regUsers is Map && regUsers.containsKey(userId);
      }).map((e) {
        final key = e.key;
        final value = Map<dynamic, dynamic>.from(e.value as Map);
        return EventData.fromMap(key, value);
      }).toList();

      // Sort by start date (soonest first)
      filteredEventsList.sort((a, b) => a.start.compareTo(b.start));
      return filteredEventsList;
    });
  }

  void _openChannel(String id, {String? messageId}) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ChannelSectionPage(
          channelId: id,
          userRole: "Student",
          // 👇 this makes the chat land and stay on the message
          initialJumpMessageId: messageId,
          onprofileTap: _openProfile,
        ),
      )
    );
    // const title = 'Channel Chat';
    // final existingIndex = _openTabs.indexWhere((tab) => tab.title == title);
    //
    // if (existingIndex != -1) {
    //   // REPLACE the existing Channel Chat page with the new channel+message
    //   setState(() {
    //     _openTabs[existingIndex] = _TabInfo(
    //       title: title,
    //       sidebarIndex: -1,
    //       page: ChannelSectionPage(
    //         channelId: id,
    //         userRole: widget.userRole,
    //         // 👇 this makes the chat land and stay on the message
    //         initialJumpMessageId: messageId,
    //       ),
    //     );
    //     _selectedTabIndex = existingIndex;
    //   });
    //   return;
    }

    void _openProfile(String id, String name) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => ProfileScreenMobile(userRole: widget.userRole,uid: id,),
        ),
      );
    }

  void _openDirectMessageTab(String peerUid, {String? peerName, String? peerRole}) {

    final page = UserMessageSection(
      initialPeerId: peerUid,
      initialPeerName: peerName,
      initialPeerRole: peerRole,
      onprofileTap: _openProfile,
    );

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => page,
      ),
    );

  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final userId = FirebaseAuth.instance.currentUser?.uid ?? widget.userId;

    if (showFinance) {
      return Scaffold(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        appBar: AppBar(
          title: Text("Finance", style: GoogleFonts.poppins(color: Colors.black)),
          backgroundColor: Colors.white,
          elevation: 0,
          iconTheme: const IconThemeData(color: Colors.black),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () => setState(() => showFinance = false),
          ),
        ),
        body: const SafeArea(
          child: SingleChildScrollView(
            child: CurrencyGemsCryptoRow(
              padding: EdgeInsets.symmetric(horizontal: 16, vertical: 20),
            ),
          ),
        ),
      );
    }

    // Events fullpage view with back button
    if (showEvents) {
      return Scaffold(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        body: SafeArea(
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // IconButton(
                  //   icon: const Icon(Icons.arrow_back),
                  //   onPressed: () => setState(() => showEvents = false),
                  // ),
                  // const SizedBox(width: 6),
                  Text(
                    "My Events",
                    textAlign: TextAlign.center,
                    style: GoogleFonts.poppins(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              Expanded(
                child: StreamBuilder<List<EventData>>(
                  stream: eventsStream(userId),
                  builder: (context, snapshot) {
                    final events = snapshot.data ?? [];
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    } else if (events.isEmpty) {
                      return const Center(child: Text("No events found"));
                    }
                    return ListView.builder(
                      padding: const EdgeInsets.only(top: 16),
                      itemCount: events.length,
                      itemBuilder: (context, idx) {
                        final event = events[idx];
                        return Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                          child: InkWell(
                            borderRadius: BorderRadius.circular(18),
                            onTap: () {
                              // TODO: Navigate to event details
                            },
                            child: Card(
                              elevation: 5,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
                              clipBehavior: Clip.antiAlias,
                              child: Stack(
                                children: [
                                  SizedBox(
                                    height: 160,
                                    width: double.infinity,
                                    child: ColorFiltered(
                                      colorFilter: ColorFilter.mode(
                                        Colors.black.withOpacity(0.5),
                                        BlendMode.darken,
                                      ),
                                      child: Image.network(
                                        event.bannerUrl,
                                        fit: BoxFit.cover,
                                        color: Colors.black.withOpacity(0.5),
                                        colorBlendMode: BlendMode.darken,
                                      ),
                                    ),
                                  ),
                                  Positioned.fill(
                                    child: Container(
                                      alignment: Alignment.center,
                                      padding: const EdgeInsets.all(24),
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.center,
                                        mainAxisAlignment: MainAxisAlignment.center,
                                        children: [
                                          Text(
                                            event.eventName,
                                            style: const TextStyle(
                                              color: Colors.white,
                                              fontWeight: FontWeight.bold,
                                              fontSize: 22,
                                              shadows: [
                                                Shadow(
                                                    offset: Offset(0, 2),
                                                    blurRadius: 6,
                                                    color: Colors.black38)
                                              ],
                                            ),
                                            textAlign: TextAlign.center,
                                          ),
                                          const SizedBox(height: 10),
                                          Text(
                                            DateFormat('dd MMM yyyy, hh:mm a')
                                                .format(event.start),
                                            style: const TextStyle(
                                              color: Colors.white,
                                              fontSize: 16,
                                              shadows: [
                                                Shadow(
                                                    offset: Offset(0, 1),
                                                    blurRadius: 5,
                                                    color: Colors.black38)
                                              ],
                                            ),
                                          ),
                                          const SizedBox(height: 10),
                                          Text(
                                            "Organized by: ${event.organizer}",
                                            style: const TextStyle(
                                              color: Colors.white,
                                              fontSize: 15,
                                              fontWeight: FontWeight.w500,
                                              shadows: [
                                                Shadow(
                                                    offset: Offset(0, 1),
                                                    blurRadius: 5,
                                                    color: Colors.black45)
                                              ],
                                            ),
                                            textAlign: TextAlign.center,
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
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      );
    }

    // Profile view with back button
    if (showProfile) {
      return Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // IconButton(
              //   icon: const Icon(Icons.arrow_back, color: Colors.black87),
              //   onPressed: () => setState(() => showProfile = false),
              // ),
              // const SizedBox(width: 6),
              Text(
                "Profile",
                textAlign: TextAlign.center,
                style: GoogleFonts.poppins(
                  color: Colors.black87,
                  fontWeight: FontWeight.w600,
                  fontSize: 20,
                ),
              ),
            ],
          ),
          Expanded(child: ProfileScreenMobile(userRole: widget.userRole,onOpenConversation: _openDirectMessageTab,)),
        ],
      );
    }

    if (showMessages) {
      return Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // IconButton(
              //   icon: const Icon(Icons.arrow_back, color: Colors.black87),
              //   onPressed: () => setState(() => showProfile = false),
              // ),
              // const SizedBox(width: 6),
              Text(
                "Messages",
                textAlign: TextAlign.center,
                style: GoogleFonts.poppins(
                  color: Colors.black87,
                  fontWeight: FontWeight.w600,
                  fontSize: 20,
                ),
              ),
            ],
          ),
          Expanded(child: UserMessageSection(onprofileTap: _openProfile,)),
        ],
      );
    }

    if (showCommunity) {
      return Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // IconButton(
              //   icon: const Icon(Icons.arrow_back, color: Colors.black87),
              //   onPressed: () => setState(() => showProfile = false),
              // ),
              // const SizedBox(width: 6),
              // Text(
              //   "Channels",
              //   textAlign: TextAlign.center,
              //   style: GoogleFonts.poppins(
              //     color: Colors.black87,
              //     fontWeight: FontWeight.w600,
              //     fontSize: 20,
              //   ),
              // ),
            ],
          ),
          Expanded(child: ChannelsPage(onChannelTap: _openChannel,userRole: "Student",)),
        ],
      );
    }

    if (showContent) {
      void onBookTap(dynamic Book) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => BookDetailPageMobile(book: Book),
          ),
        );
      }

      void onpodcastTap(Map<String, dynamic> episode) {
       final podcastState = LibsynPodcastPlayerState();
       Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) =>  LibsynPodcastPlayerController(
              playerState: podcastState,
              child: LibsynPodcastPlayerScreen(
                episode: episode,
                playerState: podcastState,
                onExplicitCloseTab: () async {
                  await podcastState.player.stop();
                  podcastState.disposeController();
                },
                onSwitchEpisode: onpodcastTap,
              ),
            ),
            // podcastPlayerState: podcastState,
          )
        );
      }
      
      void onVideoTap(String videoId) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => VideoPlayerScreen(videoId: videoId),
          ),
        );
      }

      void onRT(Map<String, dynamic> post) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ResearchDetailPage(post: post,),
          ),
        );
      }


      return Column(
        children: [
          Expanded(child: ContentScreenMobile(onBookTap: onBookTap,onPodcastTap: onpodcastTap,onVideoTap: onVideoTap,onResearchTap: onRT,)),
        ],
      );
    }



    // Option data
    final List<_OptionCardData> options = [
      _OptionCardData("Finance", Icons.account_balance_wallet, () {
        setState(() {
          showFinance = true;
          showEvents = false;
          showProfile = false;
          showMessages = false;
          showCommunity = false;
          showContent = false;
        });
      }),
      _OptionCardData("Messages", Icons.message, () {
        setState(() {
          showEvents = false;
          showProfile = false;
          showMessages = true;
          showCommunity = false;
        });
      }),
      _OptionCardData("Community", Icons.people_alt, () {
        setState(() {
          showEvents = false;
          showProfile = false;
          showMessages = false;
          showCommunity = true;
          showContent = false;
        });
      }),
      _OptionCardData("My Events", Icons.event, () {
        setState(() {
          showEvents = true;
          showProfile = false;
          showMessages = false;
          showCommunity = false;
          showContent = false;
        });
      }),
      _OptionCardData("Content Section", Icons.insert_drive_file, () {
        setState(() {
          showEvents = false;
          showProfile = false;
          showMessages = false;
          showCommunity = false;
          showContent = true;
        });
      }),
    ];

    final List<_OptionCardData> optionsBrand = [
      _OptionCardData("Messages", Icons.message, () {
        setState(() {
          showEvents = false;
          showProfile = false;
          showMessages = true;
          showCommunity = false;
        });
      }),
      _OptionCardData("Community", Icons.people_alt, () {
        setState(() {
          showEvents = false;
          showProfile = false;
          showMessages = false;
          showCommunity = true;
          showContent = false;
        });
      }),
      _OptionCardData("My Events", Icons.event, () {
        setState(() {
          showEvents = true;
          showProfile = false;
          showMessages = false;
          showCommunity = false;
          showContent = false;
        });
      })
    ];

    // Main Screen
    return Scaffold(
      backgroundColor: const Color(0xFFF3F3F3),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.only(top: 24, left: 16, right: 16, bottom: 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const SizedBox(height: 12),
              // User Avatar Section
              CircleAvatar(
                radius: 36,
                backgroundColor: Colors.purple,
                child: Text(
                  widget.userRole.isNotEmpty
                      ? widget.userRole[0].toUpperCase()
                      : "",
                  style: GoogleFonts.poppins(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 34),
                ),
              ),
              const SizedBox(height: 18),

              /// User details
              Text(
                widget.userId,
                textAlign: TextAlign.center,
                style: GoogleFonts.poppins(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                widget.userRole,
                textAlign: TextAlign.center,
                style: GoogleFonts.poppins(
                  fontSize: 16,
                  color: Colors.black54,
                  fontWeight: FontWeight.w500,
                ),
              ),

              // const Padding(
              //   padding: EdgeInsets.symmetric(vertical: 6),
              //   child: Icon(Icons.keyboard_arrow_down, color: Colors.black54),
              // ),

              // Manage profile option
              TextButton(
                onPressed: () {
                  setState(() {
                    showProfile = true;
                    showEvents = false;
                  });
                },
                child: Text(
                  "Manage profile",
                  style: GoogleFonts.poppins(
                    color: Colors.purple,
                    fontWeight: FontWeight.w600,
                    fontSize: 17,
                  ),
                ),
              ),
              const Divider(height: 34),

              // Options grid
              GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount:widget.userRole == "Student" ? options.length :optionsBrand.length,
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  mainAxisSpacing: 24,
                  crossAxisSpacing: 18,
                  childAspectRatio: 1.17,
                ),
                itemBuilder: (context, idx) {
                  final data = widget.userRole == "Student" ? options[idx] : optionsBrand[idx];
                  return _OptionCard(
                    label: data.label,
                    icon: data.icon,
                    onTap: data.onTap,
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _OptionCardData {
  final String label;
  final IconData icon;
  final VoidCallback onTap;
  _OptionCardData(this.label, this.icon, this.onTap);
}

class _OptionCard extends StatelessWidget {
  final String label;
  final IconData icon;
  final VoidCallback onTap;
  const _OptionCard({
    required this.label,
    required this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Card(
        elevation: 0.5,
        color: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 32, color: Colors.grey[700]),
              const SizedBox(height: 14),
              Text(
                label,
                style: GoogleFonts.poppins(
                  fontSize: 15,
                  color: Colors.grey[900],
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
