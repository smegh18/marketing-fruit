import 'dart:async';

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_firestore/cloud_firestore.dart' as fs;
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_database/firebase_database.dart' as rtdb;
import 'package:firebase_storage/firebase_storage.dart';
import 'package:file_picker/file_picker.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:scrollable_positioned_list/scrollable_positioned_list.dart';
import 'package:Marketing_Fruit/components/glasspopup.dart'; // for showGlassPopup()


// ---- Profile photo helpers (Auth → RTDB → Storage; fallback = icon) ----
Future<String?> _resolveProfilePhotoUrl(String uid) async {
  final auth = FirebaseAuth.instance.currentUser;

  // 1) If this is the signed-in user, try Auth.photoURL first
  if (auth != null && auth.uid == uid) {
    final p = (auth.photoURL ?? '').trim();
    if (p.isNotEmpty) return p;
  }

  // 2) RTDB: users/<uid> with common photo keys
  try {
    final snap = FirebaseDatabase.instance.ref('users/$uid');
    final s = await snap.get();
    if (s.exists && s.value is Map) {
      final m = Map<Object?, Object?>.from(s.value as Map);
      String? pick(dynamic v) {
        if (v is! String) return null;
        final t = v.trim();
        if (t.isEmpty) return null;
        final u = Uri.tryParse(t);
        return (u != null && u.hasScheme && u.hasAuthority) ? t : null;
      }

      final winner = pick(m['profilePhotoUrl']) ??
          pick(m['profile_photo_url']) ??
          pick(m['photoURL']) ??
          pick(m['avatar']) ??
          pick(m['profile_photo']) ??
          pick(m['profile_pic']);
      if (winner != null) return winner;
    }
  } catch (_) {
    // ignore and try storage
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
      if (url.trim().isNotEmpty) return url.trim();
    } catch (_) {/* try next */}
  }

  // No photo found
  return null;
}

/// Small avatar widget that shows the resolved network photo or a person icon.
class _UserAvatar extends StatelessWidget {
  final String uid;
  final String name;
  final double radius;
  const _UserAvatar({required this.uid, required this.name, this.radius = 16});

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<String?>(
      future: _resolveProfilePhotoUrl(uid),
      builder: (context, snap) {
        final url = (snap.data ?? '').trim();

        if (url.isEmpty) {
          // Fallback: circular icon with the same footprint
          return CircleAvatar(
            radius: radius,
            backgroundColor: Colors.grey.shade200,
            child: Icon(Icons.person, size: radius, color: Colors.grey.shade600),
          );
        }

        // Network image with graceful error handling
        return ClipOval(
          child: SizedBox(
            width: radius * 2,
            height: radius * 2,
            child: Image.network(
              url,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => CircleAvatar(
                radius: radius,
                backgroundColor: Colors.grey.shade200,
                child: Icon(Icons.person, size: radius, color: Colors.grey.shade600),
              ),
            ),
          ),
        );
      },
    );
  }
}




class _UserRecord {
  final String id;
  final String name;
  final String role;
  const _UserRecord({required this.id, required this.name, this.role = 'User'});
}

class UserMessageSection extends StatefulWidget {
  const UserMessageSection({
    super.key,
    this.messageListHeight = 420,
    this.initialPeerId,
    this.initialPeerName,
    this.initialPeerRole,
    required this.onprofileTap
  });

  final double messageListHeight;
   // NEW (optional preselected DM):
  final String? initialPeerId;
  final String? initialPeerName;
  final String? initialPeerRole;
  final void Function(String id, String name) onprofileTap;

  @override
  State<UserMessageSection> createState() => _UserMessageSectionState();
}

class _UserMessageSectionState extends State<UserMessageSection> {
  final TextEditingController _searchCtrl = TextEditingController();
  _UserRecord? _selectedUser;
  List<_UserRecord> _allUsers = [];
  List<_UserRecord> _searchSuggestions = [];

  final LayerLink _layerLink = LayerLink();
  OverlayEntry? _suggestionOverlay;

  String? _currentUid;

  @override
  void initState() {
    super.initState();
    final user = FirebaseAuth.instance.currentUser;
    _currentUid = user?.uid;
    _fetchAllUsers();
    _searchCtrl.addListener(_onSearchChanged);
  }

  Future<void> _fetchAllUsers() async {
    final ref = FirebaseDatabase.instance.ref('users');
    final snap = await ref.get();
    if (snap.exists && snap.value is Map) {
      final users = <_UserRecord>[];
      (snap.value as Map).forEach((uid, data) {
        if (data is Map) {
          final f = (data['first_name'] ?? '').toString();
          final l = (data['last_name'] ?? '').toString();
          final n = ('$f $l').trim();
          users.add(_UserRecord(
            id: uid,
            name: n.isEmpty ? (data['name']?.toString() ?? '') : n,
            role: data['role']?.toString() ?? 'User',
          ));
        }
      });
      setState(() {
        _allUsers = users;
        _maybeOpenInitialPeer(); // NEW
      });
    }
  }
  void _maybeOpenInitialPeer() {
  if (widget.initialPeerId == null) return;
  if (_selectedUser?.id == widget.initialPeerId) return;

  final found = _allUsers.firstWhere(
    (u) => u.id == widget.initialPeerId,
    orElse: () => _UserRecord(
      id: widget.initialPeerId!,
      name: (widget.initialPeerName ?? '').trim().isEmpty
          ? widget.initialPeerId!
          : widget.initialPeerName!.trim(),
      role: widget.initialPeerRole ?? 'User',
    ),
  );

  setState(() {
    _selectedUser = found;
    _searchCtrl.clear();
    _searchSuggestions = [];
  });
  _removeOverlay();
}


  void _onSearchChanged() {
    final q = _searchCtrl.text.trim().toLowerCase();
    List<_UserRecord> suggestions = [];
    if (q.length >= 2) {
      suggestions = _allUsers
          .where((u) => u.name.toLowerCase().contains(q) || u.role.toLowerCase().contains(q))
          .toList();
    }
    setState(() {
      _searchSuggestions = suggestions;
    });
    _updateOverlay();
  }

  void _openChat(_UserRecord user) {
    _removeOverlay();
    setState(() {
      _selectedUser = user;
    });
  }

  void _backFromChat() {
    setState(() => _selectedUser = null);
  }

  void _removeOverlay() {
    _suggestionOverlay?.remove();
    _suggestionOverlay = null;
  }

  void _updateOverlay() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _removeOverlay();
      if (_searchCtrl.text.isNotEmpty &&
          _selectedUser == null &&
          _searchSuggestions.isNotEmpty &&
          context.mounted) {
        final overlay = Overlay.of(context);
        RenderBox box = context.findRenderObject() as RenderBox;
        _suggestionOverlay = OverlayEntry(
          builder: (context) => Positioned(
            width: box.size.width * 0.7,
            child: CompositedTransformFollower(
              link: _layerLink,
              showWhenUnlinked: false,
              offset: const Offset(0, 44),
              child: Material(
                elevation: 6,
                borderRadius: BorderRadius.circular(12),
                child: ListView.separated(
                  physics: const ClampingScrollPhysics(),
                  shrinkWrap: true,
                  itemCount: _searchSuggestions.length,
                  separatorBuilder: (_, __) => const Divider(height: 1),
                  itemBuilder: (ctx, i) {
                    final u = _searchSuggestions[i];
                    return ListTile(
                      leading: _UserAvatar(uid: u.id, name: u.name, radius: 18),

                      title: Text(u.name),
                      subtitle: Text(u.role),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (_currentUid != null)
                            _DMUnreadBadge(
                              currentUid: _currentUid!,
                              peerUid: u.id,
                            ),
                          const SizedBox(width: 8),
                          OutlinedButton.icon(
                            icon: const Icon(Icons.chat_bubble_outline, size: 18),
                            label: const Text('Chat'),
                            onPressed: () => _openChat(u),
                          ),
                        ],
                      ),
                      onTap: () => _openChat(u),
                    );
                  },
                ),
              ),
            ),
          ),
        );
        overlay.insert(_suggestionOverlay!);
      }
    });
  }

  @override
