import 'dart:async';
import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_auth/firebase_auth.dart';           // ⬅️ added
import 'package:firebase_storage/firebase_storage.dart';     // ⬅️ added
import 'package:Marketing_Fruit/components/channel_chat_associates_info.dart';
import 'package:Marketing_Fruit/components/channel_chat_profile_info.dart';
import 'package:Marketing_Fruit/components/glasspopup.dart';

class ChannelInfoSection extends StatefulWidget {
  final String channelId;
  const ChannelInfoSection({super.key, required this.channelId});
  @override
  State<ChannelInfoSection> createState() => _ChannelInfoSectionState();
}

class _ChannelInfoSectionState extends State<ChannelInfoSection> {
  final TextEditingController searchController = TextEditingController();
  final DatabaseReference _db = FirebaseDatabase.instance.ref();
  String? _channelName;
  String? _description;
  String? _logoUrl;

  // Do not show Admin in suggestion dialog
  final List<String> roles = const ['Student', 'Guardian', 'Brand', 'School'];

  /// Each participant: { userId, name, email, role }
  List<Map<String, String>> _participants = [];
  Map<String, String>? _selectedParticipant;
  StreamSubscription<DatabaseEvent>? _channelSub;

  @override
  void initState() {
    super.initState();
    _attachChannelListener();
  }

  @override
  void dispose() {
    _channelSub?.cancel();
    searchController.dispose();
    super.dispose();
  }

  void _attachChannelListener() {
    final ref = _db.child('channels/${widget.channelId}');
    _channelSub = ref.onValue.listen((event) async {
      final value = event.snapshot.value;
      if (value == null || value is! Map) {
        setState(() {
          _channelName = widget.channelId;
          _description = null;
          _logoUrl = null;
          _participants = [];
          _selectedParticipant = null;
        });
        return;
      }
      final map = Map<Object?, Object?>.from(value);
      final name = map['name']?.toString();
      final desc = map['description']?.toString();
      final logo = map['logo']?.toString();

      final List<Map<String, String>> people = [];
      if (map['members'] is Map) {
        final members = Map<Object?, Object?>.from(map['members'] as Map);
        members.forEach((roleKey, usersValue) {
          final role = roleKey.toString();
          if (usersValue is Map) {
            final users = Map<Object?, Object?>.from(usersValue);
            users.forEach((userIdKey, userData) {
              final userId = userIdKey.toString();
              String name = '';
              String email = '';
              if (userData is Map) {
                final u = Map<Object?, Object?>.from(userData);
                name = u['name']?.toString() ?? '';
                email = u['email']?.toString() ?? '';
              }
              people.add({
                'userId': userId,
                'name': name,
                'email': email,
                'role': role,
              });
            });
          }
        });
      }

      // Sort by name
      people.sort((a, b) => (a['name'] ?? '').compareTo(b['name'] ?? ''));

      setState(() {
        _channelName = name ?? widget.channelId;
        _description = desc;
        _logoUrl = logo;
        _participants = people;

        if (_selectedParticipant != null) {
          final id = _selectedParticipant!['userId'];
          if (!_participants.any((p) => p['userId'] == id)) {
            _selectedParticipant = null;
          }
        }
      });
    });
  }

