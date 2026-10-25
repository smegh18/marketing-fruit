import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';

class StudentListTab extends StatefulWidget {
  /// Fires when user taps the student's name (or mobile card) to open profile/details
  final void Function(String studentName, String studentId)? onStudentTap;

  /// NEW: Fires when user taps "Chat". If not provided, falls back to onStudentTap.
  final void Function(String studentName, String studentId)? onChatTap;

  const StudentListTab({
    super.key,
    this.onStudentTap,
    this.onChatTap,
  });

  @override
  State<StudentListTab> createState() => _StudentListTabState();
}

class _StudentListTabState extends State<StudentListTab> {
  List<Map<String, dynamic>> students = [];
  bool loading = true;

  @override
  void initState() {
    super.initState();
    fetchStudents();
  }

  Future<void> fetchStudents() async {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) return;

    final dbRef = FirebaseDatabase.instance.ref().child("users");
    final currentUserSnapshot = await dbRef.child(currentUser.uid).get();
    if (!currentUserSnapshot.exists || currentUserSnapshot.value == null) {
      setState(() {
        students = [];
        loading = false;
      });
      return;
    }

    final currentData = Map<String, dynamic>.from(currentUserSnapshot.value as Map);
    final schoolField = (currentData['school'] ?? '').toString().toLowerCase();

    final snapshot = await dbRef.get();
    final result = <Map<String, dynamic>>[];

    for (final user in snapshot.children) {
      if (user.value == null) continue;
      final data = Map<String, dynamic>.from(user.value as Map);
      final studentSchool = (data['school'] ?? '').toString().toLowerCase();

      if (data['role'] == 'Student' && studentSchool == schoolField) {
        final playerDetails = data['playerDetails'] as Map<dynamic, dynamic>?;

        final phone = (data['phone'] ?? data['phone_number'] ?? data['mobile'] ?? '').toString();

        result.add({
          'id': user.key,
          'name': '${data['first_name'] ?? ''} ${data['last_name'] ?? ''}'.trim(),
          'email': (data['email'] ?? '').toString(),
          'phone': phone,
          'arc': (playerDetails?['arc'] ?? '').toString(),
          'activityLevel': (playerDetails?['activity_level'] ?? 'Normal').toString(),
          'progress': _toDouble(data['progress']) ?? 0.6,
          'image': data['profile_image'],
          'cover': playerDetails?['arc_cover'],
        });
      }
    }