void didUpdateWidget(covariant UserMessageSection oldWidget) {
  super.didUpdateWidget(oldWidget);
  if (widget.initialPeerId != null && widget.initialPeerId != oldWidget.initialPeerId) {
    _maybeOpenInitialPeer();
  }
}


  @override
  void dispose() {
    _removeOverlay();
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final containerWidth = MediaQuery.of(context).size.width * 0.90;
    final containerHeight = MediaQuery.of(context).size.height * 0.80;

    final theme = Theme.of(context);
    return Material(
      color: Colors.transparent,
      child: Center(
        child: Container(
          width: containerWidth,
          height: containerHeight,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: theme.cardColor,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CompositedTransformTarget(
                link: _layerLink,
                child: Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _searchCtrl,
                        decoration: InputDecoration(
                          hintText: 'Search user…',
                          prefixIcon: const Icon(Icons.search),
                          suffixIcon: (_searchCtrl.text.isNotEmpty && _selectedUser == null)
                              ? IconButton(
                            tooltip: 'Clear',
                            icon: const Icon(Icons.close),
                            onPressed: () {
                              setState(() => _searchCtrl.clear());
                              _onSearchChanged();
                            },
                          )
                              : null,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 10,
                          ),
                        ),
                        onChanged: (_) => _onSearchChanged(),
                        onSubmitted: (_) {
                          final match = _searchSuggestions.isNotEmpty ? _searchSuggestions.first : null;
                          if (match != null) _openChat(match);
                          _removeOverlay();
                        },
                        onTap: _updateOverlay,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),

              if (_selectedUser != null)
                Expanded(
                  child: _FirestoreDMChat(
                    user: _selectedUser!,
                    onBack: _backFromChat,
                    onView: widget.onprofileTap,
                    messageListHeight: widget.messageListHeight,
                  ),
                ),

              if (_selectedUser == null && _currentUid != null)
                Expanded(
                  child: StreamBuilder<QuerySnapshot>(
                    stream: FirebaseFirestore.instance
                        .collection('users')
                        .doc(_currentUid!)
                        .collection('chats')
                        .snapshots(),
                    builder: (context, chatSnap) {
                      if (chatSnap.connectionState == ConnectionState.waiting) {
                        return const Center(child: CircularProgressIndicator());
                      }
                      if (!chatSnap.hasData || chatSnap.data!.docs.isEmpty) {
                        return const Center(child: Text('No recents found.'));
                      }
                      final List<QueryDocumentSnapshot> chats = chatSnap.data!.docs;
                      return ListView.builder(
                        itemCount: chats.length,
                        itemBuilder: (context, i) {
                          final chatDoc = chats[i];
                          final otherUserId = chatDoc.id;
                          final lastMsgSnap = chatDoc.reference
                              .collection('messages')
                              .orderBy('timestamp', descending: true)
                              .limit(1)
                              .snapshots();

                          final cached = _allUsers.firstWhere(
                                (u) => u.id == otherUserId,
                            orElse: () => _UserRecord(id: otherUserId, name: otherUserId, role: ''),
                          );
                          return StreamBuilder<QuerySnapshot>(
                            stream: lastMsgSnap,
                            builder: (context, msgSnap) {
                              String? msg;
                              if (msgSnap.hasData && msgSnap.data!.docs.isNotEmpty) {
                                final data = msgSnap.data!.docs.first.data() as Map<String, dynamic>? ?? {};
                                // show friendly text for special message types
                                if (data['type'] == 'file') {
                                  msg = '📎 Attachment';
                                } else if (data['type'] == 'profile') {
                                  msg = '👤 Profile';
                                } else {
                                  msg = (data['text'] as String?);
                                }
                              }
                              return ListTile(
                                leading: _UserAvatar(uid: cached.id, name: cached.name, radius: 18),

                                title: Text(cached.name),
                                subtitle: Text(
                                  msg != null && msg.isNotEmpty ? msg : cached.role,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                trailing: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    _DMUnreadBadge(
                                      currentUid: _currentUid!,
                                      peerUid: cached.id,
                                    ),
                                    const SizedBox(width: 8),
                                    OutlinedButton.icon(
                                      icon: const Icon(Icons.chat, size: 18),
                                      label: const Text('Chat'),
                                      onPressed: () => _openChat(cached),
                                    ),
                                  ],
                                ),
                                onTap: () => _openChat(cached),
                              );
                            },
                          );
                        },
                      );
                    },
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

/* ===========================
   1:1 Firestore DM Chat widget
   (with inline message search + PLUS MENU)
   =========================== */

class _FirestoreDMChat extends StatefulWidget {
  final _UserRecord user;
  final VoidCallback onBack;
  final void Function(String id, String name) onView;
  final double messageListHeight; // kept as a soft minimum

  const _FirestoreDMChat({
    required this.user,
    required this.onBack,
    required this.messageListHeight, required this.onView,
  });

  @override
  State<_FirestoreDMChat> createState() => _FirestoreDMChatState();
}

class _FirestoreDMChatState extends State<_FirestoreDMChat> {
  final TextEditingController _ctrl = TextEditingController();
  bool _uploading = false; // indicates any ongoing uploads
  int _uploadingCount = 0;  // number of files currently uploading

  late String _currentUid;
  late String _currentUserName;
  late String _currentUserRole;

  // ----- Inline message search (WhatsApp-like) -----
  bool _searchOpen = false;
  final TextEditingController _msgSearchCtrl = TextEditingController();
  bool _searchLoading = false;
  static const int _scanLimit = 600;
  List<_SearchHit> _hits = []; // newest -> oldest
  int _hitIndex = -1;

  // ----- Jump-to-hit via remount -----
  final ItemScrollController _itemScrollCtrl = ItemScrollController();
  final ItemPositionsListener _itemPosListener = ItemPositionsListener.create();
  Key _listKey = const ValueKey('dm-list-init');
  String? _initialTargetId;    // message id to mount at (or null => bottom)
  String? _highlightMessageId; // blink highlight target
  int _rebuildNonce = 0;

  // ----- PLUS (“+”) anchored menu -----
  final LayerLink _plusLink = LayerLink();
  OverlayEntry? _plusMenuOverlay;

      Color _dmRoleBg(String role) {
      switch (role) {
        case 'Student':
          return Colors.blue.shade100;
        case 'Brand':
          return Colors.orange.shade100;
        case 'Guardian':
          return Colors.green.shade100;
        case 'School':
          return Colors.purple.shade100;
        case 'Admin':
          return Colors.grey.shade400;
        default:
          return Colors.grey.shade300;
      }
    }

    Color _dmRoleFg(String role) {
      switch (role) {
        case 'Student':
          return Colors.blue.shade900;
        case 'Brand':
          return Colors.orange.shade900;
        case 'Guardian':
          return Colors.green.shade900;
        case 'School':
          return Colors.purple.shade900;
        case 'Admin':
          return Colors.black;
        default:
          return Colors.black87;
      }
    }


  @override
  void initState() {
    super.initState();
    final user = FirebaseAuth.instance.currentUser;
    _currentUid = user?.uid ?? "unknown_uid";
    _currentUserName = '';
    _currentUserRole = '';

    // Mark as read when opening the thread
    WidgetsBinding.instance.addPostFrameCallback((_) => _markThreadRead());
  }

  @override
  void didUpdateWidget(covariant _FirestoreDMChat oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.user.id != widget.user.id) {
      // reset search + remount baseline for new peer
      _resetSearch(clearField: true);
      _initialTargetId = null;
      _highlightMessageId = null;
      _listKey = ValueKey('dm-${widget.user.id}-bottom-${_rebuildNonce++}');
      WidgetsBinding.instance.addPostFrameCallback((_) => _markThreadRead());
    }
  }

  Future<void> _markThreadRead() async {
    final ref = rtdb.FirebaseDatabase.instance
        .ref('messages/dm/reads/$_currentUid/${widget.user.id}');
    await ref.set(rtdb.ServerValue.timestamp);
  }

  Future<void> _loadCurrentUserDetails() async {
    final ref = FirebaseDatabase.instance.ref('users/$_currentUid');
    final snap = await ref.get();
    if (snap.exists && snap.value is Map) {
      final userMap = Map<String, dynamic>.from(snap.value as Map);
      final f = (userMap['first_name'] ?? '').toString();
      final l = (userMap['last_name'] ?? '').toString();
      final n = ('$f $l').trim();
      _currentUserName = n.isEmpty ? (userMap['name']?.toString() ?? '') : n;
      _currentUserRole = userMap['role']?.toString() ?? 'User';
    } else {
      _currentUserName = 'User';
      _currentUserRole = 'User';
    }
  }

  Future<void> _sendText() async {
    final txt = _ctrl.text.trim();
    if (txt.isEmpty) return;
    await _loadCurrentUserDetails();

    final now = FieldValue.serverTimestamp();
    final base = {
      'type': 'text',
      'text': txt,
      'fromMe': true,
      'senderUid': _currentUid,
      'receiverUid': widget.user.id,
      'senderName': _currentUserName,
      'senderRole': _currentUserRole,
      'timestamp': now,
    };

    // Sender thread
    await FirebaseFirestore.instance
        .collection('users').doc(_currentUid)
        .collection('chats').doc(widget.user.id)
        .collection('messages').add(base);

    // Recents: sender
    await FirebaseFirestore.instance
        .collection('users').doc(_currentUid)
        .collection('chats').doc(widget.user.id)
        .set({
      'peerUid': widget.user.id,
      'lastMessage': txt,
      'lastTimestamp': now,
      'peerName': widget.user.name,
      'peerRole': widget.user.role,
    }, SetOptions(merge: true));

    // Mirror for recipient
    final mirrored = Map<String, dynamic>.from(base)..['fromMe'] = false;
    await FirebaseFirestore.instance
        .collection('users').doc(widget.user.id)
        .collection('chats').doc(_currentUid)
        .collection('messages').add(mirrored);

    // Recents: recipient
    await FirebaseFirestore.instance
        .collection('users').doc(widget.user.id)
        .collection('chats').doc(_currentUid)
        .set({
      'peerUid': _currentUid,
      'lastMessage': txt,
      'lastTimestamp': now,
      'peerName': _currentUserName,
      'peerRole': _currentUserRole,
    }, SetOptions(merge: true));

    _ctrl.clear();

    // keep read state fresh for me after sending
    _markThreadRead();
  }

  /// MULTI-FILE (max 5)
  Future<void> _pickAndUploadAttachments() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        allowMultiple: true,
        type: FileType.custom,
        allowedExtensions: ['jpg', 'jpeg', 'png', 'gif', 'webp', 'pdf'],
        withData: true,
      );
      if (result == null || result.files.isEmpty) return;

      await _loadCurrentUserDetails();

      // Enforce max 5
      List<PlatformFile> files = result.files;
      if (files.length > 5) {
        files = files.take(5).toList();
        _showSnack('You can select a maximum of 5 files at a time. Taking the first 5.');
      }

      setState(() {
        _uploading = true;
        _uploadingCount = files.length;
      });

      for (final f in files) {
        await _uploadSingleAttachment(f);
        if (!mounted) return;
        setState(() => _uploadingCount -= 1);
      }

      _showSnack('Sent ${files.length} attachment${files.length == 1 ? '' : 's'}');
    } catch (e) {
      _showSnack('Upload failed: $e');
    } finally {
      if (mounted) {
        setState(() {
          _uploading = false;
          _uploadingCount = 0;
        });
      }
    }
  }

  Future<void> _uploadSingleAttachment(PlatformFile f) async {
    final name = f.name;
    final bytes = f.bytes;
    if (bytes == null) {
      _showSnack('Could not read bytes for $name');
      return;
    }

    final ext = name.split('.').last.toLowerCase();
    final isImage = ['jpg', 'jpeg', 'png', 'gif', 'webp'].contains(ext);
    final isPdf = ext == 'pdf';
    if (!(isImage || isPdf)) {
      _showSnack('Only images or PDF are allowed. Skipped $name');
      return;
    }
    final mime = isImage ? 'image/$ext' : 'application/pdf';

    final ts = DateTime.now().millisecondsSinceEpoch;
    final storagePath = 'messages/dm/$_currentUid/${widget.user.id}/${ts}_$name';
    final ref = FirebaseStorage.instance.ref(storagePath);

    final snap = await ref.putData(bytes, SettableMetadata(contentType: mime)).whenComplete(() {});
    final url = await snap.ref.getDownloadURL();

    final now = FieldValue.serverTimestamp();
    final fileMsg = {
      'type': 'file',
      'text': '',
      'fileUrl': url,
      'fileName': name,
      'fileMime': mime,
      'fromMe': true,
      'senderUid': _currentUid,
      'receiverUid': widget.user.id,
      'senderName': _currentUserName,
      'senderRole': _currentUserRole,
      'timestamp': now,
    };

    // Sender thread
    await FirebaseFirestore.instance
        .collection('users').doc(_currentUid)
        .collection('chats').doc(widget.user.id)
        .collection('messages').add(fileMsg);

    await FirebaseFirestore.instance
        .collection('users').doc(_currentUid)
        .collection('chats').doc(widget.user.id)
        .set({
      'peerUid': widget.user.id,
      'lastMessage': '📎 Attachment',
      'lastTimestamp': now,
      'peerName': widget.user.name,
      'peerRole': widget.user.role,
    }, SetOptions(merge: true));

    // Mirror for recipient
    final mirrored = Map<String, dynamic>.from(fileMsg)..['fromMe'] = false;
    await FirebaseFirestore.instance
        .collection('users').doc(widget.user.id)
        .collection('chats').doc(_currentUid)
        .collection('messages').add(mirrored);

    await FirebaseFirestore.instance
        .collection('users').doc(widget.user.id)
        .collection('chats').doc(_currentUid)
        .set({
      'peerUid': _currentUid,
      'lastMessage': '📎 Attachment',
      'lastTimestamp': now,
      'peerName': _currentUserName,
      'peerRole': _currentUserRole,
    }, SetOptions(merge: true));

    _markThreadRead();
  }

  // ===== Profile Share (same popup + Student search as channel chat) =====

  /// Students-only search (RTDB). Tries server-side role index, falls back to client filter.
  /// RTDB rules/index: { "rules": { "users": { ".indexOn": ["role"] } } }
  Future<List<_Member>> _searchAllUsers(String query, {int limit = 50}) async {
    final q = query.trim().toLowerCase();
    if (q.isEmpty) return [];

    final DatabaseReference baseRef = FirebaseDatabase.instance.ref('users');

    // OPTION A: Server-side filter by role (requires index)
    try {
      final studentsSnap = await baseRef.orderByChild('role').equalTo('Student').get();
      final results = <_Member>[];

      if (studentsSnap.exists && studentsSnap.value is Map) {
        final Map students = Map<Object?, Object?>.from(studentsSnap.value as Map);
        students.forEach((uidKey, raw) {
          final uid = uidKey.toString();
          final name = _extractDisplayName(raw, fallback: uid);
          String role = 'Unknown';
          String email = '';
          String first = '';
          String last  = '';

          if (raw is Map) {
            final m = Map<Object?, Object?>.from(raw);
            role  = (m['role'] ?? 'Unknown').toString();
            email = (m['email']?.toString() ?? '');
            first = (m['first_name']?.toString() ?? '');
            last  = (m['last_name']?.toString() ?? '');
          }

          final hay = [name, email, first, last, ('$first $last').trim()]
              .join(' ')
              .toLowerCase();

          if (hay.contains(q) && role.toLowerCase() == 'student') {
            results.add(_Member(uid: uid, name: name, role: role));
          }
        });

        results.sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
        return results.take(limit).toList();
      }
    } catch (_) {
      // fall back
    }

    // OPTION B: Client-side filter
    final snap = await baseRef.get();
    if (!snap.exists || snap.value is! Map) return [];

    final Map users = Map<Object?, Object?>.from(snap.value as Map);
    final results = <_Member>[];

    users.forEach((uidKey, raw) {
      final uid = uidKey.toString();

      String role = 'Unknown';
      String email = '';
      String first = '';
      String last  = '';
      final name = _extractDisplayName(raw, fallback: uid);

      if (raw is Map) {
        final m = Map<Object?, Object?>.from(raw);
        role  = (m['role'] ?? 'Unknown').toString();
        email = (m['email']?.toString() ?? '');
        first = (m['first_name']?.toString() ?? '');
        last  = (m['last_name']?.toString() ?? '');
      }

      if (role.toLowerCase() != 'student') return;

      final hay = [name, email, first, last, ('$first $last').trim()]
          .join(' ')
          .toLowerCase();

      if (hay.contains(q)) {
        results.add(_Member(uid: uid, name: name, role: role));
      }
    });

    results.sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
    return results.take(limit).toList();
  }

  Future<void> _shareProfiles(List<_Member> picked) async {
    if (picked.isEmpty) return;
    await _loadCurrentUserDetails();

    final now = FieldValue.serverTimestamp();

    // Compose a 'profile' message for each selected user and mirror it
    final senderMsgs = FirebaseFirestore.instance
        .collection('users').doc(_currentUid)
        .collection('chats').doc(widget.user.id)
        .collection('messages');

    final recipientMsgs = FirebaseFirestore.instance
        .collection('users').doc(widget.user.id)
        .collection('chats').doc(_currentUid)
        .collection('messages');

    final batch = FirebaseFirestore.instance.batch();

    for (final t in picked) {
      final payload = {
        'type': 'profile',
        'text': '',
        'profile': {
          'uid': t.uid,   // keep in payload for future deep-linking (not shown)
          'name': t.name,
          'role': t.role,
        },
        'fromMe': true,
        'senderUid': _currentUid,
        'receiverUid': widget.user.id,
        'senderName': _currentUserName,
        'senderRole': _currentUserRole,
        'timestamp': now,
      };

      final doc1 = senderMsgs.doc();
      batch.set(doc1, payload);

      final mirrored = Map<String, dynamic>.from(payload)
        ..['fromMe'] = false;
      final doc2 = recipientMsgs.doc();
      batch.set(doc2, mirrored);
    }

    // Update recents for both parties with a friendly label
    batch.set(
      FirebaseFirestore.instance
          .collection('users').doc(_currentUid)
          .collection('chats').doc(widget.user.id),
      {
        'peerUid': widget.user.id,
        'lastMessage': '👤 Profile',
        'lastTimestamp': now,
        'peerName': widget.user.name,
        'peerRole': widget.user.role,
      },
      SetOptions(merge: true),
    );

    batch.set(
      FirebaseFirestore.instance
          .collection('users').doc(widget.user.id)
          .collection('chats').doc(_currentUid),
      {
        'peerUid': _currentUid,
        'lastMessage': '👤 Profile',
        'lastTimestamp': now,
        'peerName': _currentUserName,
        'peerRole': _currentUserRole,
      },
      SetOptions(merge: true),
    );

    await batch.commit();
    _showSnack('Shared ${picked.length} profile${picked.length == 1 ? '' : 's'}');

    _markThreadRead();
  }

  // ===== PLUS menu overlay =====
  void _togglePlusMenu() {
    if (_plusMenuOverlay != null) {
      _plusMenuOverlay!.remove();
      _plusMenuOverlay = null;
      return;
    }

    _plusMenuOverlay = OverlayEntry(
      builder: (_) => Positioned.fill(
        child: GestureDetector(
          behavior: HitTestBehavior.translucent,
          onTap: _togglePlusMenu,
          child: Stack(
            children: [
              CompositedTransformFollower(
                link: _plusLink,
                showWhenUnlinked: false,
                offset: const Offset(-20, -172),
                child: Material(
                  color: Colors.transparent,
                  child: _PlusMenuCard(
                    onFiles: () {
                      _togglePlusMenu();
                      _pickAndUploadAttachments();
                    },
                    onProfiles: () {
                      _togglePlusMenu();
                      _openProfilePickerMulti();
                    },
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );

    Overlay.of(context, rootOverlay: true).insert(_plusMenuOverlay!);
  }

  void _openProfilePickerMulti() {
    final w = MediaQuery.of(context).size.width;
    final isPhone = w < 560;

    showGlassPopup<void>(
      context: context,
      title: 'Share Profiles',
      maxWidthFraction: isPhone ? 0.94 : 0.62,
      maxHeightFraction: isPhone ? 0.86 : 0.78,
      minWidth: 320,
      child: _ProfilePickerMultiPanel(
        onSearch: (q) => _searchAllUsers(q),
        onShare: (picked) async {
          Navigator.of(context).maybePop();
          await _shareProfiles(picked);
        },
      ),
    );
  }

  // ===== Inline search (DM) =====
  void _toggleSearchOpen() {
    setState(() {
      _searchOpen = !_searchOpen;
      if (!_searchOpen) {
        _resetSearch();
      }
    });
  }

  void _resetSearch({bool clearField = false}) {
    if (clearField) _msgSearchCtrl.clear();
    _searchLoading = false;
    _hits = [];
    _hitIndex = -1;
  }

  Future<void> _runInlineSearch() async {
    final query = _msgSearchCtrl.text.trim();
    if (query.isEmpty) {
      setState(() {
        _hits = [];
        _hitIndex = -1;
      });
      return;
    }
    setState(() {
      _searchLoading = true;
      _hits = [];
      _hitIndex = -1;
    });

    try {
      final lc = query.toLowerCase();
      final qs = await FirebaseFirestore.instance
          .collection('users')
          .doc(_currentUid)
          .collection('chats')
          .doc(widget.user.id)
          .collection('messages')
          .orderBy('timestamp', descending: true) // newest first
          .limit(_scanLimit)
          .get();

      final hits = <_SearchHit>[];
      for (final d in qs.docs) {
        final data = d.data();
        final type = (data['type'] as String?) ?? (data['fileUrl'] != null ? 'file' : 'text');
        if (type != 'text') continue;

        final txt = (data['text'] as String?) ?? '';
        if (txt.toLowerCase().contains(lc)) {
          hits.add(_SearchHit(
            channelId: widget.user.id, // reuse field; here it's peer id
            messageId: d.id,
            text: txt,
            name: (data['senderName'] as String?) ?? '',
            role: (data['senderRole'] as String?) ?? 'User',
            ts: (data['timestamp'] is Timestamp)
                ? (data['timestamp'] as Timestamp).toDate()
                : null,
          ));
        }
      }

      setState(() {
        _hits = hits;                 // newest -> oldest
        _hitIndex = hits.isEmpty ? -1 : 0;
      });

      if (_hitIndex >= 0) {
        _jumpToByRebuild(_hits[_hitIndex].messageId);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Search failed: $e')));
      }
    } finally {
      if (mounted) setState(() => _searchLoading = false);
    }
  }

  void _gotoHit(int index) {
    if (_hits.isEmpty) return;
    if (index < 0 || index >= _hits.length) return;
    setState(() => _hitIndex = index);
    _jumpToByRebuild(_hits[_hitIndex].messageId);
  }

  void _onArrowUp() {
    // Up = older => index + 1
    if (_hits.isEmpty || _hitIndex == -1) return;
    final next = _hitIndex + 1;
    if (next < _hits.length) _gotoHit(next);
  }

  void _onArrowDown() {
    // Down = newer => index - 1
    if (_hits.isEmpty || _hitIndex == -1) return;
    final prev = _hitIndex - 1;
    if (prev >= 0) _gotoHit(prev);
  }

  void _jumpToByRebuild(String messageId, {bool highlight = true}) {
    setState(() {
      _initialTargetId = messageId;
      if (highlight) _highlightMessageId = messageId;
      _listKey = ValueKey('dm-${widget.user.id}-$messageId-${_rebuildNonce++}');
    });

    // auto-clear highlight
    Future.delayed(const Duration(seconds: 8), () {
      if (!mounted) return;
      if (_highlightMessageId == messageId) {
        setState(() => _highlightMessageId = null);
      }
    });
  }

  @override
  void dispose() {
    _plusMenuOverlay?.remove();
    _ctrl.dispose();
    _msgSearchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final messagesRef = FirebaseFirestore.instance
        .collection('users').doc(_currentUid)
        .collection('chats').doc(widget.user.id)
        .collection('messages')
        .orderBy('timestamp', descending: false); // oldest -> newest

    final chipColor = Colors.purple.shade100;
    final chipTextColor = Colors.purple.shade700;

    final theme = Theme.of(context);
    return Container(
      margin: const EdgeInsets.only(top: 6),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: theme.scaffoldBackgroundColor.withOpacity(0.5),
        border: Border.all(color: theme.dividerColor.withOpacity(0.2)),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.max,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header
          Row(
            children: [
              IconButton(
                tooltip: 'Back',
                icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 18),
                onPressed: widget.onBack,
              ),
              _UserAvatar(uid: widget.user.id, name: widget.user.name, radius: 16),

              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.user.name,
                      style: const TextStyle(fontWeight: FontWeight.w700),
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: chipColor,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        'Role: ${widget.user.role}',
                        style: TextStyle(
                          fontSize: 11,
                          color: chipTextColor,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                tooltip: _searchOpen ? 'Close search' : 'Search',
                icon: Icon(_searchOpen ? Icons.close : Icons.search, size: 20),
                onPressed: _toggleSearchOpen,
              ),
              if (_uploading) ...[
                const SizedBox(width: 8),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const SizedBox(
                      width: 16, height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                    const SizedBox(width: 6),
                    Text('Uploading$_uploadingCountLabel',
                        style: const TextStyle(fontSize: 12, color: Colors.black54)),
                  ],
                ),
              ],
            ],
          ),

          // Inline search bar (DM)
          AnimatedCrossFade(
            firstChild: const SizedBox.shrink(),
            secondChild: _buildWhatsAppSearchBar(),
            crossFadeState: _searchOpen ? CrossFadeState.showSecond : CrossFadeState.showFirst,
            duration: const Duration(milliseconds: 180),
          ),

          const Divider(height: 1),

          // Messages list
          Expanded(
            child: ConstrainedBox(
              constraints: BoxConstraints(minHeight: widget.messageListHeight),
              child: StreamBuilder<QuerySnapshot>(
                stream: messagesRef.snapshots(),
                builder: (context, snap) {
                  if (snap.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  if (!snap.hasData || snap.data!.docs.isEmpty) {
                    return const Center(child: Text('No messages yet.'));
                  }

                  // Mark read whenever we successfully see new data
                  WidgetsBinding.instance.addPostFrameCallback((_) => _markThreadRead());

                  final messages = snap.data!.docs;

                  return NotificationListener<UserScrollNotification>(
                    onNotification: (_) => false,
                    child: ScrollablePositionedList.builder(
                      key: _listKey, // remount when target changes
                      itemScrollController: _itemScrollCtrl,
                      itemPositionsListener: _itemPosListener,
                      reverse: false, // oldest -> newest
                      initialScrollIndex: (() {
                        if (_initialTargetId == null) {
                          return messages.length - 1; // bottom by default
                        }
                        final idx = messages.indexWhere((d) => d.id == _initialTargetId);
                        return (idx >= 0 ? idx : messages.length - 1);
                      })(),
                      initialAlignment: _initialTargetId == null ? 1.0 : 0.33, // center target
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
                      itemCount: messages.length,
                      itemBuilder: (context, index) {
                        final doc = messages[index];
                        final data = (doc.data() as Map<String, dynamic>?) ?? {};
                        final type = (data['type'] as String?) ??
                            (data['fileUrl'] != null ? 'file' : 'text');
                        final mine = data['fromMe'] == true;

                        Widget child;
                        if (type == 'file') {
                          final fileUrl = (data['fileUrl'] as String?) ?? '';
                          final fileName = (data['fileName'] as String?) ?? 'File';
                          final fileMime = (data['fileMime'] as String?) ?? '';
                          final isImage = fileMime.startsWith('image/');

                          child = _FileBubble(
                            isMe: mine,
                            fileUrl: fileUrl,
                            fileName: fileName,
                            fileMime: fileMime,
                            isImage: isImage,
                          );
                        }  else if (type == 'profile') {
                          final Map<String, dynamic> p =
                              (data['profile'] is Map)
                                  ? Map<String, dynamic>.from(data['profile'])
                                  : {};
                          final String pName = (p['name'] ?? '').toString();
                          final String pRole = (p['role'] ?? 'Unknown').toString();

                          // Use role-based colors (so text is always visible on the white card)
                          final Color fg = _dmRoleFg(pRole);
                          final Color bg = _dmRoleBg(pRole);

                          child = Align(
                            alignment: mine ? Alignment.centerRight : Alignment.centerLeft,
                            child: _ProfileCardBubble(
                              name: pName.isEmpty ? 'Unknown' : pName,
                              role: pRole,
                              fgColor: fg,
                              bgColor: bg,
                              onView: () {
                                widget.onView(p['uid'],p['name']);
                              },
                            ),
                          );

                        } else {
                          final text = (data['text'] as String?) ?? '';
                          child = _Bubble(msg: _Msg(text: text, mine: mine));
                        }

                        final maybeBlink =
                            (doc.id == _highlightMessageId)
                                ? _BlinkHighlight(
                                    key: ValueKey('blink_${doc.id}_$_rebuildNonce'),
                                    cycles: 4,
                                    child: child,
                                  )
                                : child;

                        return KeyedSubtree(
                          key: ValueKey(doc.id),
                          child: Padding(
                            padding: EdgeInsets.only(
                              bottom: index == messages.length - 1 ? 0 : 10,
                            ),
                            child: maybeBlink,
                          ),
                        );
                      },
                    ),
                  );
                },
              ),
            ),
          ),

          const SizedBox(height: 8),

          // Composer row (with PLUS instead of paperclip)
          Row(
            children: [
              CompositedTransformTarget(
                link: _plusLink,
                child: IconButton(
                  tooltip: 'More',
                  onPressed: _uploading ? null : _togglePlusMenu,
                  icon: _uploading
                      ? const SizedBox(
                          height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2))
                      : const Icon(Icons.add_circle_outline),
                ),
              ),
              const SizedBox(width: 4),
              Expanded(
                child: TextField(
                  controller: _ctrl,
                  decoration: InputDecoration(
                    hintText: 'Write message',
                    isDense: true,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  onSubmitted: (_) => _sendText(),
                ),
              ),
              const SizedBox(width: 8),
              ElevatedButton.icon(
                onPressed: _sendText,
                icon: const Icon(Icons.send, size: 18, color: Colors.white70),
                label: const Text('Send',
                    style: TextStyle(color: Colors.white70, fontWeight: FontWeight.bold)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF3E6AF2),
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildWhatsAppSearchBar() {
    final total = _hits.length;
    final current = (_hitIndex >= 0 && total > 0) ? (_hits.length - _hitIndex) : 0;
    final counterText = total == 0 ? '' : '$current/$total';

    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 0, 12, 10),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _msgSearchCtrl,
              textInputAction: TextInputAction.search,
              onSubmitted: (_) => _runInlineSearch(),
              decoration: InputDecoration(
                hintText: 'Search messages',
                isDense: true,
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                enabledBorder: const OutlineInputBorder(
                  borderRadius: BorderRadius.all(Radius.circular(8)),
                  borderSide: BorderSide(color: Color(0xFF9AD2A0), width: 2),
                ),
                focusedBorder: const OutlineInputBorder(
                  borderRadius: BorderRadius.all(Radius.circular(8)),
                  borderSide: BorderSide(color: Color(0xFF7DBA83), width: 2),
                ),
                contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
              ),
              onChanged: (_) => setState(() {}),
            ),
          ),
          const SizedBox(width: 6),
          Tooltip(
            message: 'Previous (older)',
            child: IconButton(
              visualDensity: VisualDensity.compact,
              onPressed: (_hits.isNotEmpty && _hitIndex != -1 && _hitIndex + 1 < _hits.length)
                  ? _onArrowUp
                  : null,
              icon: const Icon(Icons.keyboard_arrow_up_rounded),
            ),
          ),
          Tooltip(
            message: 'Next (newer)',
            child: IconButton(
              visualDensity: VisualDensity.compact,
              onPressed: (_hits.isNotEmpty && _hitIndex > 0) ? _onArrowDown : null,
              icon: const Icon(Icons.keyboard_arrow_down_rounded),
            ),
          ),
          if (_searchLoading)
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 6),
              child: SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            )
          else
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 6),
              child: Text(counterText,
                  style: const TextStyle(fontSize: 12, color: Colors.black54)),
            ),
          SizedBox(
            height: 40,
            child: ElevatedButton.icon(
              onPressed: _msgSearchCtrl.text.trim().isEmpty || _searchLoading
                  ? null
                  : _runInlineSearch,
              icon: const Icon(Icons.search, size: 18),
              label: const Text('Search'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF3E6AF2),
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
              ),
            ),
          ),
          const SizedBox(width: 6),
          Tooltip(
            message: 'Clear',
            child: IconButton(
              visualDensity: VisualDensity.compact,
              onPressed: (_hits.isNotEmpty ||
                      _msgSearchCtrl.text.isNotEmpty ||
                      _searchLoading)
                  ? () {
                      setState(() {
                        _resetSearch(clearField: true);
                      });
                      FocusScope.of(context).unfocus();
                    }
                  : null,
              icon: const Icon(Icons.close_rounded),
            ),
          ),
        ],
      ),
    );
  }

  String get _uploadingCountLabel =>
      _uploadingCount > 0 ? ' ($_uploadingCount)' : '';

  void _showSnack(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  String _extractDisplayName(dynamic val, {String fallback = ''}) {
    if (val is String) return val.trim();
    if (val is Map) {
      final m = Map<Object?, Object?>.from(val);
      final name = (m['name'] ?? '').toString().trim();
      if (name.isNotEmpty) return name;
      final first = (m['first_name'] ?? '').toString().trim();
      final last = (m['last_name'] ?? '').toString().trim();
      final full = ([first, last]..removeWhere((s) => s.isEmpty)).join(' ').trim();
      if (full.isNotEmpty) return full;
      final email = (m['email'] ?? '').toString().trim();
      if (email.isNotEmpty) return email.split('@').first;
    }
    return fallback;
  }
}

/* ========= Simple bubbles ========= */

class _Msg {
  final String text;
  final bool mine;
  const _Msg({required this.text, required this.mine});
}

class _Bubble extends StatelessWidget {
  final _Msg msg;
  const _Bubble({required this.msg});

  @override
  Widget build(BuildContext context) {
    final isMe = msg.mine;
    final bg = isMe ? Colors.purple : Colors.grey.shade800;
    final fg = Colors.white;

    final bubble = Container(
      constraints: const BoxConstraints(maxWidth: 520),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(msg.text, style: TextStyle(color: fg, height: 1.35)),
    );

    if (isMe) {
      return Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [Flexible(child: bubble)],
      );
    }
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 16,
          height: 16,
          margin: const EdgeInsets.only(right: 8, left: 4, top: 2),
          decoration: const BoxDecoration(
            color: Color(0xFFE0E0E0),
            shape: BoxShape.circle,
          ),
        ),
        Flexible(child: bubble),
      ],
    );
  }
}