  // =========================
  // ADD PARTICIPANT (Glass)
  // =========================
  void _addParticipant() {
    String? selectedRole = roles.first;
    String searchText = '';
    List<Map<String, dynamic>> suggestions = [];
    bool searching = false;

    Future<void> fetchSuggestions(String query, String role) async {
      searching = true;
      final ref = FirebaseDatabase.instance.ref('users');
      final snap = await ref.get();
      suggestions.clear();
      if (snap.exists && snap.value is Map) {
        final map = Map<String, dynamic>.from(snap.value as Map);
        map.forEach((userId, userData) {
          final u = Map<String, dynamic>.from(userData);
          final userRole = u['role']?.toString();
          final firstName = u['first_name']?.toString().toLowerCase() ?? '';
          final lastName = u['last_name']?.toString().toLowerCase() ?? '';
          final email = u['email']?.toString().toLowerCase() ?? '';
          if (userRole == role &&
              (firstName.contains(query) ||
                  lastName.contains(query) ||
                  email.contains(query) ||
                  userId.toLowerCase().contains(query))) {
            suggestions.add({
              'userId': userId,
              'name': '${u['first_name'] ?? ''} ${u['last_name'] ?? ''}'.trim(),
              'email': u['email'] ?? '',
            });
          }
        });
      }
      searching = false;
    }

    showGlassPopup(
      context: context,
      title: 'Add Participant',
      dismissible: true,
      child: StatefulBuilder(
        builder: (dialogContext, setDialogState) {
          return Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _GlassField(
                child: DropdownButtonFormField<String>(
                  value: selectedRole,
                  decoration: const InputDecoration(
                    labelText: 'Role',
                    border: InputBorder.none,
                  ),
                  dropdownColor: Colors.black87,
                  style: const TextStyle(color: Colors.white),
                  items: roles
                      .map((r) => DropdownMenuItem(value: r, child: Text(r)))
                      .toList(),
                  onChanged: (val) {
                    setDialogState(() {
                      selectedRole = val!;
                      searchText = '';
                      suggestions = [];
                    });
                  },
                ),
              ),
              const SizedBox(height: 12),
              _GlassField(
                child: TextField(
                  autofocus: true,
                  style: const TextStyle(color: Colors.white),
                  decoration: const InputDecoration(
                    hintText: "Search by name/email/userId",
                    hintStyle: TextStyle(color: Colors.white70),
                    border: InputBorder.none,
                  ),
                  onChanged: (q) async {
                    setDialogState(() {
                      searchText = q.trim().toLowerCase();
                    });
                    if (searchText.length >= 2 && selectedRole != null) {
                      await fetchSuggestions(searchText, selectedRole!);
                      setDialogState(() {});
                    } else {
                      setDialogState(() => suggestions.clear());
                    }
                  },
                ),
              ),
              const SizedBox(height: 10),
              if (searchText.length >= 2 && selectedRole != null)
                searching
                    ? const Padding(
                        padding: EdgeInsets.symmetric(vertical: 12),
                        child: Center(child: CircularProgressIndicator()),
                      )
                    : (suggestions.isEmpty
                        ? const Padding(
                            padding: EdgeInsets.symmetric(vertical: 12),
                            child: Text('No match found',
                                style: TextStyle(color: Colors.white70)),
                          )
                        : ListView.separated(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            itemCount: suggestions.length,
                            separatorBuilder: (_, __) => Divider(
                              height: 1,
                              color: Colors.white.withOpacity(0.25),
                            ),
                            itemBuilder: (_, i) {
                              final s = suggestions[i];
                              return ListTile(
                                dense: true,
                                leading: const Icon(Icons.person,
                                    color: Colors.white),
                                title: Text(
                                  s['name'] ?? '',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                subtitle: Text(
                                  s['email'] ?? '',
                                  style:
                                      const TextStyle(color: Colors.white70),
                                ),
                                onTap: () async {
                                  await FirebaseDatabase.instance
                                      .ref(
                                          'channels/${widget.channelId}/members/$selectedRole/${s['userId']}')
                                      .set({
                                    'name': s['name'],
                                    'email': s['email'],
                                    'userId': s['userId'],
                                    'role': selectedRole,
                                  });
                                  if (mounted) {
                                    Navigator.of(dialogContext).pop();
                                  }
                                },
                              );
                            },
                          )),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton(
                  style: OutlinedButton.styleFrom(
                    side: BorderSide(color: Colors.white.withOpacity(0.7)),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10)),
                  ),
                  onPressed: () => Navigator.of(dialogContext).pop(),
                  child: const Text("Cancel",
                      style: TextStyle(fontWeight: FontWeight.w600)),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  // =========================
  // REMOVE PARTICIPANT (Glass)
  // =========================
  void _removeParticipant(Map<String, String> p) {
    final name = p['name'] ?? '';
    final role = p['role'] ?? '';
    final userId = p['userId'] ?? '';

    showGlassPopup(
      context: context,
      title: 'Confirm Removal',
      dismissible: true,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "Are you sure you want to remove $name?",
            style:
                const TextStyle(fontSize: 16, color: Colors.white, height: 1.35),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  style: OutlinedButton.styleFrom(
                    side: BorderSide(color: Colors.white.withOpacity(0.7)),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10)),
                  ),
                  onPressed: () => Navigator.pop(context),
                  child: const Text("Cancel",
                      style: TextStyle(fontWeight: FontWeight.w600)),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10)),
                    elevation: 0,
                  ),
                  onPressed: () async {
                    await _db
                        .child('channels/${widget.channelId}/members/$role/$userId')
                        .remove();
                    if (mounted) {
                      setState(() {
                        if (_selectedParticipant?['userId'] == userId) {
                          _selectedParticipant = null;
                        }
                      });
                      Navigator.pop(context);
                    }
                  },
                  child: const Text("Delete",
                      style:
                          TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // =========================
  // EDIT DESCRIPTION (Glass)
  // =========================
  void _editGroupDescription() {
    String tempDescription = _description ?? '';
    final controller = TextEditingController(text: tempDescription);

    showGlassPopup(
      context: context,
      title: 'Edit Group Description',
      dismissible: true,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _GlassField(
            child: TextField(
              controller: controller,
              style: const TextStyle(color: Colors.white),
              onChanged: (value) => tempDescription = value,
              maxLines: 3,
              decoration: const InputDecoration(
                hintText: "Enter group description",
                hintStyle: TextStyle(color: Colors.white70),
                border: InputBorder.none,
              ),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  style: OutlinedButton.styleFrom(
                    side: BorderSide(color: Colors.white.withOpacity(0.7)),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10)),
                  ),
                  onPressed: () => Navigator.pop(context),
                  child: const Text("Cancel",
                      style: TextStyle(fontWeight: FontWeight.w600)),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.black,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10)),
                    elevation: 0,
                  ),
                  onPressed: () async {
                    await _db
                        .child('channels/${widget.channelId}/description')
                        .set(tempDescription);
                    if (mounted) Navigator.pop(context);
                  },
                  child: const Text("Save",
                      style:
                          TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _membersCountLabel() => 'Group · ${_participants.length} members';

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final containerWidth = screenWidth * 0.90;
    final q = searchController.text.trim().toLowerCase();
    final filtered = q.isEmpty
        ? _participants
        : _participants
            .where((p) => (p['name'] ?? '').toLowerCase().contains(q))
            .toList();

    return SingleChildScrollView(
      child: Center(
        child: Container(
          width: containerWidth,
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              CircleAvatar(
                radius: 30,
                backgroundColor: Colors.transparent,
                backgroundImage:
                    (_logoUrl != null && _logoUrl!.isNotEmpty) ? NetworkImage(_logoUrl!) : null,
                child: (_logoUrl == null || _logoUrl!.isEmpty)
                    ? const Icon(Icons.group, color: Colors.white, size: 32)
                    : null,
              ),
              const SizedBox(height: 12),
              Text(
                _channelName ?? widget.channelId,
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                overflow: TextOverflow.ellipsis,
              ),
              Text(_membersCountLabel()),
              const SizedBox(height: 16),
              GestureDetector(
                onTap: _editGroupDescription,
                child: Text(
                  (_description == null || _description!.isEmpty)
                      ? 'Add group description'
                      : _description!,
                  style: const TextStyle(color: Colors.green),
                ),
              ),
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  ElevatedButton.icon(
                    onPressed: _addParticipant,
                    icon: const Icon(Icons.person_add),
                    label: const Text("Add"),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              ListTile(
                leading: const Icon(Icons.import_export),
                title: const Text("Export Chat"),
                onTap: () {/* Export logic */},
              ),
              ListTile(
                leading: const Icon(Icons.delete),
                title: const Text("Delete Chat"),
                onTap: () {/* Delete logic */},
              ),
              const SizedBox(height: 24),
              const Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  "Participants",
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: searchController,
                onChanged: (_) => setState(() {}),
                decoration: InputDecoration(
                  hintText: "Search participant",
                  prefixIcon: const Icon(Icons.search),
                  suffixIcon: searchController.text.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.close),
                          onPressed: () {
                            searchController.clear();
                            setState(() {});
                          },
                        )
                      : null,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                ),
              ),
              const SizedBox(height: 8),
              ...filtered.map(
                (p) => _ParticipantTile(
                  userId: p['userId'] ?? '',
                  name: p['name'] ?? '',
                  role: p['role'] ?? '',
                  selected: _selectedParticipant?['userId'] == p['userId'],
                  onTap: () => setState(() => _selectedParticipant = p),
                  onRemove: () => _removeParticipant(p),
                ),
              ),
              const SizedBox(height: 16),
              if (_selectedParticipant != null) ...[
                const Divider(height: 32),
                Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    "Profile",
                    style: Theme.of(context)
                        .textTheme
                        .titleMedium
                        ?.copyWith(fontWeight: FontWeight.w700),
                  ),
                ),
                const SizedBox(height: 12),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF7F8FA),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.grey.shade300),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 10),
                      ChannelProfileInfoSection(
                        channelId: widget.channelId,
                        userId: _selectedParticipant!['userId']!,
                        role: _selectedParticipant!['role']!,
                      ),
                      const SizedBox(height: 5),
                      if (_selectedParticipant!['role'] == 'School')
                        ChannelAssociatesProfileSection(
                          channelId: widget.channelId,
                          schoolId: _selectedParticipant!['userId']!,
                        ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

/* ──────────────────────────────────────────────────────────────────────────
   Role-aware avatar that fetches Student photos via cached resolver
   (Auth.photoURL → RTDB users/<uid> common keys → Storage fallbacks).
   Non-students show a fixed role initial (A/B/G/S).
   ────────────────────────────────────────────────────────────────────────── */

class _ParticipantTile extends StatelessWidget {
  final String userId;
  final String name;
  final String role;
  final bool selected;
  final VoidCallback onTap;
  final VoidCallback onRemove;

  const _ParticipantTile({
    required this.userId,
    required this.name,
    required this.role,
    required this.selected,
    required this.onTap,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      selected: selected,
      selectedTileColor: const Color(0xFFEFF3FF),
      leading: _RoleAwareAvatar(uid: userId, role: role, name: name),
      title: Text(name.isEmpty ? '(no name)' : name, overflow: TextOverflow.ellipsis),
      subtitle: Text(role),
      trailing: IconButton(
        icon: const Icon(Icons.remove_circle, color: Colors.red),
        onPressed: onRemove,
      ),
      onTap: onTap,
    );
  }
}

class _RoleAwareAvatar extends StatelessWidget {
  final String uid;
  final String role;
  final String name;
  const _RoleAwareAvatar({required this.uid, required this.role, required this.name});

  bool get _isStudent => role.trim().toLowerCase() == 'student';

  @override
  Widget build(BuildContext context) {
    if (!_isStudent) {
      // Non-students: fixed initial based on role (A/B/G/S)
      final letter = _roleInitial(role);
      return CircleAvatar(
        radius: 20,
        backgroundColor: const Color(0xFFEDF1F7),
        child: Text(
          letter,
          style: const TextStyle(
            color: Color(0xFF2A2E3B),
            fontWeight: FontWeight.w800,
          ),
        ),
      );
    }

    // Students: resolve photo with small in-memory future cache
    return FutureBuilder<String?>(
      future: _getPhotoUrlCached(uid),
      builder: (context, snap) {
        final url = (snap.data ?? '').trim();
        if (url.isEmpty) {
          // fallback: student initial "S"
          return const CircleAvatar(
            radius: 20,
            backgroundColor: Color(0xFFEDF1F7),
            child: Text(
              'S',
              style: TextStyle(
                color: Color(0xFF2A2E3B),
                fontWeight: FontWeight.w800,
              ),
            ),
          );
        }
        return CircleAvatar(
          radius: 20,
          backgroundColor: Colors.transparent,
          foregroundImage: NetworkImage(url),
        );
      },
    );
  }
}

String _roleInitial(String role) {
  switch (role.trim().toLowerCase()) {
    case 'admin':
      return 'A';
    case 'brand':
      return 'B';
    case 'guardian':
      return 'G';
    case 'school':
      return 'S';
    default:
      return role.isNotEmpty ? role.characters.first.toUpperCase() : '?';
  }
}

/* ──────────────────────────────────────────────────────────────────────────
   Glass field (unchanged)
   ────────────────────────────────────────────────────────────────────────── */

class _GlassField extends StatelessWidget {
  final Widget child;
  const _GlassField({required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.25),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.white.withOpacity(0.25)),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      child: child,
    );
  }
}

