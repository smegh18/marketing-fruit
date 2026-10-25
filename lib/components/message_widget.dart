import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

// NEW (for photo resolution)
import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_storage/firebase_storage.dart';

/// --------------------------------------------------------------------------------------
/// Profile-photo resolution with a small in-memory future cache
/// Order: Auth.photoURL (if current user) -> RTDB users/<uid> (common keys) -> Storage
/// If nothing is found, return null and show a fallback avatar (role letter).
/// --------------------------------------------------------------------------------------
final Map<String, Future<String?>> _photoFutureCache = {};

Future<String?> _resolveProfilePhotoUrl(String uid) async {
  final auth = FirebaseAuth.instance.currentUser;

  // 1) If it's the signed-in user, try Auth.photoURL first
  if (auth != null && auth.uid == uid) {
    final p = (auth.photoURL ?? '').trim();
    if (p.isNotEmpty) return p;
  }

  // 2) RTDB: users/<uid> → look for common photo keys with a valid URL shape
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
          pick(m['profile_photo']) ??
          pick(m['profile_pic']);

      if (url != null) return url;
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
    } catch (_) {
      // try next extension
    }
  }

  // No photo found
  return null;
}

/// Get (and memoize) the future to avoid repeated network calls while scrolling.
Future<String?> _getPhotoUrlCached(String uid) {
  return _photoFutureCache.putIfAbsent(uid, () => _resolveProfilePhotoUrl(uid));
}

/// Square avatar with dynamic photo OR role-letter fallback.
/// - When photo exists: shows image
/// - When absent: shows letter tile using role mapping (A/B/G/S/S) or first letter of name
class _UserAvatarSquare extends StatelessWidget {
  final String uid;
  final String displayName;
  final double size;
  final double radius;

  /// Role like: "Student", "Brand", "Guardian", "School", "Admin"
  final String? role;

  const _UserAvatarSquare({
    required this.uid,
    required this.displayName,
    this.size = 40,
    this.radius = 8,
    this.role,
  });