class _FileBubble extends StatelessWidget {
  final bool isMe;
  final String fileUrl;
  final String fileName;
  final String fileMime;
  final bool isImage;

  const _FileBubble({
    required this.isMe,
    required this.fileUrl,
    required this.fileName,
    required this.fileMime,
    required this.isImage,
  });

  @override
  Widget build(BuildContext context) {
    final bg = isMe ? Colors.purple : Colors.grey.shade800;
    final fg = Colors.white;

    Widget content;
    if (isImage) {
      content = GestureDetector(
        onTap: () => _openUrl(fileUrl, context),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(10),
          child: Image.network(
            fileUrl,
            fit: BoxFit.cover,
            width: 240,
            height: 240,
          ),
        ),
      );
    } else {
      // PDF chip
      content = InkWell(
        onTap: () => _openUrl(fileUrl, context),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.picture_as_pdf, size: 18, color: Colors.red),
            const SizedBox(width: 8),
            Flexible(
              child: Text(
                fileName,
                style: TextStyle(
                  color: fg,
                  decoration: TextDecoration.underline,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      );
    }

    final bubble = Container(
      constraints: const BoxConstraints(maxWidth: 520),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(12),
      ),
      child: content,
    );

    return Align(
      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: bubble,
    );
  }

  Future<void> _openUrl(String url, BuildContext context) async {
    final uri = Uri.parse(url);
    final ok = await launchUrl(uri, mode: LaunchMode.externalApplication);
    if (!ok && context.mounted) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Could not open file.')));
    }
  }
}

