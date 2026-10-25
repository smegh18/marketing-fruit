import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/rendering.dart';
import 'package:Marketing_Fruit/components/glasspopup.dart';
import 'web_image_downloader_stub.dart'
  if (dart.library.html) 'package:image_downloader_web/image_downloader_web.dart';
import 'package:photo_view/photo_view.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:scrollable_positioned_list/scrollable_positioned_list.dart';

// If you show the Channel Info drawer elsewhere, keep or remove this:
import 'package:Marketing_Fruit/components/channel_chat_info.dart';


// ---- Simple future cache so we don't refetch on every frame ----
final Map<String, Future<String?>> _photoFutureCache = {};

Future<String?> _resolveProfilePhotoUrl(String uid) async {
  final auth = FirebaseAuth.instance.currentUser;

  // 1) If it's the signed-in user, try Auth.photoURL first
  if (auth != null && auth.uid == uid) {
    final p = (auth.photoURL ?? '').trim();
    if (p.isNotEmpty) return p;
  }

  // 2) RTDB: users/<uid> – check common photo fields for a valid URL
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
          pick(m['avatar']) ??
          pick(m['photo']) ??
          pick(m['profile_photo']);
      if (url != null) return url;
    }
  } catch (_) {
    // ignore and try storage
  }

  // 3) Storage fallback
  final ref = FirebaseStorage.instance.ref();
  for (final path in [
    'users/$uid/profile.jpg',
    'users/$uid/profile.jpeg',
    'users/$uid/profile.png',
  ]) {
    try {
      final url = await ref.child(path).getDownloadURL();
      if (url.trim().isNotEmpty) return url.trim();
    } catch (_) {}
  }

  return null;
}

Future<String?> _getPhotoUrlCached(String uid) {
  return _photoFutureCache.putIfAbsent(uid, () => _resolveProfilePhotoUrl(uid));
}

// Map role -> single-letter code for non-students
String _roleInitial(String role) {
  switch (role.trim().toLowerCase()) {
    case 'admin':   return 'A';
    case 'brand':   return 'B';
    case 'guardian':return 'G';
    case 'school':  return 'S';
    default:        return '?';
  }
}



class _RoleAwareAvatar extends StatelessWidget {
  final String uid;
  final String role;
  final double size;

  const _RoleAwareAvatar({
    required this.uid,
    required this.role,
    this.size = 28,
  });

  @override
  Widget build(BuildContext context) {
    // ✅ Always try to resolve a profile photo for ANY role (Student/Brand/Guardian/School/Admin)
    return FutureBuilder<String?>(
      future: _getPhotoUrlCached(uid),
      builder: (context, snap) {
        final url = (snap.data ?? '').trim();

        if (url.isNotEmpty) {
          return ClipOval(
            child: Image.network(
              url,
              width: size,
              height: size,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => _fallback(),
            ),
          );
        }
        return _fallback();
      },
    );
  }

  Widget _fallback() {
    // Still keep a neat fallback if no photo exists
    final letter = _roleInitial(role); // A/B/G/S/? (you already have this helper)
    return CircleAvatar(
      radius: size / 2,
      backgroundColor: Colors.grey.shade300,
      child: Text(
        letter,
        style: TextStyle(
          fontWeight: FontWeight.w800,
          fontSize: size * 0.58,
          color: Colors.black87,
        ),
      ),
    );
  }
}







class ChannelSectionPage extends StatefulWidget {
  final String channelId;
  final double messageListHeight;
  final String userRole; // pass "admin" for admin, else user's role
  final String? adminUid; // required for admin, any fixed string
  final String? initialJumpMessageId;
  final void Function(String id, String name) onprofileTap;

  const ChannelSectionPage({
    super.key,
    required this.channelId,
    required this.userRole,
    this.adminUid,
    this.messageListHeight = 420,
    this.initialJumpMessageId, required this.onprofileTap,
  });

  @override
  State<ChannelSectionPage> createState() => _ChannelSectionPageState();
}