  String _roleLetter(String? r) {
    final rl = (r ?? '').trim().toLowerCase();
    switch (rl) {
      case 'admin':
        return 'A';
      case 'brand':
        return 'B';
      case 'guardian':
        return 'G';
      case 'school':
        return 'S';
      case 'student':
        return 'S';
      default:
        return displayName.isNotEmpty ? displayName[0].toUpperCase() : 'U';
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return FutureBuilder<String?>(
      future: _getPhotoUrlCached(uid),
      builder: (context, snap) {
        final url = (snap.data ?? '').trim();

        if (url.isEmpty) {
          // Role-letter fallback tile
          return Container(
            width: size,
            height: size,
            decoration: BoxDecoration(
              color: theme.colorScheme.primary.withOpacity(0.15),
              borderRadius: BorderRadius.circular(radius),
            ),
            alignment: Alignment.center,
            child: Text(
              _roleLetter(role),
              style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    fontSize: size * 0.48,
                    color: theme.colorScheme.primary,
                  ),
            ),
          );
        }

        // Photo available
        return ClipRRect(
          borderRadius: BorderRadius.circular(radius),
          child: SizedBox(
            width: size,
            height: size,
            child: Image.network(
              url,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => Container(
                width: size,
                height: size,
                decoration: BoxDecoration(
                  color: theme.colorScheme.primary.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(radius),
                ),
                alignment: Alignment.center,
                child: Text(
                  _roleLetter(role),
                  style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        fontSize: size * 0.48,
                        color: theme.colorScheme.primary,
                      ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

class MessagesWidget extends StatelessWidget {
  /// Fraction of screen width this widget should take (0..1).
  final double width;

  /// Optional fixed height. If null, a smart default is used.
  /// The computed height is clamped to avoid overflowing short screens.
  final double? height;

  final bool disabled;

  /// When a row is tapped, call this to open the Messages tab (or your chat screen)
  final void Function(String peerUid, String? peerName, String? peerRole)? onOpenConversation;

  const MessagesWidget({
    super.key,
    required this.width,
    this.height,
    this.disabled = false,
    this.onOpenConversation,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final dpi = MediaQuery.of(context).devicePixelRatio;

    // Keep your original scale logic, but bump defaults
    double scale;
    if (dpi > 1.0 && dpi < 2.0) {
      scale = 1.16;
    } else if (dpi >= 2.0) {
      scale = 0.9;
    } else {
      scale = 0.9;
    }

    final bool isMacOS = Theme.of(context).platform == TargetPlatform.macOS;

    return IgnorePointer(
      ignoring: disabled,
      child: Opacity(
        opacity: disabled ? 0.85 : 1.0,
        child: LayoutBuilder(
          builder: (context, constraints) {
            final screenSize = MediaQuery.of(context).size;
            final screenWidth = screenSize.width;
            final screenHeight = screenSize.height;

            final widgetWidth = (screenWidth * width).clamp(280.0, screenWidth);
            // Increased defaults: 720 (macOS) / 820 (others). Then scale. Then clamp.
            final base = isMacOS ? 920.0 : 820.0;
            final computed = (base * scale);

            // If height is provided, prefer it; otherwise use the larger new default.
            // Clamp to keep some breathing room on short screens.
            final targetHeight = (height ?? computed).clamp(420.0, screenHeight + 120.0);

            final currentUid = FirebaseAuth.instance.currentUser?.uid;

            return SizedBox(
              width: widgetWidth,
              height: screenHeight * 0.9,
              child: Container(
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
                padding: const EdgeInsets.all(20),
                alignment: Alignment.center,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      "Conversations",
                      style: GoogleFonts.poppins(
                        fontWeight: FontWeight.bold,
                        fontSize: 22,
                        color: theme.hintColor,
                      ),
                    ),
                    const SizedBox(height: 20),

                    // If no user, show a friendly message
                    if (currentUid == null)
                      const Expanded(
                        child: Center(child: Text('Please sign in to view your conversations.')),
                      )
                    else
                      Expanded(
                        child: StreamBuilder<QuerySnapshot>(
                          stream: FirebaseFirestore.instance
                              .collection('users')
                              .doc(currentUid)
                              .collection('chats')
                              .snapshots(),
                          builder: (context, chatSnap) {
                            if (chatSnap.connectionState == ConnectionState.waiting) {
                              return const Center(child: CircularProgressIndicator());
                            }
                            if (!chatSnap.hasData || chatSnap.data!.docs.isEmpty) {
                              return const Center(child: Text('No conversations yet.'));
                            }

                            final chats = chatSnap.data!.docs;

                            return ListView.separated(
                              itemCount: chats.length,
                              separatorBuilder: (_, __) => const SizedBox(height: 12),
                              itemBuilder: (context, index) {
                                final chatDoc = chats[index];
                                final peerUid = chatDoc.id;

                                // Prefer the metadata saved in chat doc if present
                                final data = chatDoc.data() as Map<String, dynamic>? ?? {};
                                final peerName = (data['peerName'] as String?) ?? '';
                                final peerRole = (data['peerRole'] as String?) ?? '';

                                // Fallback: also fetch last message preview live
                                final lastMsgStream = chatDoc.reference
                                    .collection('messages')
                                    .orderBy('timestamp', descending: true)
                                    .limit(1)
                                    .snapshots();

                                return StreamBuilder<QuerySnapshot>(
                                  stream: lastMsgStream,
                                  builder: (context, msgSnap) {
                                    String preview = (data['lastMessage'] as String?) ?? '';
                                    if (msgSnap.hasData && msgSnap.data!.docs.isNotEmpty) {
                                      final md = msgSnap.data!.docs.first.data() as Map<String, dynamic>? ?? {};
                                      final type = (md['type'] as String?)?.toLowerCase().trim();
                                      if (type == 'file') {
                                        preview = '📎 Attachment';
                                      } else if (type == 'profile') {
                                        preview = '👤 Profile';
                                      } else if ((md['text'] as String?)?.isNotEmpty == true) {
                                        preview = md['text'];
                                      }
                                    }

                                    return InkWell(
                                      borderRadius: BorderRadius.circular(10),
                                      onTap: () {
                                        onOpenConversation?.call(peerUid, peerName, peerRole);
                                      },
                                      child: Row(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          // Dynamic photo (cached); fallback: role letter tile
                                          _UserAvatarSquare(
                                            uid: peerUid,
                                            displayName: peerName.isNotEmpty ? peerName : peerUid,
                                            size: 40,
                                            radius: 8,
                                            role: peerRole, // <--- role-aware fallback
                                          ),
                                          const SizedBox(width: 12),
                                          Expanded(
                                            child: Column(
                                              crossAxisAlignment: CrossAxisAlignment.start,
                                              children: [
                                                Text(
                                                  peerName.isNotEmpty ? peerName : peerUid,
                                                  style: TextStyle(
                                                    color: theme.hintColor,
                                                    fontWeight: FontWeight.w600,
                                                  ),
                                                  maxLines: 1,
                                                  overflow: TextOverflow.ellipsis,
                                                ),
                                                const SizedBox(height: 4),
                                                Text(
                                                  preview.isNotEmpty ? preview : (peerRole.isNotEmpty ? peerRole : ''),
                                                  style: TextStyle(
                                                    color: theme.hintColor,
                                                    fontSize: 13,
                                                  ),
                                                  maxLines: 1,
                                                  overflow: TextOverflow.ellipsis,
                                                ),
                                              ],
                                            ),
                                          ),
                                        ],
                                      ),
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
            );
          },
        ),
      ),
    );
  }
}