/* ===========================
   DM Unread Badge (per peer)
   =========================== */

class _DMUnreadBadge extends StatelessWidget {
  final String currentUid;
  final String peerUid;

  const _DMUnreadBadge({
    required this.currentUid,
    required this.peerUid,
  });

  @override
  Widget build(BuildContext context) {
    // RTDB last-read location (similar to channels)
    final readsRef = rtdb.FirebaseDatabase.instance
        .ref('messages/dm/reads/$currentUid/$peerUid');

    return StreamBuilder<rtdb.DatabaseEvent>(
      stream: readsRef.onValue,
      builder: (context, snap) {
        int lastReadMs = 0;
        if (snap.hasData && snap.data!.snapshot.value != null) {
          final v = snap.data!.snapshot.value;
          if (v is int) lastReadMs = v;
          if (v is double) lastReadMs = v.round();
          if (v is String) lastReadMs = int.tryParse(v) ?? 0;
        }

        final lastRead = lastReadMs == 0
            ? null
            : fs.Timestamp.fromMillisecondsSinceEpoch(lastReadMs);

        fs.Query q = fs.FirebaseFirestore.instance
            .collection('users')
            .doc(currentUid)
            .collection('chats')
            .doc(peerUid)
            .collection('messages')
            .orderBy('timestamp', descending: false);

        if (lastRead != null) {
          q = q.where('timestamp', isGreaterThan: lastRead);
        }

        return StreamBuilder<fs.QuerySnapshot>(
          stream: q.snapshots(),
          builder: (context, qs) {
            if (!qs.hasData) return const SizedBox.shrink();
            int unread = 0;

            // To count only peer messages, use:
            // unread = qs.data!.docs.where((d) => (d['fromMe'] != true)).length;

            unread = qs.data!.docs.length;

            if (unread <= 0) return const SizedBox.shrink();
            return Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.red.shade100,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                '$unread',
                style: const TextStyle(
                  color: Colors.red,
                  fontWeight: FontWeight.bold,
                ),
              ),
            );
          },
        );
      },
    );
  }
}