/* ──────────────────────────────────────────────────────────────────────────
   Photo resolver + tiny in-memory future cache
   Order: Auth.photoURL (if current user) → RTDB users/<uid> (common keys)
          → Storage users/<uid>/profile.(jpg|jpeg|png).
   Returns null if nothing is found.
   ────────────────────────────────────────────────────────────────────────── */

final Map<String, Future<String?>> _photoFutureCache = {};

Future<String?> _getPhotoUrlCached(String uid) {
  return _photoFutureCache.putIfAbsent(uid, () => _resolveProfilePhotoUrl(uid));
}

Future<String?> _resolveProfilePhotoUrl(String uid) async {
  final authUser = FirebaseAuth.instance.currentUser;

  // 1) If it's the signed-in user, try Auth.photoURL first
  if (authUser != null && authUser.uid == uid) {
    final p = (authUser.photoURL ?? '').trim();
    if (p.isNotEmpty) return p;
  }

  // 2) RTDB: users/<uid> → common keys with valid URL shape
  try {
    final snap = await FirebaseDatabase.instance.ref('users/$uid').get();
    if (snap.exists && snap.value is Map) {
      final m = Map<Object?, Object?>.from(snap.value as Map);

      String? pick(dynamic v) {
        if (v is! String) return null;
        final t = v.trim();
        if (t.isEmpty) return null;
        final u = Uri.tryParse(t);
        return (u != null && u.hasScheme && u.hasAuthority) ? t : null;
      }

      final url = pick(m['profilePhotoUrl']) ??
          pick(m['profile_photo_url']) ??
          pick(m['photoURL']) ??
          pick(m['photoUrl']) ??
          pick(m['avatar']) ??
          pick(m['profile_photo']) ??
          pick(m['profile_pic']);

      if (url != null) return url;
    }
  } catch (_) {
    // ignore and try storage next
  }

  // 3) Storage: users/<uid>/profile.(jpg|jpeg|png)
  final ref = FirebaseStorage.instance.ref();
  for (final path in [
    'users/$uid/profile.jpg',
    'users/$uid/profile.jpeg',
    'users/$uid/profile.png',
  ]) {
    try {
      final url = await ref.child(path).getDownloadURL();
      final t = url.trim();
      if (t.isNotEmpty) return t;
    } catch (_) {
      // try next extension
    }
  }

  // No photo found
  return null;
}
