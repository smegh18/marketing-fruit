import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import 'channel_chat_associates_info.dart';

class ChannelProfileInfoSection extends StatefulWidget {
  final String channelId;
  final String userId;
  final String role; // 'Student', 'Guardian', 'Brand', 'School', 'Admin'
  const ChannelProfileInfoSection({
    super.key,
    required this.channelId,
    required this.userId,
    required this.role,
  });

  @override
  State<ChannelProfileInfoSection> createState() => _ChannelProfileInfoSectionState();
}

class _ChannelProfileInfoSectionState extends State<ChannelProfileInfoSection> {
  String? expandedUserId;
  String? expandedRole;

  // ---- Data fetch helpers ---------------------------------------------------

  Future<Map<String, dynamic>?> _fetchProfileFromChannel() async {
    final ref = FirebaseDatabase.instance
        .ref('channels/${widget.channelId}/members/${widget.role}/${widget.userId}');
    final snap = await ref.get();
    if (!snap.exists || snap.value == null) return null;
    final map = Map<dynamic, dynamic>.from(snap.value as Map);
    return map.map((k, v) => MapEntry(k.toString(), v));
  }

  Future<Map<String, dynamic>?> _fetchProfileFromUsers() async {
    final ref = FirebaseDatabase.instance.ref('users/${widget.userId}');
    final snap = await ref.get();
    if (!snap.exists || snap.value == null) return null;
    final map = Map<dynamic, dynamic>.from(snap.value as Map);
    return map.map((k, v) => MapEntry(k.toString(), v));
  }

  // Lightweight fetch for an arbitrary user (used by associates list)
  Future<Map<String, dynamic>?> _fetchUserById(String uid) async {
    if (uid.isEmpty) return null;
    final ref = FirebaseDatabase.instance.ref('users/$uid');
    final snap = await ref.get();
    if (!snap.exists || snap.value == null) return null;
    final map = Map<dynamic, dynamic>.from(snap.value as Map);
    return map.map((k, v) => MapEntry(k.toString(), v));
  }

  /// Build "associates" list based on the primary user's role.
  Future<List<Map<String, String>>> _fetchAssociationWidgets(Map<String, dynamic>? userMap) async {
    final List<Map<String, String>> associates = [];
    if (userMap == null) return [];

    final db = FirebaseDatabase.instance.ref();
    final usersSnap = await db.child('users').get();
    final users = usersSnap.exists && usersSnap.value is Map
        ? Map<String, dynamic>.from(usersSnap.value as Map)
        : <String, dynamic>{};

    final role = (widget.role).toString();

    // Student: show their School and Guardian
    if (role == 'Student') {
      final String? school = userMap['school']?.toString();
      final String? guardianEmail = userMap['guardian_email']?.toString();

      if (school != null && school.isNotEmpty) {
        bool foundSchool = false;
        for (var entry in users.entries) {
          final u = Map<String, dynamic>.from(entry.value);
          if (u['role'] == 'School' &&
              (u['school']?.toString() == school || u['first_name']?.toString() == school)) {
            associates.add({
              'type': 'School',
              'name': u['school']?.toString() ?? u['first_name']?.toString() ?? school,
              'email': u['email']?.toString() ?? '',
              'userId': entry.key,
            });
            foundSchool = true;
          }
        }
        if (!foundSchool) {
          associates.add({'type': 'School', 'name': school, 'email': '', 'userId': ''});
        }
      }

      if (guardianEmail != null && guardianEmail.isNotEmpty) {
        for (var entry in users.entries) {
          final u = Map<String, dynamic>.from(entry.value);
          if (u['role'] == 'Guardian' && (u['email']?.toString() == guardianEmail)) {
            associates.add({
              'type': 'Guardian',
              'name': '${u['first_name'] ?? ''} ${u['last_name'] ?? ''}'.trim(),
              'email': u['email'] ?? '',
              'userId': entry.key,
            });
            break;
          }
        }
      }
    }
    // Guardian: show all their students (children)
    else if (role == 'Guardian') {
      final myEmail = userMap['email']?.toString();
      if (myEmail != null) {
        for (var entry in users.entries) {
          final u = Map<String, dynamic>.from(entry.value);
          if (u['role'] == 'Student' && u['guardian_email']?.toString() == myEmail) {
            associates.add({
              'type': 'Student',
              'name': '${u['first_name'] ?? ''} ${u['last_name'] ?? ''}'.trim(),
              'email': u['email'] ?? '',
              'userId': entry.key,
            });
          }
        }
      }
    }
    // School: show all students with this school
    else if (role == 'School') {
      final schoolName = userMap['school']?.toString() ?? userMap['first_name']?.toString();
      if (schoolName != null && schoolName.isNotEmpty) {
        for (var entry in users.entries) {
          final u = Map<String, dynamic>.from(entry.value);
          if (u['role'] == 'Student' && u['school']?.toString() == schoolName) {
            associates.add({
              'type': 'Student',
              'name': '${u['first_name'] ?? ''} ${u['last_name'] ?? ''}'.trim(),
              'email': u['email'] ?? '',
              'userId': entry.key,
            });
          }
        }
      }
    }
    // Brand/Admin: no default associations logic added here; extend if needed.
    return associates;
  }