/* ======= Blink/highlight for targeted messages ======= */
class _BlinkHighlight extends StatefulWidget {
  final Widget child;
  final int cycles;
  const _BlinkHighlight({super.key, required this.child, this.cycles = 4});
  @override
  State<_BlinkHighlight> createState() => _BlinkHighlightState();
}

class _BlinkHighlightState extends State<_BlinkHighlight>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ac;
  int _count = 0;

  @override
  void initState() {
    super.initState();
    _ac = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 450),
    )..addStatusListener((s) {
        if (s == AnimationStatus.completed || s == AnimationStatus.dismissed) {
          _count++;
          if (_count >= widget.cycles * 2) {
            _ac.stop();
            if (mounted) setState(() {});
          } else {
            _ac.reverseDuration ??= _ac.duration;
            (s == AnimationStatus.completed) ? _ac.reverse() : _ac.forward();
          }
        }
      });
    _ac.forward();
  }

  @override
  void dispose() {
    _ac.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!_ac.isAnimating && _count >= widget.cycles * 2) {
      return widget.child;
    }
    return FadeTransition(
      opacity: Tween(begin: 0.45, end: 1.0).animate(_ac),
      child: widget.child,
    );
  }
}

/// Search hit model (reused)
class _SearchHit {
  final String channelId; // here used as peer id
  final String messageId;
  final String text;
  final String name;
  final String role;
  final DateTime? ts;
  _SearchHit({
    required this.channelId,
    required this.messageId,
    required this.text,
    required this.name,
    required this.role,
    required this.ts,
  });
}

