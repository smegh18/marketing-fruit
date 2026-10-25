import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

class UsersList extends StatefulWidget {
  final void Function(String userName, Map<dynamic, dynamic> locationHistory)? onLocationTab;
  final void Function(String studentName, String studentId)? onStudentTab;
  final void Function(String guardianName, String guardianEmail)? onGuardianTab;
  final void Function(String schoolName, String schoolId)? onSchoolTab;
  final String? initialRole;
  final String userRole;

  const UsersList({
    super.key,
    this.onLocationTab,
    this.onStudentTab,
    this.onGuardianTab,
    this.onSchoolTab,
    this.initialRole,
    required this.userRole,
  });

  @override
  State<UsersList> createState() => _UsersListState();
}

class _UsersListState extends State<UsersList> {
  late String selectedTab;
  List<Map<String, dynamic>> userList = [];
  bool isLoading = true;
  Map<String, String> lastLogins = {};
  String searchQuery = '';

  @override
  void initState() {
    super.initState();
    selectedTab = widget.initialRole ?? "All";
    _fetchUsers();
  }

  Future<void> _fetchUsers() async {
    final dbRef = FirebaseDatabase.instance.ref();
    final snapshot = await dbRef.get();

    Map<String, dynamic> allUsers = {};
    if (snapshot.exists) {
      final data = Map<String, dynamic>.from(snapshot.value as Map);
      if (data.containsKey('users')) {
        allUsers = Map<String, dynamic>.from(data['users']);
      } else {
        allUsers = data;
      }
    }

    final List<Map<String, dynamic>> loadedUsers = [];
    allUsers.forEach((uid, udata) {
      if (udata is Map) {
        final user = Map<String, dynamic>.from(udata);
        user['id'] = uid;
        loadedUsers.add(user);
      }
    });

    // Filter out brand users when userRole is 'Brand'
    List<Map<String, dynamic>> filteredUsers = loadedUsers;
    if (widget.userRole.trim().toLowerCase() == 'brand') {
      filteredUsers = loadedUsers
          .where((user) =>
      getUserRole(user).toLowerCase() != 'brand')
          .toList();
    }

    setState(() {
      userList = filteredUsers;
      isLoading = false;
    });

    await _fetchLastLogins(filteredUsers.map((u) => u['email'] as String?).whereType<String>().toList());
  }

  Future<void> _fetchLastLogins(List<String> emails) async {
    final currentUser = FirebaseAuth.instance.currentUser;
    Map<String, String> loginMap = {};
    if (currentUser != null && emails.contains(currentUser.email)) {
      final lastSignIn = currentUser.metadata.lastSignInTime;
      if (lastSignIn != null) {
        if (currentUser.email != null) loginMap[currentUser.email!] = lastSignIn.toString();
      }
    }
    setState(() {
      lastLogins = loginMap;
    });
  }

  String getUserRole(Map<String, dynamic> user) {
    final role = (user['role'] ?? '').toString().toLowerCase();
    if (role.isNotEmpty) return _capitalize(role);
    if (user.containsKey('school')) return 'School';
    if (user.containsKey('brand')) return 'Brand';
    if (user.containsKey('children')) return 'Guardian';
    return 'Student';
  }

  String getUserDetails(Map<String, dynamic> user) {
    final role = getUserRole(user);

    if (role == 'Student') {
      final playerDetails = user['playerDetails'];
      if (playerDetails is Map && playerDetails['arc'] != null) {
        return playerDetails['arc'].toString();
      }
      return user['state'] ?? user['industry'] ?? '';
    }
    if (role == 'School') {
      return user['school'] ?? '';
    }
    if (role == 'Brand') {
      if (user['brand'] is Map) {
        return (user['brand']['name'] ?? '').toString();
      }
      return user['brand']?.toString() ?? '';
    }
    if (role == 'Guardian') {
      final children = user['children'];
      if (children is Map) {
        final db = {for (final u in userList) u['id']: u};
        final names = <String>[];
        for (final cid in children.keys) {
          final childUser = db[cid];
          if (childUser != null) {
            final name = _fullName(childUser);
            names.add(name);
          }
        }
        return names.join(', ');
      }
      return '';
    }
    return '';
  }

  String _fullName(Map<String, dynamic> user) {
    final first = user['first_name'] ?? user['firstName'] ?? '';
    final last = user['last_name'] ?? user['lastName'] ?? '';
    if (first.isNotEmpty && last.isNotEmpty) return "$first $last";
    if (first.isNotEmpty) return first;
    if (last.isNotEmpty) return last;
    return user['name'] ?? '';
  }

  String getUserName(Map<String, dynamic> user) => _fullName(user);
  String getUserEmail(Map<String, dynamic> user) => (user['email'] ?? '').toString();