  // ---- Avatar helpers -------------------------------------------------------

  String? _extractPhotoUrl(Map<String, dynamic>? user) {
    if (user == null) return null;
    final candidates = [
      user['photoUrl'],
      user['photo_url'],
      user['profile_pic'],
      user['profile_photo'],
      user['image'],
      user['avatar'],
    ];
    for (final c in candidates) {
      final s = c?.toString().trim();
      if (s != null && s.isNotEmpty) return _resolveImage(s);
    }
    return null;
  }

  String _roleInitial(String role) {
    switch (role) {
      case 'Admin':
        return 'A';
      case 'Brand':
        return 'B';
      case 'Guardian':
        return 'G';
      case 'School':
        return 'S';
      default:
        return role.isNotEmpty ? role[0].toUpperCase() : '?';
    }
  }

  Color _roleColor(String role) {
    switch (role) {
      case 'Admin':
        return Colors.redAccent;
      case 'Brand':
        return Colors.purple;
      case 'Guardian':
        return Colors.amber.shade700;
      case 'School':
        return Colors.blue;
      case 'Student':
        return Colors.green;
      default:
        return Colors.grey;
    }
  }

  /// Main avatar (header): Students -> photo (if any). Others -> A/B/G/S letter.
  Widget _buildMainAvatar({
    required String role,
    required String displayName,
    required Map<String, dynamic>? userData,
    double radius = 40,
  }) {
    if (role == 'Student') {
      final photo = _extractPhotoUrl(userData);
      if (photo != null && photo.isNotEmpty) {
        return CircleAvatar(
          radius: radius,
          backgroundColor: _roleColor(role),
          backgroundImage: NetworkImage(photo),
          onBackgroundImageError: (_, __) {},
          child: const SizedBox(), // ensures no letter overlays the photo
        );
      }
      // If photo missing/fails, fallback to letter of name's first char
      final letter = displayName.isNotEmpty ? displayName[0].toUpperCase() : 'S';
      return CircleAvatar(
        radius: radius,
        backgroundColor: _roleColor(role),
        child: Text(letter, style: const TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.w700)),
      );
    }