// ---------- Tiny helper ----------
extension _StrX on String {
  String ifEmpty(String fallback) => isEmpty ? fallback : this;
}

/* ======= Plus menu card (same pattern as channel chat) ======= */
class _PlusMenuCard extends StatelessWidget {
  final VoidCallback onFiles;
  final VoidCallback onProfiles;

  const _PlusMenuCard({
    required this.onFiles,
    required this.onProfiles,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 12,
      shadowColor: Colors.black26,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 360),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                margin: const EdgeInsets.only(top: 6, bottom: 12),
                height: 4,
                width: 44,
                decoration: BoxDecoration(
                  color: Colors.black12,
                  borderRadius: BorderRadius.circular(999),
                ),
              ),
              ListTile(
                leading: const CircleAvatar(
                  backgroundColor: Color(0xFFEEF2FF),
                  child: Icon(Icons.insert_drive_file_rounded, color: Color(0xFF3E6AF2)),
                ),
                title: const Text('Files', style: TextStyle(fontWeight: FontWeight.w600)),
                subtitle: const Text('Send photos or PDF'),
                onTap: onFiles,
              ),
              ListTile(
                leading: const CircleAvatar(
                  backgroundColor: Color(0xFFE8FAF0),
                  child: Icon(Icons.person_add_alt_1_rounded, color: Color(0xFF21A66F)),
                ),
                title: const Text('Profiles', style: TextStyle(fontWeight: FontWeight.w600)),
                subtitle: const Text('Share student profile'),
                onTap: onProfiles,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/* ======= Shared profile picker panel (matches channel chat style) ======= */

class _Member {
  final String uid;
  final String name;
  final String role;
  _Member({required this.uid, required this.name, required this.role});
}

class _ProfilePickerMultiPanel extends StatefulWidget {
  final Future<List<_Member>> Function(String query) onSearch;
  final ValueChanged<List<_Member>> onShare;

  const _ProfilePickerMultiPanel({
    required this.onSearch,
    required this.onShare,
  });

  @override
  State<_ProfilePickerMultiPanel> createState() => _ProfilePickerMultiPanelState();
}

class _ProfilePickerMultiPanelState extends State<_ProfilePickerMultiPanel> {
  final TextEditingController _searchCtrl = TextEditingController();
  String _q = '';
  List<_Member> _results = [];
  bool _loading = false;
  Timer? _debounce;

  // Keep selected across searches
  final Map<String, _Member> _selectedMap = <String, _Member>{};

  @override
  void dispose() {
    _debounce?.cancel();
    _searchCtrl.dispose();
    super.dispose();
  }

  void _onQueryChanged(String v) {
    setState(() => _q = v);
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 320), () async {
      if (!mounted) return;
      if (_q.trim().isEmpty) {
        setState(() {
          _results = [];
          _loading = false;
        });
        return;
      }
      setState(() => _loading = true);
      try {
        final res = await widget.onSearch(_q);
        if (mounted) {
          setState(() {
            _results = res;
            _loading = false;
          });
        }
      } catch (_) {
        if (mounted) setState(() => _loading = false);
      }
    });
  }