    setState(() {
      students = result;
      loading = false;
    });
  }

  static double? _toDouble(dynamic v) {
    if (v == null) return null;
    if (v is double) return v;
    if (v is int) return v.toDouble();
    if (v is String) {
      return double.tryParse(v);
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final w = MediaQuery.of(context).size.width;
    final pixelRatio = MediaQuery.of(context).devicePixelRatio;
    final scale = (1 / pixelRatio).clamp(0.75, 1.0);
    final isMobile = w < 720;

    if (loading) return const Center(child: CircularProgressIndicator());

    return SafeArea(
      child: SingleChildScrollView(
        padding: EdgeInsets.all(16 * scale),
        physics: const AlwaysScrollableScrollPhysics(),
        child: Container(
          decoration: BoxDecoration(
            color: theme.cardColor,
            borderRadius: BorderRadius.circular(16 * scale),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.10),
                blurRadius: 12 * scale,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          padding: EdgeInsets.all(20 * scale),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "Student List",
                style: GoogleFonts.poppins(
                  fontSize: 22 * scale,
                  fontWeight: FontWeight.bold,
                  color: Colors.blue,
                ),
              ),
              SizedBox(height: 12 * scale),
              const Divider(thickness: 1.2),

              if (isMobile)
                _buildMobileCards(scale)
              else
                _buildDesktopTable(scale),
            ],
          ),
        ),
      ),
    );
  }

  // ------------ Desktop/Web table ------------
  Widget _buildDesktopTable(double scale) {
    return Column(
      children: [
        Table(
          columnWidths: const {
            0: FlexColumnWidth(2.5),
            1: FlexColumnWidth(2.5),
            2: FlexColumnWidth(2.0),
            3: FlexColumnWidth(1.8),
            4: FlexColumnWidth(2.6),
            5: FlexColumnWidth(2.8), // CONNECT column
          },
          children: [
            TableRow(
              children: [
                _header("Name", scale),
                _header("Email Address", scale),
                _header("Arc", scale),
                _header("Activity", scale),
                _header("Progress", scale),
                _header("Connect", scale),
              ],
            ),
          ],
        ),
        const Divider(thickness: 1.2),
        ListView.separated(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: students.length,
          separatorBuilder: (_, __) => const Divider(thickness: 1),
          itemBuilder: (context, index) {
            final s = students[index];
            final id = (s['id'] ?? '').toString();
            final name = (s['name'] ?? 'Unknown').toString();
            final email = (s['email'] ?? '').toString();
            final phone = (s['phone'] ?? '').toString();

            return Table(
              columnWidths: const {
                0: FlexColumnWidth(2.5),
                1: FlexColumnWidth(2.5),
                2: FlexColumnWidth(2.0),
                3: FlexColumnWidth(1.8),
                4: FlexColumnWidth(2.6),
                5: FlexColumnWidth(2.8),
              },
              children: [
                TableRow(
                  children: [
                    Padding(
                      padding: EdgeInsets.symmetric(vertical: 12 * scale),
                      child: MouseRegion(
                        cursor: SystemMouseCursors.click,
                        child: GestureDetector(
                          onTap: () => widget.onStudentTap?.call(name, id),
                          child: _avatarName(
                            s['image'],
                            name,
                            scale,
                          ),
                        ),
                      ),
                    ),
                    Padding(
                      padding: EdgeInsets.symmetric(vertical: 12 * scale),
                      child: _cell(email, scale),
                    ),
                    Padding(
                      padding: EdgeInsets.symmetric(vertical: 12 * scale),
                      child: _cell(_formatArc(s['arc'] ?? ''), scale),
                    ),
                    Padding(
                      padding: EdgeInsets.symmetric(vertical: 12 * scale),
                      child: _cell((s['activityLevel'] ?? 'Normal').toString(), scale),
                    ),
                    Padding(
                      padding: EdgeInsets.symmetric(vertical: 12 * scale),
                      child: _percentText((s['progress'] as double?) ?? 0.0, scale),
                    ),
                    Padding(
                      padding: EdgeInsets.symmetric(vertical: 8 * scale),
                      child: _connectButtonsRow(
                        name: name,
                        id: id,
                        email: email,
                        phone: phone,
                        scale: scale,
                      ),
                    ),
                  ],
                ),
              ],
            );
          },
        ),
      ],
    );
  }

  // ------------ Mobile card list ------------
  Widget _buildMobileCards(double scale) {
    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: students.length,
      separatorBuilder: (_, __) => SizedBox(height: 12 * scale),
      itemBuilder: (context, i) {
        final s = students[i];
        final id = (s['id'] ?? '').toString();
        final name = (s['name'] ?? 'Unknown').toString();
        final email = (s['email'] ?? '').toString();
        final phone = (s['phone'] ?? '').toString();

        return _StudentMobileCard(
          name: name,
          email: email,
          phone: phone,
          arcFull: _formatArc((s['arc'] ?? '').toString()),
          activity: (s['activityLevel'] ?? 'Normal').toString(),
          progress: (s['progress'] as double?) ?? 0.0,
          avatarUrl: s['image'] as String?,
          scale: scale,
          onTap: () => widget.onStudentTap?.call(name, id),
          onPhoneTap: phone.isNotEmpty ? () => _launchPhone(phone) : null,
          onChatTap: () {
            if (widget.onChatTap != null) {
              widget.onChatTap!(name, id);
            } else {
              // fallback: use onStudentTap to open existing Messages tab behavior
              widget.onStudentTap?.call(name, id);
            }
          },
        );
      },
    );
  }

  // ------------ helpers (desktop table) ------------
  Widget _header(String label, double scale) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 8 * scale),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 14 * scale,
          fontWeight: FontWeight.bold,
          color: Colors.grey.shade600,
        ),
      ),
    );
  }

  Widget _cell(String value, double scale) {
    return SizedBox(
      width: 120 * scale,
      child: Text(
        value,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(fontSize: 14 * scale),
      ),
    );
  }

  Widget _avatarName(String? imageUrl, String name, double scale) {
    return Row(
      children: [
        CircleAvatar(
          radius: 18 * scale,
          backgroundImage: imageUrl != null && imageUrl.isNotEmpty ? NetworkImage(imageUrl) : null,
          child: (imageUrl == null || imageUrl.isEmpty) ? const Icon(Icons.person) : null,
        ),
        SizedBox(width: 10 * scale),
        Expanded(
          child: Text(
            name,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: 14 * scale,
            ),
          ),
        ),
      ],
    );
  }

  /// Replaces progress bar with a clean percentage label (e.g., "78%")
  Widget _percentText(double progress, double scale) {
    final pct = (progress.clamp(0.0, 1.0) * 100).round();
    return Text(
      '$pct%',
      style: TextStyle(
        fontSize: 14 * scale,
        fontWeight: FontWeight.w600,
        color: Colors.blueGrey.shade800,
      ),
    );
  }

  /// Compact row of 2 buttons (Email removed): Chat + Phone (hover shows number)
  Widget _connectButtonsRow({
    required String name,
    required String id,
    required String email,
    required String phone,
    required double scale,
  }) {
    final hasPhone = phone.isNotEmpty;

    return Wrap(
      alignment: WrapAlignment.start,
      spacing: 8 * scale,
      runSpacing: 8 * scale,
      children: [
        _pillButton(
          label: 'Chat',
          icon: Icons.chat_bubble_outline,
          enabled: true,
          scale: scale,
          onTap: () {
            if (widget.onChatTap != null) {
              widget.onChatTap!(name, id);
            } else {
              widget.onStudentTap?.call(name, id);
            }
          },
        ),
        _PhonePill(
          phone: phone,
          enabled: hasPhone,
          scale: scale,
          onTap: hasPhone ? () => _launchPhone(phone) : null,
        ),
      ],
    );
  }

  Widget _pillButton({
    required String label,
    required IconData icon,
    required bool enabled,
    required double scale,
    VoidCallback? onTap,
  }) {
    final bg = enabled ? Colors.blue.shade50 : Colors.grey.shade200;
    final fg = enabled ? Colors.blue.shade700 : Colors.grey.shade500;
    return Material(
      color: bg,
      borderRadius: BorderRadius.circular(999),
      child: InkWell(
        onTap: enabled ? onTap : null,
        borderRadius: BorderRadius.circular(999),
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 10 * scale, vertical: 6 * scale),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 16 * scale, color: fg),
              SizedBox(width: 6 * scale),
              Text(
                label,
                style: TextStyle(
                  color: fg,
                  fontSize: 12.5 * scale,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _launchPhone(String phone) async {
    final normalized = phone.replaceAll(RegExp(r'\s+'), '');
    final uri = Uri(scheme: 'tel', path: normalized);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  /// Formats arc consistently across views.
  /// - Empty / null / strings containing "not" => "Not Started Arcs Yet"
  /// - Known arcs => "<Name> Arc"
  /// - Others => Title Case + " Arc"
  String _formatArc(String raw) {
    final a = raw.trim().toLowerCase();
    if (a.isEmpty || a.contains('not')) {
      return 'Not Started Arcs Yet';
    }
    if (a.contains('entertain')) return 'Entertainment Arc';
    if (a.contains('recycl')) return 'Recycle Arc';
    if (a.contains('art')) return 'Art Arc';

    // fallback: Title Case + ' Arc'
    final title = raw
        .trim()
        .split(RegExp(r'\s+'))
        .where((w) => w.isNotEmpty)
        .map((w) => w[0].toUpperCase() + (w.length > 1 ? w.substring(1).toLowerCase() : ''))
        .join(' ');
    return title.isEmpty ? 'Not Started Arcs Yet' : '$title Arc';
  }
}

// =================== MOBILE CARD ===================
class _StudentMobileCard extends StatelessWidget {
  final String name;
  final String email;
  final String phone;
  final String arcFull;
  final String activity;
  final double progress;
  final String? avatarUrl;
  final double scale;

  final VoidCallback? onTap;
  final VoidCallback? onPhoneTap;
  final VoidCallback? onChatTap;

  const _StudentMobileCard({
    required this.name,
    required this.email,
    required this.phone,
    required this.arcFull,
    required this.activity,
    required this.progress,
    required this.avatarUrl,
    required this.scale,
    this.onTap,
    this.onPhoneTap,
    this.onChatTap,
  });

  @override
  Widget build(BuildContext context) {
    final hasPhone = phone.isNotEmpty;

    // Clean card
    return Material(
      elevation: 6 * scale,
      borderRadius: BorderRadius.circular(16 * scale),
      clipBehavior: Clip.antiAlias,
      color: Colors.white,
      child: InkWell(
        onTap: onTap,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Top row (avatar + name)
            Padding(
              padding: EdgeInsets.fromLTRB(14 * scale, 12 * scale, 14 * scale, 8 * scale),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 18 * scale,
                    backgroundImage: (avatarUrl != null && avatarUrl!.isNotEmpty)
                        ? NetworkImage(avatarUrl!)
                        : null,
                    child: (avatarUrl == null || avatarUrl!.isEmpty)
                        ? const Icon(Icons.person)
                        : null,
                  ),
                  SizedBox(width: 10 * scale),
                  Expanded(
                    child: Text(
                      name,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 14 * scale,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Arc label (full wording)
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 16 * scale),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    arcFull,
                    style: TextStyle(
                      color: Colors.black87,
                      fontSize: 13 * scale,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  SizedBox(height: 4 * scale),
                  Container(
                    height: 2 * scale,
                    width: 44 * scale,
                    decoration: BoxDecoration(
                      color: Colors.black26,
                      borderRadius: BorderRadius.circular(999),
                    ),
                  ),
                ],
              ),
            ),

            SizedBox(height: 10 * scale),
            const Divider(height: 1),

            // Details area
            Padding(
              padding: EdgeInsets.fromLTRB(16 * scale, 12 * scale, 16 * scale, 8 * scale),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _infoRow(Icons.mail_outline, email, scale),
                  SizedBox(height: 8 * scale),
                  _infoRow(Icons.phone_outlined, phone.isEmpty ? '—' : phone, scale),
                  SizedBox(height: 8 * scale),
                  _infoRow(Icons.local_activity_outlined, 'Activity: $activity', scale),
                  SizedBox(height: 10 * scale),
                  Text(
                    'Progress',
                    style: TextStyle(fontWeight: FontWeight.w600, fontSize: 12 * scale),
                  ),
                  SizedBox(height: 6 * scale),
                  // Percentage instead of progress bar
                  Text(
                    '${(progress.clamp(0.0, 1.0) * 100).round()}%',
                    style: TextStyle(
                      fontSize: 14 * scale,
                      fontWeight: FontWeight.w700,
                      color: Colors.blueGrey.shade800,
                    ),
                  ),
                ],
              ),
            ),

            // Connect buttons row (Email removed)
            Padding(
              padding: EdgeInsets.fromLTRB(12 * scale, 6 * scale, 12 * scale, 14 * scale),
              child: Wrap(
                spacing: 8 * scale,
                runSpacing: 8 * scale,
                children: [
                  _pillButton(
                    label: 'Chat',
                    icon: Icons.chat_bubble_outline,
                    enabled: true,
                    scale: scale,
                    onTap: onChatTap,
                  ),
                  // On mobile there's no hover, but keep a tooltip + tap action
                  Tooltip(
                    message: phone.isEmpty ? 'No phone' : phone,
                    child: _pillButton(
                      label: 'Phone',
                      icon: Icons.phone_outlined,
                      enabled: hasPhone,
                      scale: scale,
                      onTap: onPhoneTap,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _infoRow(IconData icon, String text, double scale) {
    return Row(
      children: [
        Icon(icon, size: 16 * scale, color: Colors.grey.shade700),
        SizedBox(width: 8 * scale),
        Expanded(
          child: Text(
            text,
            style: TextStyle(fontSize: 13 * scale, color: Colors.grey.shade800),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  Widget _pillButton({
    required String label,
    required IconData icon,
    required bool enabled,
    required double scale,
    VoidCallback? onTap,
  }) {
    final bg = enabled ? Colors.blue.shade50 : Colors.grey.shade200;
    final fg = enabled ? Colors.blue.shade700 : Colors.grey.shade500;
    return Material(
      color: bg,
      borderRadius: BorderRadius.circular(999),
      child: InkWell(
        onTap: enabled ? onTap : null,
        borderRadius: BorderRadius.circular(999),
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 10 * scale, vertical: 6 * scale),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 16 * scale, color: fg),
              SizedBox(width: 6 * scale),
              Text(
                label,
                style: TextStyle(
                  color: fg,
                  fontSize: 12.5 * scale,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Desktop-only phone pill that shows the full phone number on hover
class _PhonePill extends StatefulWidget {
  final String phone;
  final bool enabled;
  final double scale;
  final VoidCallback? onTap;

  const _PhonePill({
    required this.phone,
    required this.enabled,
    required this.scale,
    this.onTap,
  });

  @override
  State<_PhonePill> createState() => _PhonePillState();
}

class _PhonePillState extends State<_PhonePill> {
  bool _hovering = false;

  @override
  Widget build(BuildContext context) {
    final hasPhone = widget.enabled && widget.phone.isNotEmpty;
    final bg = hasPhone ? Colors.blue.shade50 : Colors.grey.shade200;
    final fg = hasPhone ? Colors.blue.shade700 : Colors.grey.shade500;

    final label = _hovering && hasPhone ? widget.phone : 'Phone';

    final pill = Material(
      color: bg,
      borderRadius: BorderRadius.circular(999),
      child: InkWell(
        onTap: hasPhone ? widget.onTap : null,
        borderRadius: BorderRadius.circular(999),
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 10 * widget.scale, vertical: 6 * widget.scale),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.phone_outlined, size: 16 * widget.scale, color: fg),
              SizedBox(width: 6 * widget.scale),
              Text(
                label,
                style: TextStyle(
                  color: fg,
                  fontSize: 12.5 * widget.scale,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );

    return Tooltip(
      message: hasPhone ? widget.phone : 'No phone',
      child: MouseRegion(
        onEnter: (_) => setState(() => _hovering = true),
        onExit: (_) => setState(() => _hovering = false),
        cursor: hasPhone ? SystemMouseCursors.click : SystemMouseCursors.basic,
        child: pill,
      ),
    );
  }
}