    // Non-students: show role initial only
    final initial = _roleInitial(role);
    return CircleAvatar(
      radius: radius,
      backgroundColor: _roleColor(role),
      child: Text(initial, style: const TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.w700)),
    );
  }

  /// Associate avatar: Students -> try photo via userId; others -> A/B/G/S
  Widget _buildAssociateAvatar({
    required String associateRole,
    required String name,
    required String userId,
  }) {
    if (associateRole == 'Student' && userId.isNotEmpty) {
      // Load photo lazily
      return FutureBuilder<Map<String, dynamic>?>(
        future: _fetchUserById(userId),
        builder: (context, snap) {
          final map = snap.data;
          final photo = _extractPhotoUrl(map);
          if (photo != null && photo.isNotEmpty) {
            return CircleAvatar(
              radius: 25,
              backgroundColor: _roleColor('Student'),
              backgroundImage: NetworkImage(photo),
              onBackgroundImageError: (_, __) {},
              child: const SizedBox(),
            );
          }
          final letter = name.isNotEmpty ? name[0].toUpperCase() : 'S';
          return CircleAvatar(
            radius: 25,
            backgroundColor: _roleColor('Student'),
            child: Text(letter, style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w700)),
          );
        },
      );
    }

    // Non-students
    final initial = _roleInitial(associateRole);
    return CircleAvatar(
      radius: 25,
      backgroundColor: _roleColor(associateRole),
      child: Text(initial, style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w700)),
    );
  }

  String _displayName(Map<String, dynamic> data) {
    final first = (data['first_name'] ?? data['name'] ?? '').toString().trim();
    final last = (data['last_name'] ?? '').toString().trim();
    final combined = ((first.isNotEmpty ? first : '') + (last.isNotEmpty ? ' $last' : '')).trim();
    return combined.isNotEmpty ? combined : 'Unknown';
  }

  // Resolve ipfs:// -> https gateway, otherwise return as-is
  String _resolveImage(String path) {
    if (path.startsWith('ipfs://')) {
      final hash = path.substring(7);
      return 'https://gateway.pinata.cloud/ipfs/$hash';
    }
    return path;
  }

  // ---- UI -------------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    final double screenWidth = MediaQuery.of(context).size.width;
    final double containerWidth = screenWidth * 0.90;

    return FutureBuilder<Map<String, dynamic>?>(
      future: _fetchProfileFromUsers().then((userMap) async {
        if (userMap != null) return userMap;
        return await _fetchProfileFromChannel();
      }),
      builder: (context, snapshot) {
        final Map<String, dynamic> data = (snapshot.data ?? {});
        final role = (data['role']?.toString() ?? widget.role);
        final name = _displayName(data);

        return Center(
          child: Container(
            width: containerWidth,
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                IconButton(
                  icon: const Icon(Icons.arrow_back),
                  onPressed: () => Navigator.pop(context),
                ),
                const SizedBox(height: 12),

                // Header avatar + name + role
                Center(
                  child: Column(
                    children: [
                      _buildMainAvatar(role: role, displayName: name, userData: data, radius: 40),
                      const SizedBox(height: 12),
                      Text(
                        name,
                        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      Text(
                        role,
                        style: const TextStyle(color: Colors.grey),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 24),

                // Quick actions (wire up later)
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _buildActionButton(Icons.remove_circle_outline, 'Remove'),
                    _buildActionButton(Icons.block, 'Restrict'),
                    _buildActionButton(Icons.call, 'Call'),
                    _buildActionButton(Icons.email, 'Email'),
                  ],
                ),

                const SizedBox(height: 30),

                // Basic fields
                _buildInfoRow('Email', (data['email'] ?? '').toString()),
                _buildInfoRow('UserId', (data['userId'] ?? widget.userId).toString()),
                _buildInfoRow('Description', (data['bio'] ?? data['description'] ?? 'N/A').toString()),
                _buildInfoRow('Contact', (data['contact'] ?? data['mobile'] ?? 'N/A').toString()),

                const SizedBox(height: 30),

                const Text('Associated with', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                const SizedBox(height: 12),

                FutureBuilder<List<Map<String, String>>>(
                  future: _fetchProfileFromUsers().then((userMap) => _fetchAssociationWidgets(userMap)),
                  builder: (context, snap) {
                    if (snap.connectionState == ConnectionState.waiting) {
                      return const Center(child: Padding(
                        padding: EdgeInsets.symmetric(vertical: 12),
                        child: CircularProgressIndicator(),
                      ));
                    }
                    final associates = snap.data ?? [];
                    if (associates.isEmpty) {
                      return const Text("No associations found");
                    }

                    final List<Widget> associateWidgets = [];
                    for (final a in associates) {
                      final aUserId = a['userId'] ?? '';
                      final aRole = a['type'] ?? '';
                      final aName = a['name'] ?? '';
                      final aEmail = a['email'] ?? '';

                      associateWidgets.add(
                        GestureDetector(
                          onTap: () {
                            if (aUserId.isNotEmpty) {
                              setState(() {
                                if (expandedUserId == aUserId && expandedRole == aRole) {
                                  expandedUserId = null;
                                  expandedRole = null;
                                } else {
                                  expandedUserId = aUserId;
                                  expandedRole = aRole;
                                }
                              });
                            }
                          },
                          child: Container(
                            margin: const EdgeInsets.symmetric(vertical: 6),
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: Colors.grey.shade100,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Row(
                              children: [
                                _buildAssociateAvatar(
                                  associateRole: aRole,
                                  name: aName,
                                  userId: aUserId,
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(aName,
                                          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                                      Text(aRole, style: const TextStyle(color: Colors.grey)),
                                      if (aEmail.isNotEmpty)
                                        Text(aEmail, style: const TextStyle(color: Colors.black45, fontSize: 12)),
                                    ],
                                  ),
                                ),
                                if (aUserId.isNotEmpty)
                                  Icon(
                                    expandedUserId == aUserId && expandedRole == aRole
                                        ? Icons.keyboard_arrow_up
                                        : Icons.keyboard_arrow_down,
                                    color: Colors.grey.shade600,
                                  ),
                              ],
                            ),
                          ),
                        ),
                      );

                      // Expanded nested profile for the associate
                      if (expandedUserId == aUserId && expandedRole == aRole) {
                        associateWidgets.add(
                          Padding(
                            padding: const EdgeInsets.only(bottom: 10, left: 12, right: 12),
                            child: ChannelAssociatesProfileSection(
                              channelId: widget.channelId,
                              schoolId: aUserId,           // original param name kept
                              associateRole: aRole,
                            ),
                          ),
                        );
                      }
                    }

                    return Column(children: associateWidgets);
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // ---- Small UI pieces ------------------------------------------------------

  Widget _buildActionButton(IconData icon, String label) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: Colors.grey.shade200,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: Colors.green),
        ),
        const SizedBox(height: 4),
        Text(label, textAlign: TextAlign.center),
      ],
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(label, style: const TextStyle(fontWeight: FontWeight.w500)),
          ),
          const SizedBox(width: 12),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }
}