  String getLastLogin(Map<String, dynamic> user) {
    final email = user['email'];
    if (email is String && lastLogins.containsKey(email)) {
      return lastLogins[email]!;
    }
    final dbLogin = user['last_login'];
    if (dbLogin is int || dbLogin is String) {
      return formatTimestamp(dbLogin);
    }
    return '';
  }

  String formatTimestamp(dynamic millis) {
    if (millis == null) return '';
    if (millis is int) {
      final dt = DateTime.fromMillisecondsSinceEpoch(millis);
      return "${dt.year}-${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')} "
          "${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}";
    }
    if (millis is String) {
      final parsed = int.tryParse(millis);
      if (parsed != null) return formatTimestamp(parsed);
      DateTime? dt;
      try {
        dt = DateTime.parse(millis);
      } catch (_) {}
      if (dt != null) {
        return "${dt.year}-${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')} "
            "${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}";
      }
    }
    return '';
  }

  Widget getLocationCell(BuildContext context, Map<String, dynamic> user) {
    final locationHistory = user['location history'];
    if (locationHistory == null) {
      return const Icon(Icons.location_off, color: Colors.grey, size: 22);
    }
    return IconButton(
      icon: const Icon(Icons.location_on, color: Colors.blue, size: 22),
      tooltip: "Show location information",
      onPressed: () {
        if (widget.onLocationTab != null) {
          widget.onLocationTab!(getUserName(user), locationHistory);
        }
      },
    );
  }