class _ChannelSectionPageState extends State<ChannelSectionPage>
    with WidgetsBindingObserver, AutomaticKeepAliveClientMixin {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  final TextEditingController _controller = TextEditingController();

  final ItemScrollController _itemScrollCtrl = ItemScrollController();
  final ItemPositionsListener _itemPosListener = ItemPositionsListener.create();

  Color _roleColor(String role) {
    switch (role) {
      case 'Student':
        return Colors.blue.withOpacity(0.2);
      case 'Brand':
        return Colors.orange.withOpacity(0.2);
      case 'Guardian':
        return Colors.green.withOpacity(0.2);
      case 'School':
        return Colors.purple.withOpacity(0.2);
      case 'Admin':
        return Colors.grey.withOpacity(0.2);
      default:
        return Colors.grey.withOpacity(0.2);
    }
  }

  Color _roleFgColor(String role) {
    switch (role) {
      case 'Student':
        return Colors.blue.shade200;
      case 'Brand':
        return Colors.orange.shade200;
      case 'Guardian':
        return Colors.green.shade200;
      case 'School':
        return Colors.purple.shade200;
      case 'Admin':
        return Colors.grey.shade300;
      default:
        return Colors.grey.shade300;
    }
  }

  @override
  bool get wantKeepAlive => true;

  Key _listKey = const ValueKey('list-init');
  String? _initialTargetId;
  String? _highlightMessageId;
  int _rebuildNonce = 0;

  bool _uploading = false;
  int _uploadingCount = 0;

  String? _currentUserId;
  String? _currentUserName;
  String? _currentRole;

  // Mentions overlay (channel members only)
  final LayerLink _composerLink = LayerLink();
  OverlayEntry? _mentionOverlay;
  final FocusNode _composerFocus = FocusNode();
  final Set<String> _pendingMentionIds = <String>{};
  int _lastAtIndex = -1;
  List<_Member> _members = [];
  List<_Member> _mentionSuggestions = [];

  // “+” anchored menu
  final LayerLink _plusLink = LayerLink();
  OverlayEntry? _plusMenuOverlay;

  bool _mentionHighlightClearedByScroll = false;
  int _revisitNonce = 0;
  bool _activatedOnce = false;

  bool _searchOpen = false;
  final TextEditingController _searchCtrl = TextEditingController();
  bool _searchLoading = false;
  static const int _scanLimit = 600;
  List<_SearchHit> _hits = [];
  int _hitIndex = -1;

  Future<void> _markChannelRead() async {
    if (_currentUserId == null) return;
    final ref = FirebaseDatabase.instance
        .ref('channels/${widget.channelId}/reads/${_currentUserId!}');
    await ref.set(ServerValue.timestamp);
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);

    FirebaseMessaging.instance.requestPermission();
    FirebaseMessaging.instance.getToken();

    _initialTargetId = (widget.initialJumpMessageId?.isNotEmpty ?? false)
        ? widget.initialJumpMessageId
        : null;
    _highlightMessageId = _initialTargetId;
    _listKey = ValueKey('list-${widget.channelId}-${_initialTargetId ?? "bottom"}');

    if (widget.userRole.toLowerCase() == 'admin') {
      _currentUserId = widget.adminUid ?? 'ADMIN_USER_ID';
      _currentUserName = 'Admin';
      _currentRole = 'Admin';
    } else {
      final user = FirebaseAuth.instance.currentUser;
      _currentUserId = user?.uid;
      _loadUserDetails();
    }

    // Channel members -> mentions only
    FirebaseDatabase.instance
        .ref('channels/${widget.channelId}/members')
        .onValue
        .listen((ev) {
      final list = <_Member>[];
      if (ev.snapshot.value is Map) {
        final rolesMap = Map<Object?, Object?>.from(ev.snapshot.value as Map);
        rolesMap.forEach((roleKey, usersVal) {
          final role = roleKey.toString();
          if (usersVal is Map) {
            final users = Map<Object?, Object?>.from(usersVal);
            users.forEach((uidKey, value) {
              final uid = uidKey.toString();
              final displayName = _extractDisplayName(value, fallback: uid);
              if (uid.isNotEmpty && displayName.isNotEmpty) {
                list.add(_Member(uid: uid, name: displayName, role: role));
              }
            });
          }
        });
      }
      if (mounted) setState(() => _members = list);
    });

    _activateHighlights();
    _markChannelRead();
  }

  @override
  void didUpdateWidget(covariant ChannelSectionPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.channelId != widget.channelId ||
        oldWidget.initialJumpMessageId != widget.initialJumpMessageId) {
      _initialTargetId = (widget.initialJumpMessageId?.isNotEmpty ?? false)
          ? widget.initialJumpMessageId
          : null;
      _highlightMessageId = _initialTargetId;
      _listKey = ValueKey('list-${widget.channelId}-${_initialTargetId ?? "bottom"}-${_rebuildNonce++}');
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_activatedOnce && ModalRoute.of(context)?.isCurrent == true) {
      _activatedOnce = true;
      WidgetsBinding.instance.addPostFrameCallback((_) => _activateHighlights());
    } else if (ModalRoute.of(context)?.isCurrent != true) {
      _activatedOnce = false;
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _activateHighlights();
    }
  }

  void _activateHighlights() {
    setState(() {
      _mentionHighlightClearedByScroll = false;
      _revisitNonce++;
    });
    _markChannelRead();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _mentionOverlay?.remove();
    _plusMenuOverlay?.remove();
    _controller.dispose();
    _composerFocus.dispose();
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadUserDetails() async {
    if (_currentUserId == null) return;
    final ref = FirebaseDatabase.instance.ref('users/${_currentUserId!}');
    final snap = await ref.get();
    if (snap.exists && snap.value is Map) {
      final u = Map<String, dynamic>.from(snap.value as Map);
      setState(() {
        final fullName =
            ((u['first_name'] ?? '') + ' ' + (u['last_name'] ?? '')).trim();
        _currentUserName =
            fullName.isEmpty ? (u['name']?.toString() ?? '') : fullName;
        _currentRole = u['role']?.toString() ?? 'Unknown';
      });
    }
  }

  Future<_SenderMeta> _latestSenderMeta() async {
    if (widget.userRole.toLowerCase() != 'admin' && _currentUserId != null) {
      final ref = FirebaseDatabase.instance.ref('users/${_currentUserId!}');
      final snap = await ref.get();
      if (snap.exists && snap.value is Map) {
        final u = Map<String, dynamic>.from(snap.value as Map);
        final n = ((u['first_name'] ?? '') + ' ' + (u['last_name'] ?? '')).trim();
        final name = n.isEmpty ? (u['name']?.toString() ?? 'Unknown') : n;
        final role = u['role']?.toString() ?? 'Unknown';
        return _SenderMeta(name: name, role: role);
      }
    }
    return _SenderMeta(name: _currentUserName ?? 'Unknown', role: _currentRole ?? 'Unknown');
  }

  Future<void> _sendMessage() async {
    final text = _controller.text.trim();
    if (text.isEmpty || _currentUserId == null) return;

    final mentions = _pendingMentionIds.isEmpty ? <String>[] : _pendingMentionIds.toList();
    final meta = await _latestSenderMeta();

    await FirebaseFirestore.instance
        .collection('channels')
        .doc(widget.channelId)
        .collection('messages')
        .add({
      'type': 'text',
      'text': text,
      'fromMe': true,
      'userId': _currentUserId,
      'role': meta.role,
      'name': meta.name,
      'mentions': mentions,
      'timestamp': FieldValue.serverTimestamp(),
    });

    _controller.clear();
    _pendingMentionIds.clear();
    _lastAtIndex = -1;
    _activateHighlights();
  }

  Future<void> _pickAndUploadAttachments() async {
    if (_currentUserId == null) return;

    try {
      final result = await FilePicker.platform.pickFiles(
        allowMultiple: true,
        type: FileType.custom,
        allowedExtensions: ['jpg', 'jpeg', 'png', 'gif', 'webp', 'pdf'],
        withData: true,
      );
      if (result == null || result.files.isEmpty) return;

      var files = result.files;
      if (files.length > 5) {
        _showSnack('You can select a maximum of 5 files. Taking first 5.');
        files = files.take(5).toList();
      }

      final meta = await _latestSenderMeta();

      setState(() {
        _uploading = true;
        _uploadingCount = files.length;
      });

      for (final f in files) {
        await _uploadSingleAttachment(f, meta);
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

  Future<void> _uploadSingleAttachment(PlatformFile f, _SenderMeta meta) async {
    final name = f.name;
    final ext = name.split('.').last.toLowerCase();

    final isImage = ['jpg', 'jpeg', 'png', 'gif', 'webp'].contains(ext);
    final isPdf = ext == 'pdf';
    if (!(isImage || isPdf)) {
      _showSnack('Only images or PDF allowed. Skipped $name');
      return;
    }

    final bytes = f.bytes;
    if (bytes == null) {
      _showSnack('Could not read file bytes for $name. On web, ensure withData:true.');
      return;
    }

    final mime = isImage ? 'image/$ext' : 'application/pdf';
    final ts = DateTime.now().millisecondsSinceEpoch;
    final storagePath = 'channels/${widget.channelId}/messages/$_currentUserId/${ts}_$name';

    final ref = FirebaseStorage.instance.ref(storagePath);
    final snap =
        await ref.putData(bytes, SettableMetadata(contentType: mime)).whenComplete(() {});
    final url = await snap.ref.getDownloadURL();

    await FirebaseFirestore.instance
        .collection('channels')
        .doc(widget.channelId)
        .collection('messages')
        .add({
      'type': 'file',
      'text': '',
      'fileUrl': url,
      'fileName': name,
      'fileMime': mime,
      'fromMe': true,
      'userId': _currentUserId,
      'role': meta.role,
      'name': meta.name,
      'mentions': [],
      'timestamp': FieldValue.serverTimestamp(),
    });
  }

  Future<void> _shareProfiles(List<_Member> targets) async {
    if (_currentUserId == null || targets.isEmpty) return;
    final meta = await _latestSenderMeta();

    final batch = FirebaseFirestore.instance.batch();
    final msgColl = FirebaseFirestore.instance
        .collection('channels')
        .doc(widget.channelId)
        .collection('messages');

    for (final t in targets) {
      final doc = msgColl.doc();
      batch.set(doc, {
        'type': 'profile',
        'text': '',
        'profile': {
          'uid': t.uid, // kept in payload; not shown in UI
          'name': t.name,
          'role': t.role,
        },
        'fromMe': true,
        'userId': _currentUserId,
        'role': meta.role,
        'name': meta.name,
        'mentions': [],
        'timestamp': FieldValue.serverTimestamp(),
      });
    }
    await batch.commit();

    _showSnack('Shared ${targets.length} profile${targets.length == 1 ? '' : 's'}');
  }

  // Search all users in RTDB
  /// Students-only search (RTDB). Tries an indexed role query first; falls back to client-side filter if needed.
/// Add to your RTDB rules/indexes: { "rules": { "users": { ".indexOn": ["role"] } } }
Future<List<_Member>> _searchAllUsers(String query, {int limit = 50}) async {
  final q = query.trim().toLowerCase();
  if (q.isEmpty) return [];

  final DatabaseReference baseRef = FirebaseDatabase.instance.ref('users');

  // --- OPTION A: Server-side filter (best for scale) ---
  // This requires RTDB index: .indexOn: ["role"] under /users
  // It returns only users with role == "Student".
  try {
    final studentsSnap = await baseRef
        .orderByChild('role')
        .equalTo('Student')
        .get();

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

        // Build haystack for fuzzy text match
        final hay = [
          name,
          email,
          first,
          last,
          ('$first $last').trim(),
        ].join(' ').toLowerCase();

        if (hay.contains(q)) {
          // Safety: only accept Students
          if (role.toLowerCase() == 'student') {
            results.add(_Member(uid: uid, name: name, role: role));
          }
        }
      });

      results.sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
      return results.take(limit).toList();
    }
  } catch (_) {
    // If orderByChild/equalTo fails (no index or rules), fall through to Option B.
  }

  // --- OPTION B: Client-side filter (works without index; worse for scale) ---
  final snap = await baseRef.get();
  if (!snap.exists || snap.value is! Map) return [];

  final Map users = Map<Object?, Object?>.from(snap.value as Map);
  final results = <_Member>[];

  users.forEach((uidKey, raw) {
    final uid = uidKey.toString();

    // Extract fields
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

    // Only Students
    if (role.toLowerCase() != 'student') return;

    // Fuzzy text match
    final hay = [
      name,
      email,
      first,
      last,
      ('$first $last').trim(),
    ].join(' ').toLowerCase();

    if (hay.contains(q)) {
      results.add(_Member(uid: uid, name: name, role: role));
    }
  });

  results.sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
  return results.take(limit).toList();
}


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



  void _jumpToByRebuild(String messageId, {bool highlight = true}) {
    setState(() {
      _initialTargetId = messageId;
      if (highlight) _highlightMessageId = messageId;
      _listKey = ValueKey('list-${widget.channelId}-$messageId-${_rebuildNonce++}');
    });

    Future.delayed(const Duration(seconds: 8), () {
      if (!mounted) return;
      if (_highlightMessageId == messageId) {
        setState(() => _highlightMessageId = null);
      }
    });
  }

  void _toggleSearchOpen() {
    setState(() {
      _searchOpen = !_searchOpen;
      if (!_searchOpen) {
        _resetSearch();
      }
    });
  }

  void _resetSearch() {
    _searchCtrl.clear();
    _searchLoading = false;
    _hits = [];
    _hitIndex = -1;
  }

  Future<void> _runInlineSearch() async {
    final query = _searchCtrl.text.trim();
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
          .collection('channels')
          .doc(widget.channelId)
          .collection('messages')
          .orderBy('timestamp', descending: true)
          .limit(_scanLimit)
          .get();

      final hits = <_SearchHit>[];
      for (final d in qs.docs) {
        final data = d.data();
        final type =
            (data['type'] as String?) ?? (data['fileUrl'] != null ? 'file' : 'text');
        if (type != 'text') continue;

        final txt = (data['text'] as String?) ?? '';
        if (txt.toLowerCase().contains(lc)) {
          hits.add(_SearchHit(
            channelId: widget.channelId,
            messageId: d.id,
            text: txt,
            name: (data['name'] as String?) ?? '',
            role: (data['role'] as String?) ?? 'Unknown',
            ts: (data['timestamp'] is Timestamp)
                ? (data['timestamp'] as Timestamp).toDate()
                : null,
          ));
        }
      }

      setState(() {
        _hits = hits;
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
    if (_hits.isEmpty || _hitIndex == -1) return;
    final next = _hitIndex + 1;
    if (next < _hits.length) _gotoHit(next);
  }

  void _onArrowDown() {
    if (_hits.isEmpty || _hitIndex == -1) return;
    final prev = _hitIndex - 1;
    if (prev >= 0) _gotoHit(prev);
  }

  void _openInfoDrawer() => _scaffoldKey.currentState?.openEndDrawer();

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final chipColor = Colors.purple.shade100;
    final chipTextColor = Colors.purple.shade700;

    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      endDrawer: Drawer(
        elevation: 20,
        width: 420,
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(12, 16, 12, 16),
            child: SingleChildScrollView(
              child: Column(
                children: [
                  Row(
                    children: [
                      const Text('Channel Info',
                          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                      const Spacer(),
                      IconButton(
                        tooltip: 'Close',
                        icon: const Icon(Icons.close),
                        onPressed: () => Navigator.of(context).pop(),
                      ),
                    ],
                  ),
                  const Divider(),
                  ChannelInfoSection(channelId: widget.channelId),
                ],
              ),
            ),
          ),
        ),
      ),
      body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 8,
                      offset: const Offset(0, 2)),
                ],
              ),
              child: Column(
                children: [
                  // Header
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                    child: Row(
                      children: [
                        const CircleAvatar(
                          radius: 16,
                          backgroundColor: Color(0xFFE3E6EA),
                          child: Icon(Icons.person, size: 18, color: Colors.black54),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              FutureBuilder<DataSnapshot>(
                                future: FirebaseDatabase.instance
                                    .ref('channels/${widget.channelId}/name')
                                    .get(),
                                builder: (context, snap) {
                                  if (snap.connectionState == ConnectionState.waiting) {
                                    return const Text('Loading...');
                                  }
                                  return Text(
                                    snap.data?.value?.toString() ?? widget.channelId,
                                    style: const TextStyle(
                                        fontSize: 16, fontWeight: FontWeight.w700),
                                    overflow: TextOverflow.ellipsis,
                                  );
                                },
                              ),
                              const SizedBox(height: 2),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                decoration: BoxDecoration(
                                  color: chipColor,
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: StreamBuilder<DatabaseEvent>(
                                  stream: FirebaseDatabase.instance
                                      .ref('channels/${widget.channelId}/members')
                                      .onValue,
                                  builder: (context, snapshot) {
                                    int count = 0;
                                    if (snapshot.hasData &&
                                        snapshot.data!.snapshot.value is Map) {
                                      final members = snapshot.data!.snapshot.value as Map;
                                      members.forEach((r, vals) {
                                        if (vals is Map) count += vals.length;
                                      });
                                    }
                                    return Text('Channel Members: $count',
                                        style: TextStyle(
                                            fontSize: 11,
                                            color: chipTextColor,
                                            fontWeight: FontWeight.w600));
                                  },
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
                        IconButton(
                          tooltip: 'Channel Info',
                          icon: const Icon(Icons.info_outline, size: 20),
                          onPressed: _openInfoDrawer,
                        ),
                      ],
                    ),
                  ),

                  // WhatsApp-like inline search row
                  AnimatedCrossFade(
                    firstChild: const SizedBox.shrink(),
                    secondChild: _buildWhatsAppSearchBar(),
                    crossFadeState:
                    _searchOpen ? CrossFadeState.showSecond : CrossFadeState.showFirst,
                    duration: const Duration(milliseconds: 180),
                  ),

                  const Divider(height: 1),

                  // Chat + Composer
                  Expanded(
                    child: Column(
                      children: [
                        Expanded(
                          child: StreamBuilder<QuerySnapshot>(
                            stream: FirebaseFirestore.instance
                                .collection('channels')
                                .doc(widget.channelId)
                                .collection('messages')
                                .orderBy('timestamp', descending: false)
                                .snapshots(),
                            builder: (context, snapshot) {
                              if (snapshot.connectionState == ConnectionState.waiting) {
                                return const Center(child: CircularProgressIndicator());
                              }
                              if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                                return const Center(child: Text('No messages yet.'));
                              }

                              final messages = snapshot.data!.docs;

                              return NotificationListener<UserScrollNotification>(
                                onNotification: (n) {
                                  if (!_mentionHighlightClearedByScroll &&
                                      n.direction != ScrollDirection.idle) {
                                    setState(() => _mentionHighlightClearedByScroll = true);
                                  }
                                  return false;
                                },
                                child: ScrollablePositionedList.builder(
                                  key: _listKey,
                                  itemScrollController: _itemScrollCtrl,
                                  itemPositionsListener: _itemPosListener,
                                  reverse: false,
                                  initialScrollIndex: (() {
                                    if (_initialTargetId == null) {
                                      return messages.length - 1;
                                    }
                                    final idx =
                                    messages.indexWhere((d) => d.id == _initialTargetId);
                                    return (idx >= 0 ? idx : messages.length - 1);
                                  })(),
                                  initialAlignment:
                                  _initialTargetId == null ? 1.0 : 0.33,
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 8, vertical: 12),
                                  itemCount: messages.length,
                                  itemBuilder: (context, index) {
                                    final doc = messages[index];
                                    final data =
                                        (doc.data() as Map<String, dynamic>?) ?? {};

                                    final String type = (data['type'] as String?) ??
                                        (data['fileUrl'] != null ? 'file' : 'text');
                                    final String userId =
                                        (data['userId'] as String?) ?? '';
                                    final String role =
                                        (data['role'] as String?) ?? 'Unknown';
                                    final String name = (data['name'] as String?) ??
                                        (userId.isEmpty ? 'Unknown' : userId);
                                    final String text =
                                        (data['text'] as String?) ?? '';

                                    final Timestamp? ts = data['timestamp'] is Timestamp
                                        ? data['timestamp'] as Timestamp
                                        : null;
                                    final DateTime time =
                                        ts?.toDate() ?? DateTime.now();

                                    final bool isMe = userId == _currentUserId;
                                    final List mentionIds = (data['mentions'] is List)
                                        ? List.from(data['mentions'])
                                        : const [];
                                    final bool mentionsMe = _currentUserId != null &&
                                        mentionIds.contains(_currentUserId);
                                    final bool showMentionBorder = mentionsMe &&
                                        !_mentionHighlightClearedByScroll;
                                    final bool highlight =
                                    (doc.id == _highlightMessageId);

                                    Widget content;
                                    if (type == 'file') {
                                      final String fileUrl =
                                          (data['fileUrl'] as String?) ?? '';
                                      final String fileName =
                                          (data['fileName'] as String?) ?? 'File';
                                      final String fileMime =
                                          (data['fileMime'] as String?) ?? '';
                                      final bool isImage =
                                      fileMime.startsWith('image/');

                                      if (isImage) {
                                        content = GestureDetector(
                                          onTap: () =>
                                              _showPhotoFullScreen(fileUrl, name),
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
                                        content = InkWell(
                                          onTap: () => _openUrl(fileUrl),
                                          child: Row(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              const Icon(Icons.picture_as_pdf,
                                                  size: 18, color: Colors.red),
                                              const SizedBox(width: 8),
                                              Flexible(
                                                child: Text(
                                                  fileName,
                                                  style: TextStyle(
                                                    color: _roleFgColor(role),
                                                    decoration:
                                                    TextDecoration.underline,
                                                  ),
                                                  overflow: TextOverflow.ellipsis,
                                                ),
                                              ),
                                            ],
                                          ),
                                        );
                                      }
                                    } else if (type == 'profile') {
  final Map<String, dynamic> p =
      (data['profile'] is Map)
          ? Map<String, dynamic>.from(data['profile'])
          : {};
  final String pUid  = (p['uid']  ?? '').toString();
  final String pName = (p['name'] ?? '').toString();
  final String pRole = (p['role'] ?? 'Unknown').toString();

  content = _ProfileCardBubble(
    uid: pUid, // 🔸 NEW: lets the card resolve the photo
    name: pName.isNotEmpty ? pName : 'Unknown',
    role: pRole,
    fgColor: _roleFgColor(role),
    bgColor: _roleColor(role),
    onView: () {
      widget.onprofileTap(pUid, pName);
    },
  );
}
else {
                                      content = RichText(
                                        text: buildMentionRichText(
                                          text,
                                          base: TextStyle(
                                              color: _roleFgColor(role),
                                              height: 1.35),
                                          mention: TextStyle(
                                            color: _roleFgColor(role),
                                            fontWeight: FontWeight.w800,
                                            decoration: TextDecoration.underline,
                                          ),
                                        ),
                                      );
                                    }

                                    Widget bubble = Container(
                                      constraints:
                                      const BoxConstraints(maxWidth: 520),
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 14, vertical: 12),
                                      decoration: BoxDecoration(
                                        color: _roleColor(role),
                                        border: Border.all(
                                          color: showMentionBorder
                                              ? Colors.amber.shade700
                                              : Colors.transparent,
                                          width: showMentionBorder ? 2 : 0,
                                        ),
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: Column(
                                        crossAxisAlignment: isMe
                                            ? CrossAxisAlignment.end
                                            : CrossAxisAlignment.start,
                                        children: [
                                          Row(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              Text(
                                                name,
                                                style: TextStyle(
                                                  color: _roleFgColor(role),
                                                  fontWeight: FontWeight.bold,
                                                ),
                                              ),
                                              const SizedBox(width: 6),
                                              Container(
                                                padding: const EdgeInsets.symmetric(
                                                    horizontal: 6, vertical: 2),
                                                decoration: BoxDecoration(
                                                  color: _roleFgColor(role)
                                                      .withOpacity(0.2),
                                                  borderRadius:
                                                  BorderRadius.circular(999),
                                                ),
                                                child: Text(
                                                  role,
                                                  style: TextStyle(
                                                    color: _roleFgColor(role),
                                                    fontSize: 9,
                                                    fontWeight: FontWeight.w600,
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ),
                                          const SizedBox(height: 6),
                                          content,
                                          Padding(
                                            padding: const EdgeInsets.only(top: 6),
                                            child: Text(_timeLabel(time),
                                                style: const TextStyle(
                                                    fontSize: 10,
                                                    color: Colors.black54)),
                                          ),
                                        ],
                                      ),
                                    );

                                    final Widget maybeBlink =
                                    (highlight ||
                                        (mentionsMe &&
                                            !_mentionHighlightClearedByScroll))
                                        ? _BlinkHighlight(
                                      key: ValueKey(
                                          '${doc.id}_$_revisitNonce'),
                                      cycles: 4,
                                      child: bubble,
                                    )
                                        : bubble;

                                    return KeyedSubtree(
                                    key: ValueKey(doc.id),
                                    child: Padding(
                                      padding: EdgeInsets.only(bottom: index == messages.length - 1 ? 0 : 12),
                                      child: Row(
                                        mainAxisAlignment: isMe ? MainAxisAlignment.end : MainAxisAlignment.start,
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          if (!isMe) ...[
                                            _RoleAwareAvatar(uid: userId, role: role, size: 28),
                                            const SizedBox(width: 8),
                                          ],
                                          // Keep your existing highlight wrapper around the bubble:
                                          Flexible(child: maybeBlink),
                                          if (isMe) ...[
                                            const SizedBox(width: 8),
                                            _RoleAwareAvatar(uid: userId, role: role, size: 28),
                                          ],
                                        ],
                                      ),
                                    ),
                                  );

                                  },
                                ),
                              );
                            },
                          ),
                        ),

                        // Composer
                        _ComposerBar(
                          controller: _controller,
                          focusNode: _composerFocus,
                          link: _composerLink,
                          plusLink: _plusLink,
                          onChanged: _handleComposerChanged,
                          onSend: _sendMessage,
                          onPlus: _togglePlusMenu,
                          uploading: _uploading,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
      )
    );
  }

  Widget _buildWhatsAppSearchBar() {
    final total = _hits.length;
    final current =
        (_hitIndex >= 0 && total > 0) ? (_hits.length - _hitIndex) : 0;
    final counterText = total == 0 ? '' : '$current/$total';

    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 0, 12, 10),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _searchCtrl,
              textInputAction: TextInputAction.search,
              onSubmitted: (_) => _runInlineSearch(),
              decoration: InputDecoration(
                hintText: 'Search',
                isDense: true,
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide:
                      const BorderSide(color: Color(0xFF9AD2A0), width: 2),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide:
                      const BorderSide(color: Color(0xFF7DBA83), width: 2),
                ),
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
              ),
              onChanged: (_) => setState(() {}),
            ),
          ),
          const SizedBox(width: 6),
          Tooltip(
            message: 'Previous (older)',
            child: IconButton(
              visualDensity: VisualDensity.compact,
              onPressed:
                  (_hits.isNotEmpty && _hitIndex != -1 && _hitIndex + 1 < _hits.length)
                      ? _onArrowUp
                      : null,
              icon: const Icon(Icons.keyboard_arrow_up_rounded),
            ),
          ),
          Tooltip(
            message: 'Next (newer)',
            child: IconButton(
              visualDensity: VisualDensity.compact,
              onPressed: (_hits.isNotEmpty && _hitIndex > 0)
                  ? _onArrowDown
                  : null,
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
              onPressed: _searchCtrl.text.trim().isEmpty || _searchLoading
                  ? null
                  : _runInlineSearch,
              icon: const Icon(Icons.search, size: 18),
              label: const Text('Search'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF3E6AF2),
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
              ),
            ),
          ),
          const SizedBox(width: 6),
          Tooltip(
            message: 'Clear',
            child: IconButton(
              visualDensity: VisualDensity.compact,
              onPressed: (_hits.isNotEmpty ||
                      _searchCtrl.text.isNotEmpty ||
                      _searchLoading)
                  ? () {
                      setState(() {
                        _resetSearch();
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

  // Mentions overlay (channel members)
  void _openMentions(String query) {
    _mentionSuggestions = _members
        .where((m) => m.name.toLowerCase().contains(query.toLowerCase()))
        .take(8)
        .toList();

    _mentionOverlay?.remove();
    if (_mentionSuggestions.isEmpty) return;

    _mentionOverlay = OverlayEntry(
      builder: (_) => Positioned.fill(
        child: IgnorePointer(
          ignoring: false,
          child: Stack(
            children: [
              Positioned.fill(
                child: GestureDetector(
                  onTap: _closeMentions,
                  behavior: HitTestBehavior.translucent,
                ),
              ),
              CompositedTransformFollower(
                link: _composerLink,
                showWhenUnlinked: false,
                offset: const Offset(0, -210),
                child: Material(
                  elevation: 10,
                  borderRadius: BorderRadius.circular(10),
                  child: ConstrainedBox(
                    constraints:
                        const BoxConstraints(maxWidth: 420, maxHeight: 200),
                    child: ListView.builder(
                      padding: const EdgeInsets.symmetric(vertical: 6),
                      shrinkWrap: true,
                      itemCount: _mentionSuggestions.length,
                      itemBuilder: (ctx, i) {
                        final m = _mentionSuggestions[i];
                        return ListTile(
                          dense: true,
                          title: Text(
                            m.name,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(fontWeight: FontWeight.w600),
                          ),
                          onTap: () => _pickMention(m),
                        );
                      },
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );

    Overlay.of(context, rootOverlay: true).insert(_mentionOverlay!);
  }

  void _closeMentions() {
    _mentionOverlay?.remove();
    _mentionOverlay = null;
    _lastAtIndex = -1;
  }

  void _handleComposerChanged(String val) {
    final sel = _controller.selection;
    final caret = sel.isValid ? sel.baseOffset : val.length;
    if (caret <= 0 || caret > val.length) {
      _closeMentions();
      return;
    }

    int i = caret - 1;
    while (i >= 0 && !RegExp(r'\s').hasMatch(val[i])) {
      i--;
    }
    final tokenStart = i + 1;
    if (tokenStart < val.length && val[tokenStart] == '@') {
      final query = val.substring(tokenStart + 1, caret);
      _lastAtIndex = tokenStart;
      _openMentions(query);
    } else {
      _closeMentions();
    }
  }

  void _showPhotoFullScreen(String url, String name) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => _FullScreenPhotoDialog(
        imageUrl: url,
        senderName: name,
      ),
    );
  }

  void _pickMention(_Member m) {
    final text = _controller.text;
    final sel = _controller.selection;
    final caret = sel.isValid ? sel.baseOffset : text.length;
    if (_lastAtIndex < 0 || _lastAtIndex >= text.length) {
      _closeMentions();
      return;
    }

    final newText = text.replaceRange(_lastAtIndex, caret, '@${m.name} ');
    final newCaret = _lastAtIndex + m.name.length + 2;

    _controller.value = TextEditingValue(
      text: newText,
      selection: TextSelection.collapsed(offset: newCaret),
    );

    _pendingMentionIds.add(m.uid);
    _closeMentions();
  }

  String _timeLabel(DateTime t) {
    final h = t.hour % 12 == 0 ? 12 : t.hour % 12;
    final mm = t.minute.toString().padLeft(2, '0');
    final ampm = t.hour >= 12 ? 'pm' : 'am';
    return '$h:$mm $ampm';
  }

  void _showSnack(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  Future<void> _openUrl(String url) async {
    final uri = Uri.parse(url);
    if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      _showSnack('Could not open file.');
    }
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

class _FullScreenPhotoDialog extends StatelessWidget {
  final String imageUrl;
  final String senderName;

  const _FullScreenPhotoDialog({
    required this.imageUrl,
    required this.senderName,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.black,
      child: Stack(
        children: [
          Positioned.fill(
            child: PhotoView(
              imageProvider: NetworkImage(imageUrl),
              backgroundDecoration: const BoxDecoration(color: Colors.black),
              minScale: PhotoViewComputedScale.contained,
              maxScale: PhotoViewComputedScale.covered * 2.0,
            ),
          ),
          Positioned(
            top: 18,
            left: 10,
            child: Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.arrow_back,
                      color: Colors.white, size: 28),
                  onPressed: () => Navigator.of(context).pop(),
                ),
                Text(
                  senderName,
                  style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w500,
                      fontSize: 16),
                ),
              ],
            ),
          ),
          Positioned(
            top: 18,
            right: 10,
            child: IconButton(
              icon: const Icon(Icons.download, color: Colors.white, size: 28),
              onPressed: () async {
                if (kIsWeb) {
                  await WebImageDownloader.downloadImageFromWeb(imageUrl);
                }
              },
              tooltip: 'Download',
            ),
          ),
        ],
      ),
    );
  }
}

// ===== Models & helpers =====
class _SenderMeta {
  final String name;
  final String role;
  _SenderMeta({required this.name, required this.role});
}

class _Member {
  final String uid;
  final String name;
  final String role;
  _Member({required this.uid, required this.name, required this.role});
}

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

InlineSpan buildMentionRichText(
  String text, {
  TextStyle? base,
  TextStyle? mention,
}) {
  final reg = RegExp(r'@([A-Za-z0-9._\- ]{1,40})');
  final spans = <TextSpan>[];
  int last = 0;
  for (final m in reg.allMatches(text)) {
    if (m.start > last) {
      spans.add(TextSpan(text: text.substring(last, m.start), style: base));
    }
    spans.add(TextSpan(
      text: text.substring(m.start, m.end),
      style: mention ?? base?.copyWith(fontWeight: FontWeight.w700),
    ));
    last = m.end;
  }
  if (last < text.length) {
    spans.add(TextSpan(text: text.substring(last), style: base));
  }
  return TextSpan(children: spans);
}

// ----------- Composer Widget (with anchored +) -----------
class _ComposerBar extends StatelessWidget {
  final TextEditingController controller;
  final FocusNode focusNode;
  final LayerLink link;
  final LayerLink plusLink;
  final ValueChanged<String>? onChanged;
  final VoidCallback onSend;
  final VoidCallback onPlus;
  final bool uploading;

  const _ComposerBar({
    required this.controller,
    required this.focusNode,
    required this.link,
    required this.plusLink,
    this.onChanged,
    required this.onSend,
    required this.onPlus,
    required this.uploading,
  });

  @override
  Widget build(BuildContext context) {
    return CompositedTransformTarget(
      link: link,
      child: Container(
        padding: const EdgeInsets.only(left: 10, right: 10, top: 8, bottom: 10),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: const BorderRadius.vertical(bottom: Radius.circular(12)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 4,
              offset: const Offset(0, -1),
            ),
          ],
        ),
        child: Row(
          children: [
            CompositedTransformTarget(
              link: plusLink,
              child: IconButton(
                tooltip: 'More',
                onPressed: uploading ? null : onPlus,
                icon: uploading
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.add_circle_outline),
              ),
            ),
            const SizedBox(width: 4),
            Expanded(
              child: TextField(
                focusNode: focusNode,
                controller: controller,
                decoration: InputDecoration(
                  hintText: 'Write message (type @ to mention)',
                  isDense: true,
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                onChanged: onChanged,
                onSubmitted: (_) => onSend(),
              ),
            ),
            const SizedBox(width: 8),
            ElevatedButton.icon(
              onPressed: onSend,
              icon: const Icon(Icons.send, size: 18, color: Colors.white70),
              label: const Text(
                'Send',
                style:
                    TextStyle(color: Colors.white70, fontWeight: FontWeight.bold),
              ),
              style: ElevatedButton.styleFrom(
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                backgroundColor: const Color(0xFF3E6AF2),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ======= Search Hit Model =======
class _SearchHit {
  final String channelId;
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

// ======= Anchored “+” menu card (above button) =======
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
                subtitle: const Text('Share channel member profile'),
                onTap: onProfiles,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// ======= Profile picker (multi-select) with RTDB search
/// Shows RESULTS (left) and SELECTED LIST (right). Send will send ALL in the selected list.
/// ======= Profile picker (multi-select) PANEL (no Dialog)
/// This is rendered *inside* the glass popup. All colors/styles are tuned
/// for white text on a dark translucent background.
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

    // Reusable whites on dark glass
    const labelStyle = TextStyle(color: Colors.white70, fontSize: 12, fontWeight: FontWeight.w600);
    const bodyStyle  = TextStyle(color: Colors.white,   fontSize: 14);
    const weakText   = TextStyle(color: Colors.white60);

    final divider = Divider(height: 1, color: Colors.white.withOpacity(0.18));
    final borderSide = BorderSide(color: Colors.white.withOpacity(0.22));

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Title is provided by GlassPopupScaffold; keep a bit of top spacing inside content.
        const SizedBox(height: 4),

        // Search
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

        // Two-column layout
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
                // LEFT: Search results with checkboxes
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

                // RIGHT: Selected list
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

        // Footer actions
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


// ======= Profile card bubble (NO UID shown) =======
class _ProfileCardBubble extends StatelessWidget {
  final String uid;              // used to resolve profile photo
  final String name;
  final String role;
  final Color fgColor;
  final Color bgColor;
  final VoidCallback onView;

  const _ProfileCardBubble({
    required this.uid,
    required this.name,
    required this.role,
    required this.fgColor,
    required this.bgColor,
    required this.onView,
  });

  // Role -> single-letter fallback when no photo exists
  String _roleLetter(String roleLower) {
    switch (roleLower) {
      case 'admin':   return 'A';
      case 'brand':   return 'B';
      case 'guardian':return 'G';
      case 'school':  return 'S';
      case 'student': return (name.isNotEmpty ? name[0].toUpperCase() : 'U');
      default:        return (name.isNotEmpty ? name[0].toUpperCase() : 'U');
    }
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<String?>(
      // 🔹 Try to load a photo for EVERY role (not just students)
      future: _getPhotoUrlCached(uid),
      builder: (context, snap) {
        final url = (snap.data ?? '').trim();

        final Widget avatarChild = (url.isNotEmpty)
            ? CircleAvatar(
                radius: 20,
                backgroundImage: NetworkImage(url),
                backgroundColor: Colors.transparent,
                onBackgroundImageError: (_, __) {},
              )
            : CircleAvatar(
                radius: 20,
                backgroundColor: bgColor.withOpacity(0.65),
                child: Text(
                  _roleLetter(role.toLowerCase()),
                  style: TextStyle(color: fgColor, fontWeight: FontWeight.w800),
                ),
              );

        return Container(
          constraints: const BoxConstraints(maxWidth: 460),
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: Colors.black26,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: fgColor.withOpacity(0.25)),
          ),
          child: Row(
            children: [
              avatarChild,
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: fgColor,
                        fontWeight: FontWeight.w700,
                        fontSize: 14,
                      ),
                    ),
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
      },
    );
  }
}