  void _togglePick(_Member m, bool pick) {
    setState(() {
      if (pick) {
        _selectedMap[m.uid] = m;
      } else {
        _selectedMap.remove(m.uid);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final selected = _selectedMap.values.toList()
      ..sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));

    const labelStyle = TextStyle(color: Colors.white70, fontSize: 12, fontWeight: FontWeight.w600);
    const bodyStyle  = TextStyle(color: Colors.white,   fontSize: 14);
    const weakText   = TextStyle(color: Colors.white60);

    final divider = Divider(height: 1, color: Colors.white.withOpacity(0.18));
    final borderSide = BorderSide(color: Colors.white.withOpacity(0.22));

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const SizedBox(height: 4),
        Padding(
          padding: const EdgeInsets.fromLTRB(4, 4, 4, 12),
          child: TextField(
            controller: _searchCtrl,
            style: bodyStyle,
            cursorColor: Colors.white70,
            decoration: InputDecoration(
              hintText: 'Type a name, email, or part of it',
              hintStyle: const TextStyle(color: Colors.white60),
              prefixIcon: const Icon(Icons.search, color: Colors.white70),
              isDense: true,
              filled: true,
              fillColor: Colors.white.withOpacity(0.06),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: borderSide,
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide(color: Colors.white.withOpacity(0.40), width: 1.6),
              ),
              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
            ),
            onChanged: _onQueryChanged,
          ),
        ),
        ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 900, maxHeight: 520),
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.04),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.white.withOpacity(0.10)),
            ),
            child: Row(
              children: [
                Expanded(
                  flex: 3,
                  child: _loading
                      ? const Center(child: CircularProgressIndicator(color: Colors.white))
                      : (_q.trim().isEmpty
                          ? const Center(child: Text('Start typing to search all users', style: weakText))
                          : (_results.isEmpty
                              ? const Center(child: Text('No users found', style: weakText))
                              : ListView.separated(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                                  itemCount: _results.length,
                                  separatorBuilder: (_, __) => divider,
                                  itemBuilder: (ctx, i) {
                                    final m = _results[i];
                                    final picked = _selectedMap.containsKey(m.uid);
                                    return Theme(
                                      data: Theme.of(context).copyWith(
                                        checkboxTheme: CheckboxThemeData(
                                          side: borderSide,
                                          fillColor: WidgetStateProperty.all(Colors.white),
                                          checkColor: WidgetStateProperty.all(Colors.black),
                                        ),
                                      ),
                                      child: CheckboxListTile(
                                        value: picked,
                                        onChanged: (v) => _togglePick(m, v == true),
                                        controlAffinity: ListTileControlAffinity.leading,
                                        title: Text(m.name,
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                            style: bodyStyle.copyWith(fontWeight: FontWeight.w600)),
                                        subtitle: Text(m.role, style: labelStyle),
                                        secondary: picked
                                            ? const Icon(Icons.check_circle, color: Colors.lightGreenAccent)
                                            : const SizedBox.shrink(),
                                      ),
                                    );
                                  },
                                ))),
                ),
                Container(
                  width: 280,
                  decoration: BoxDecoration(
                    border: Border(left: borderSide),
                    color: Colors.white.withOpacity(0.02),
                  ),
                  child: Column(
                    children: [
                      Padding(
                        padding: const EdgeInsets.fromLTRB(12, 12, 12, 8),
                        child: Row(
                          children: [
                            const Text('Selected', style: labelStyle),
                            const SizedBox(width: 6),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.12),
                                borderRadius: BorderRadius.circular(999),
                              ),
                              child: Text('${selected.length}', style: const TextStyle(color: Colors.white, fontSize: 11)),
                            ),
                            const Spacer(),
                            if (selected.isNotEmpty)
                              TextButton(
                                onPressed: () => setState(_selectedMap.clear),
                                child: const Text('Clear all', style: TextStyle(color: Colors.white)),
                              ),
                          ],
                        ),
                      ),
                      divider,
                      Expanded(
                        child: selected.isEmpty
                            ? const Center(child: Text('No profiles selected', style: weakText))
                            : ListView.separated(
                                itemCount: selected.length,
                                separatorBuilder: (_, __) => divider,
                                itemBuilder: (ctx, i) {
                                  final m = selected[i];
                                  return ListTile(
                                    dense: true,
                                    leading: CircleAvatar(
                                      backgroundColor: Colors.white.withOpacity(0.15),
                                      child: Text(
                                        m.name.isNotEmpty ? m.name[0].toUpperCase() : '?',
                                        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800),
                                      ),
                                    ),
                                    title: Text(m.name,
                                        maxLines: 1, overflow: TextOverflow.ellipsis, style: bodyStyle),
                                    subtitle: Text(m.role, style: labelStyle),
                                    trailing: IconButton(
                                      tooltip: 'Remove',
                                      icon: const Icon(Icons.close_rounded, color: Colors.white70),
                                      onPressed: () => _togglePick(m, false),
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
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(6, 12, 6, 0),
          child: Row(
            children: [
              Text(
                selected.isEmpty ? 'No profiles selected' : '${selected.length} selected',
                style: const TextStyle(color: Colors.white70),
              ),
              const Spacer(),
              TextButton(
                onPressed: () => Navigator.of(context).maybePop(),
                child: const Text('Cancel', style: TextStyle(color: Colors.white)),
              ),
              const SizedBox(width: 8),
              ElevatedButton.icon(
                onPressed: selected.isEmpty
                    ? null
                    : () {
                        widget.onShare(selected);
                      },
                icon: const Icon(Icons.send, size: 16),
                label: const Text('Send'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: Colors.black,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

/* ======= Profile card bubble (visual) ======= */
class _ProfileCardBubble extends StatelessWidget {
  final String name;
  final String role;
  final Color fgColor;
  final Color bgColor;
  final VoidCallback onView;

  const _ProfileCardBubble({
    required this.name,
    required this.role,
    required this.fgColor,
    required this.bgColor,
    required this.onView,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(maxWidth: 460),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: fgColor.withOpacity(0.25)),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 20,
            backgroundColor: bgColor.withOpacity(0.65),
            child: Text(
              name.isNotEmpty ? name[0].toUpperCase() : '?',
              style: TextStyle(color: fgColor, fontWeight: FontWeight.w800),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                        color: fgColor, fontWeight: FontWeight.w700, fontSize: 14)),
                const SizedBox(height: 2),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: fgColor.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(
                    role,
                    style: TextStyle(
                      color: fgColor,
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          OutlinedButton.icon(
            onPressed: onView,
            icon: const Icon(Icons.contact_page_outlined, size: 16),
            label: const Text('View', style: TextStyle(fontSize: 12)),
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
            ),
          ),
        ],
      ),
    );
  }
}