  String _capitalize(String text) {
    if (text.isEmpty) return text;
    return text[0].toUpperCase() + text.substring(1).toLowerCase();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final roles = widget.userRole.toLowerCase() == 'admin'
        ? ['All', 'Student', 'Guardian', 'School', 'Brand']
        : ['All', 'Student', 'Guardian', 'School'];
    final filtered = selectedTab == 'All'
        ? userList
        : userList.where((u) => getUserRole(u).toLowerCase() == selectedTab.toLowerCase()).toList();

    List<Map<String, dynamic>> displayList = filtered.where((user) {
      if (searchQuery.trim().isEmpty) return true;
      final name = getUserName(user).toLowerCase();
      final email = getUserEmail(user).toLowerCase();
      return name.contains(searchQuery.toLowerCase()) ||
          email.contains(searchQuery.toLowerCase());
    }).toList();

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: theme.cardColor,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  spreadRadius: 1,
                  blurRadius: 2,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                SizedBox(
                  width: kIsWeb ? 350 : 300,
                  child: TextField(
                    decoration: const InputDecoration(
                      hintText: "Search",
                      prefixIcon: Icon(Icons.search),
                      border: OutlineInputBorder(),
                      isDense: true,
                      contentPadding: EdgeInsets.symmetric(vertical: 10, horizontal: 14),
                    ),
                    onChanged: (val) => setState(() => searchQuery = val),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 30),
          Container(
            padding: const EdgeInsets.all(16),
            width: double.infinity,
            decoration: BoxDecoration(
              color: theme.cardColor,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  spreadRadius: 1,
                  blurRadius: 2,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Users",
                  style: GoogleFonts.poppins(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 16),
                Wrap(
                  spacing: 10,
                  children: roles.map((role) =>
                      FilterChip(
                        label: Text(role),
                        selected: selectedTab == role,
                        onSelected: (_) => setState(() => selectedTab = role),
                      )
                  ).toList(),
                ),
                const SizedBox(height: 20),
                isLoading
                    ? const SizedBox(
                    height: 100,
                    child: Center(child: CircularProgressIndicator()))
                    : ConstrainedBox(
                  constraints: const BoxConstraints(minHeight: 300.0),
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      return Scrollbar(
                        thumbVisibility: true,
                        child: SingleChildScrollView(
                          scrollDirection: Axis.vertical,
                          child: SingleChildScrollView(
                            scrollDirection: Axis.horizontal,
                            child: ConstrainedBox(
                              constraints: BoxConstraints(minWidth: constraints.maxWidth),
                              child: DataTable(
                                columnSpacing: 24,
                                columns: widget.userRole.toLowerCase() == 'admin' ? const [
                                  DataColumn(label: Text("Name"),headingRowAlignment: MainAxisAlignment.center),
                                  DataColumn(label: Text("Email"),headingRowAlignment: MainAxisAlignment.center),
                                  DataColumn(label: Text("Role"),headingRowAlignment: MainAxisAlignment.center),
                                  DataColumn(label: Text("Last login"),headingRowAlignment: MainAxisAlignment.center),
                                  DataColumn(label: Text("Details"),headingRowAlignment: MainAxisAlignment.center),
                                  DataColumn(label: Text("Location"),headingRowAlignment: MainAxisAlignment.center),
                                  DataColumn(label: Text("Active"),headingRowAlignment: MainAxisAlignment.center),
                                ] : const [
                                  DataColumn(label: Text("Name"),headingRowAlignment: MainAxisAlignment.center),
                                  DataColumn(label: Text("Role"),headingRowAlignment: MainAxisAlignment.center),
                                  DataColumn(label: Text("Details"),headingRowAlignment: MainAxisAlignment.center),
                                ],
                                rows: displayList.map((user) {
                                  final role = getUserRole(user).toLowerCase();
                                  final userName = getUserName(user);
                                  final userId = user['id']?.toString() ?? '';
                                  Widget nameCell = _avatarNameCell(userName);

                                  if (role == 'student' && widget.onStudentTab != null) {
                                    nameCell = MouseRegion(
                                      cursor: SystemMouseCursors.click,
                                      child: GestureDetector(
                                        onTap: () =>
                                            widget.onStudentTab!(userName, userId),
                                        child: nameCell,
                                      ),
                                    );
                                  } else if (role == 'guardian' &&
                                      widget.onGuardianTab != null) {
                                    final guardianEmail = user['email']?.toString() ?? '';
                                    nameCell = MouseRegion(
                                      cursor: SystemMouseCursors.click,
                                      child: GestureDetector(
                                        onTap: () => widget
                                            .onGuardianTab!(userName, guardianEmail),
                                        child: nameCell,
                                      ),
                                    );
                                  } else if (role == 'school' &&
                                      widget.onSchoolTab != null) {
                                    nameCell = MouseRegion(
                                      cursor: SystemMouseCursors.click,
                                      child: GestureDetector(
                                        onTap: () =>
                                            widget.onSchoolTab!(userName, userId),
                                        child: nameCell,
                                      ),
                                    );
                                  }

                                  return widget.userRole.toLowerCase() == 'admin' ? DataRow(cells: [
                                    DataCell(Center(child: nameCell)),
                                    DataCell(Center(child: Text(getUserEmail(user)))),
                                    DataCell(Center(child: Text(getUserRole(user)))),
                                    DataCell(Center(child: Text(getLastLogin(user)))),
                                    DataCell(Center(child: Text(getUserDetails(user)))),
                                    DataCell(Center(child: getLocationCell(context, user))),
                                    DataCell(Center(
                                      child: Switch(
                                        value: user['active'] == true,
                                        onChanged: (val) {
                                          FirebaseDatabase.instance
                                              .ref('users/${user['id']}/active')
                                              .set(val);
                                          setState(() {
                                            user['active'] = val;
                                          });
                                        },
                                      ),
                                    )),
                                  ]): DataRow(cells: [
                                    DataCell(Center(child: nameCell)),
                                    DataCell(Center(child: Text(getUserRole(user)))),
                                    DataCell(Center(child: Text(getUserDetails(user)))),
                                  ]);
                                }).toList(),
                              ),
                            ),
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
    );
  }

  Widget _avatarNameCell(String name) => Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      Text(
        name,
        style: TextStyle(
          fontWeight: FontWeight.w600,
          fontSize: 14,
          color: Colors.blue.shade300,
          decoration: TextDecoration.underline,
        ),
      ),
    ],
  );
}

/// --- Location Information TAB ---
class LocationInformationTab extends StatelessWidget {
  final String userName;
  final Map<dynamic, dynamic> history;
  const LocationInformationTab({super.key, required this.userName, required this.history});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final hintColor = theme.hintColor;
    final entries = _extractAllLocationEntries(history);

    return Container(
      width: double.infinity,
      height: double.infinity,
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.5),
            spreadRadius: 2,
            blurRadius: 5,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Top row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                "Location Information - $userName",
                style: theme.textTheme.titleMedium?.copyWith(
                  color: hintColor,
                  fontWeight: FontWeight.bold,
                  fontSize: 20,
                ),
              ),
              IconButton(
                tooltip: "Show all location points on map",
                icon: Icon(Icons.map, color: hintColor, size: 26),
                onPressed: () {
                  if (entries.isNotEmpty) {
                    _showAllLocationsPopup(context, entries);
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text("No location history available"))
                    );
                  }
                },
              ),
            ],
          ),
          const SizedBox(height: 20),
          Expanded(
            child: entries.isEmpty
                ? Center(child: Text('No Location History Found.', style: TextStyle(color: hintColor)))
                : LayoutBuilder(
              builder: (context, constraints) {
                return Scrollbar(
                  thumbVisibility: true,
                  child: SingleChildScrollView(
                    scrollDirection: Axis.vertical,
                    child: SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: ConstrainedBox(
                        constraints: BoxConstraints(minWidth: constraints.maxWidth),
                        child: DataTable(
                          headingRowColor: WidgetStateProperty.resolveWith(
                                  (states) => hintColor.withAlpha(8)),
                          columns: [
                            DataColumn(label: Text('Date', style: TextStyle(color: hintColor))),
                            DataColumn(label: Text('Time', style: TextStyle(color: hintColor))),
                            DataColumn(label: Text('Latitude', style: TextStyle(color: hintColor))),
                            DataColumn(label: Text('Longitude', style: TextStyle(color: hintColor))),
                            DataColumn(label: Text('Type', style: TextStyle(color: hintColor))),
                            DataColumn(label: Text('Map', style: TextStyle(color: hintColor))),
                          ],
                          rows: entries.map((entry) {
                            return DataRow(
                              cells: [
                                DataCell(Text(entry['date'] ?? '', style: TextStyle(color: hintColor))),
                                DataCell(Text(entry['time'] ?? '', style: TextStyle(color: hintColor))),
                                DataCell(Text(entry['latitude']?.toString() ?? '', style: TextStyle(color: hintColor))),
                                DataCell(Text(entry['longitude']?.toString() ?? '', style: TextStyle(color: hintColor))),
                                DataCell(Text(entry['type'] ?? '', style: TextStyle(color: hintColor))),
                                DataCell(IconButton(
                                  icon: Icon(Icons.map, color: hintColor, size: 22),
                                  onPressed: () {
                                    _showLocationPopup(context, entry['latitude'], entry['longitude']);
                                  },
                                )),
                              ],
                            );
                          }).toList(),
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  /// Flattens 'Accurate Location' and 'Approx Location' to one list
  static List<Map<String, dynamic>> _extractAllLocationEntries(Map<dynamic, dynamic> history) {
    final entries = <Map<String, dynamic>>[];

    void addEntries(Map<String, dynamic> node, String type) {
      for (final dateKey in node.keys) {
        final timeMap = Map<String, dynamic>.from(node[dateKey]);
        for (final timeKey in timeMap.keys) {
          final data = Map<String, dynamic>.from(timeMap[timeKey]);
          entries.add({
            'date': dateKey,
            'time': timeKey,
            'latitude': data['latitude'],
            'longitude': data['longitude'],
            'type': type,
          });
        }
      }
    }

    if (history['Accurate Location'] != null) {
      addEntries(Map<String, dynamic>.from(history['Accurate Location']), 'Accurate');
    }
    if (history['Approx Location'] != null) {
      addEntries(Map<String, dynamic>.from(history['Approx Location']), 'Approx');
    }

    // Sort by date/time descending
    entries.sort((a, b) {
      final dateCmp = (b['date'] ?? '').compareTo(a['date'] ?? '');
      if (dateCmp != 0) return dateCmp;
      return (b['time'] ?? '').compareTo(a['time'] ?? '');
    });
    return entries;
  }

  static void _showLocationPopup(BuildContext context, dynamic latRaw, dynamic lngRaw) {
    final lat = double.tryParse(latRaw.toString());
    final lng = double.tryParse(lngRaw.toString());

    if (lat == null || lng == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Invalid lat/lng')));
      return;
    }

    final marker = Marker(
      markerId: const MarkerId('selected_location'),
      position: LatLng(lat, lng),
    );
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Location on Map"),
        content: SizedBox(
          height: 350,
          width: 400,
          child: GoogleMap(
            initialCameraPosition: CameraPosition(
              target: LatLng(lat, lng),
              zoom: 18,
            ),
            markers: {marker},
            zoomControlsEnabled: false,
            myLocationButtonEnabled: false,
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.of(ctx).pop(), child: const Text("Close")),
        ],
      ),
    );
  }

  static void _showAllLocationsPopup(BuildContext context, List<Map<String, dynamic>> entries) {
    final markers = <Marker>[];
    for (int idx = 0; idx < entries.length; idx++) {
      final entry = entries[idx];
      final lat = double.tryParse(entry['latitude'].toString());
      final lng = double.tryParse(entry['longitude'].toString());
      if (lat != null && lng != null) {
        markers.add(Marker(
          markerId: MarkerId('marker$idx'),
          position: LatLng(lat, lng),
          infoWindow: InfoWindow(
            title: "${entry['date']} ${entry['time']} (${entry['type']})",
          ),
          icon: entry['type'] == "Accurate"
              ? BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed)
              : BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueBlue),
        ));
      }
    }

    LatLng initial;
    if (markers.isNotEmpty) {
      initial = markers.first.position;
    } else {
      initial = const LatLng(20.5937, 78.9629); // India center
    }

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("All Locations Map"),
        content: SizedBox(
          height: MediaQuery.of(context).size.height * 0.6,
          width: MediaQuery.of(context).size.width * 0.6,
          child: GoogleMap(
            initialCameraPosition: CameraPosition(
              target: initial,
              zoom: markers.length > 1 ? 8 : 15,
            ),
            markers: markers.toSet(),
            zoomControlsEnabled: false,
            myLocationButtonEnabled: false,
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.of(ctx).pop(), child: const Text("Close")),
        ],
      ),
    );
  }
}
