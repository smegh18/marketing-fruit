import 'dart:ui';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/foundation.dart'; // For kIsWeb
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:Marketing_Fruit/components/mglasspopup.dart';

class ChildrenSection extends StatefulWidget {
  final String guardianEmail;
  final double width;
  final void Function(String arc, String name, String studentId)? onChildSelected;

  const ChildrenSection({
    super.key,
    required this.guardianEmail,
    this.onChildSelected,
    required this.width,
  });

  @override
  State<ChildrenSection> createState() => _ChildrenSectionState();
}

class _ChildrenSectionState extends State<ChildrenSection> {
  List<Map<String, dynamic>> children = [];
  Map<String, bool> accessStatus = {};
  bool loading = true;
  String? guardianUid;
  bool hasPendingVerification = false;
  List<Map<String, dynamic>> unverifiedChildren = [];

  @override
  void initState() {
    super.initState();
    fetchChildren();
  }

  Future<void> fetchChildren() async {
    final dbRef = FirebaseDatabase.instance.ref().child("users");
    final snapshot = await dbRef.get();
    final matchingChildren = <Map<String, dynamic>>[];
    String? foundGuardianUid;

    for (var child in snapshot.children) {
      final data = Map<String, dynamic>.from(child.value as Map);
      if (data['email'] == widget.guardianEmail && data['role'] == 'Guardian') {
        foundGuardianUid = child.key;
      }
    }
    if (foundGuardianUid == null) {
      setState(() => loading = false);
      return;
    }
    guardianUid = foundGuardianUid;

    for (var child in snapshot.children) {
      final data = Map<String, dynamic>.from(child.value as Map);
      if (data['role'] == 'Student' && data['guardian_email'] == widget.guardianEmail) {
        final playerDetails = data['playerDetails'] as Map<dynamic, dynamic>?;
        final studentId = child.key!;
        final isVerified = data['guardian_verified'] == true;

        if (!isVerified) {
          unverifiedChildren.add({
            'uid': studentId,
            'email': data['email'],
            'username': '${data['first_name'] ?? ''} ${data['last_name'] ?? ''}',
          });
          hasPendingVerification = true;
        }

        final childEntry = {
          'uid': studentId,
          'name': '${data['first_name'] ?? ''} ${data['last_name'] ?? ''}',
          'arc': playerDetails?['arc'] ?? 'Not Started',
          'image': data['profile_image'],
          'progress': (data['progress'] ?? 0.0).toDouble(),
        };

        matchingChildren.add(childEntry);

        final accessRef = FirebaseDatabase.instance
            .ref()
            .child("users/$guardianUid/children/$studentId/access_granted");

        final accessSnapshot = await accessRef.get();
        final accessGranted = accessSnapshot.exists ? accessSnapshot.value == true : true;
        accessStatus[studentId] = accessGranted;
        if (!accessSnapshot.exists) {
          await accessRef.set(true);
        }
      }
    }
    setState(() {
      children = matchingChildren;
      loading = false;
    });

    if (hasPendingVerification) {
      await Future.delayed(const Duration(milliseconds: 300));
      _showVerificationPopup();
    }
  }

  Future<void> _showVerificationPopup() async {
    for (final child in List<Map<String, dynamic>>.from(unverifiedChildren)) {
      final confirmed = await showGlassPopup<bool>(
        context: context,
        title: 'Access Request',
        dismissible: true,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 8),
            Text(
              "The player with Email: ${child['email']} and Username: ${child['username']} has added you as a guardian. Provide them with the access.",
              textAlign: TextAlign.center,
              style: GoogleFonts.poppins(fontSize: 18, color: Colors.white),
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.black,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      elevation: 0,
                    ),
                    onPressed: () => Navigator.of(context).pop(true),
                    child: const Text("Provide Access", style: TextStyle(color: Colors.white)),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.black,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      elevation: 0,
                    ),
                    onPressed: () => Navigator.of(context).pop(false),
                    child: const Text("Reject Access", style: TextStyle(color: Colors.white)),
                  ),
                ),
              ],
            ),
          ],
        ),
      );

      if (confirmed != null) {
        await FirebaseDatabase.instance
            .ref()
            .child("users/${child['uid']}/guardian_verified")
            .set(confirmed);

        setState(() {
          unverifiedChildren.removeWhere((c) => c['uid'] == child['uid']);
          hasPendingVerification = unverifiedChildren.isNotEmpty;
        });
      }
    }
  }

  Future<void> _handleAccessToggle(String childId) async {
    final currentAccess = accessStatus[childId] ?? true;
    final confirm = await showGlassPopup<bool>(
      context: context,
      title: 'Confirm Action',
      dismissible: true,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            currentAccess
                ? "Are you sure you want to restrict user access?"
                : "Are you sure you want to provide user access?",
            textAlign: TextAlign.center,
            style: GoogleFonts.poppins(fontSize: 18, color: Colors.white),
          ),
          const SizedBox(height: 18),
          Row(
            children: [
              Expanded(
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.black,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    elevation: 0,
                  ),
                  onPressed: () => Navigator.of(context).pop(false),
                  child: const Text("No", style: TextStyle(color: Colors.white)),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.black,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    elevation: 0,
                  ),
                  onPressed: () => Navigator.of(context).pop(true),
                  child: const Text("Yes", style: TextStyle(color: Colors.white)),
                ),
              ),
            ],
          ),
        ],
      ),
    );

    if (confirm == true && guardianUid != null) {
      final newAccess = !currentAccess;

      await FirebaseDatabase.instance
          .ref()
          .child("users/$guardianUid/children/$childId/access_granted")
          .set(newAccess);

      setState(() {
        accessStatus[childId] = newAccess;
      });
    }
  }

  void _showAccessRequiredPopup() {
    showGlassPopup<void>(
      context: context,
      title: 'Access Denied',
      dismissible: true,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            "You need to provide access first to view this child's details.",
            textAlign: TextAlign.center,
            style: GoogleFonts.poppins(fontSize: 18, color: Colors.white),
          ),
          const SizedBox(height: 18),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.black,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                elevation: 0,
              ),
              onPressed: () => Navigator.pop(context),
              child: const Text('OK', style: TextStyle(color: Colors.white)),
            ),
          ),
        ],
      ),
    );
  }

  void _showPendingRequestsPopup() {
    showGlassPopup<void>(
      context: context,
      title: 'Pending Access Requests',
      dismissible: true,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (unverifiedChildren.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 8),
              child: Text('No pending requests', style: TextStyle(color: Colors.white70)),
            )
          else
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: unverifiedChildren.length,
              separatorBuilder: (_, __) => Divider(
                height: 1,
                color: Colors.white.withOpacity(0.2),
              ),
              itemBuilder: (context, index) {
                final child = unverifiedChildren[index];
                return ListTile(
                  contentPadding: const EdgeInsets.symmetric(vertical: 6),
                  title: Text(
                    child['username'] ?? 'Unknown',
                    style: GoogleFonts.poppins(fontSize: 16, color: Colors.white, fontWeight: FontWeight.w600),
                  ),
                  subtitle: Text(
                    child['email'] ?? '',
                    style: GoogleFonts.poppins(fontSize: 13, color: Colors.white70),
                  ),
                  trailing: const Icon(Icons.chevron_right, color: Colors.white70),
                  onTap: () async {
                    Navigator.of(context).pop();

                    final confirmed = await showGlassPopup<bool>(
                      context: context,
                      title: 'Access Request',
                      dismissible: true,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            "The player with Email: ${child['email']} and Username: ${child['username']} has added you as a guardian. Provide them with the access.",
                            textAlign: TextAlign.center,
                            style: GoogleFonts.poppins(fontSize: 18, color: Colors.white),
                          ),
                          const SizedBox(height: 18),
                          Row(
                            children: [
                              Expanded(
                                child: ElevatedButton(
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.black,
                                    padding: const EdgeInsets.symmetric(vertical: 14),
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                    elevation: 0,
                                  ),
                                  onPressed: () => Navigator.of(context).pop(true),
                                  child: const Text("Provide Access", style: TextStyle(color: Colors.white)),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: ElevatedButton(
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.black,
                                    padding: const EdgeInsets.symmetric(vertical: 14),
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                    elevation: 0,
                                  ),
                                  onPressed: () => Navigator.of(context).pop(false),
                                  child: const Text("Reject Access", style: TextStyle(color: Colors.white)),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    );
                    if (confirmed != null) {
                      await FirebaseDatabase.instance
                          .ref()
                          .child("users/${child['uid']}/guardian_verified")
                          .set(confirmed);

                      setState(() {
                        unverifiedChildren.removeWhere((c) => c['uid'] == child['uid']);
                        hasPendingVerification = unverifiedChildren.isNotEmpty;
                      });
                    }
                  },
                );
              },
            ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final size = MediaQuery.of(context).size;
    final pixelRatio = MediaQuery.of(context).devicePixelRatio;
    const baselinePixelRatio = 1.0;

    double t = ((pixelRatio - baselinePixelRatio) / baselinePixelRatio).clamp(0.0, 1.0);
    double scaleFactor = lerpDouble(1.0, 0.8, t)!;
    double sfg = lerpDouble(1.0, 0.75, t)!;

    if (pixelRatio >= 2.0 || pixelRatio == 1.0) {
      scaleFactor = 1.0;
      sfg = 1.0;
    } else {
      scaleFactor = (baselinePixelRatio / pixelRatio) * 0.9;
      sfg = (baselinePixelRatio / pixelRatio) * 1.3;
    }

    final cardHeight = pixelRatio >= 2.0 || pixelRatio == 1.0
        ? size.height * 0.42 * sfg
        : size.height * 0.453 * sfg;
    final cardWidth = kIsWeb ? widget.width * 0.25 * sfg : widget.width * 0.8;
    const horizontalPadding = 48.0;

    if (loading) {
      return const Center(child: CircularProgressIndicator());
    }

    return SingleChildScrollView(
      child: Container(
        width: widget.width * sfg,
        margin: EdgeInsets.symmetric(vertical: 12 * scaleFactor),
        decoration: BoxDecoration(
          color: theme.cardColor,
          borderRadius: BorderRadius.circular(16 * scaleFactor),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.5),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        padding: EdgeInsets.symmetric(vertical: 32 * scaleFactor),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: EdgeInsets.symmetric(horizontal: horizontalPadding * scaleFactor),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      "Your Children",
                      style: GoogleFonts.poppins(
                        fontSize: 22 * sfg,
                        fontWeight: FontWeight.bold,
                        color: theme.hintColor,
                      ),
                    ),
                  ),
                  InkWell(
                    onTap: _showPendingRequestsPopup,
                    child: Icon(Icons.notifications_active, color: Colors.redAccent, size: 28 * sfg),
                  ),
                ],
              ),
            ),
            SizedBox(height: 32 * scaleFactor),

            Center(
              child: SizedBox(
                height: cardHeight * 0.8 * (kIsWeb ? 1.0 : children.length.clamp(1, 3).toDouble()),
                // For web: keep original horizontal list, for non-web: column with vertical cards
                child: kIsWeb
                    ? ListView.builder(
                  scrollDirection: Axis.horizontal,
                  padding: EdgeInsets.symmetric(horizontal: horizontalPadding * scaleFactor),
                  itemCount: children.length,
                  itemBuilder: (context, index) {
                    final child = children[index];
                    final hasAccess = accessStatus[child['uid']] ?? true;
                    return _buildChildCard(
                      name: child['name'],
                      arc: child['arc'],
                      imageUrl: child['image'],
                      progress: child['progress'],
                      height: cardHeight,
                      width: cardWidth,
                      scale: sfg,
                      theme: theme,
                      hasAccess: hasAccess,
                      onTap: () {
                        print(widget.onChildSelected);
                        if (!hasAccess) {
                          _showAccessRequiredPopup();
                        } else if (widget.onChildSelected != null) {
                          print("Tapped");
                          widget.onChildSelected!(
                            child['arc'],
                            child['name'],
                            child['uid'],
                          );
                        }
                      },
                      onToggleAccess: () => _handleAccessToggle(child['uid']),
                    );
                  },
                )
                    : SingleChildScrollView(
                  child: Padding(
                    padding: EdgeInsets.symmetric(horizontal: horizontalPadding * scaleFactor),
                    child: Column(
                      children: List.generate(children.length, (index) {
                        final child = children[index];
                        final hasAccess = accessStatus[child['uid']] ?? true;
                        return Padding(
                          padding: EdgeInsets.only(bottom: 20 * scaleFactor),
                          child: _buildChildCard(
                            name: child['name'],
                            arc: child['arc'],
                            imageUrl: child['image'],
                            progress: child['progress'] ?? 0.6,
                            height: cardHeight,
                            width: cardWidth,
                            scale: sfg,
                            theme: theme,
                            hasAccess: hasAccess,
                            onTap: () {
                              if (!hasAccess) {
                                _showAccessRequiredPopup();
                              } else if (widget.onChildSelected != null) {
                                print("Tapped");
                                widget.onChildSelected!(
                                  child['arc'],
                                  child['name'],
                                  child['uid'],
                                );
                              }
                            },
                            onToggleAccess: () => _handleAccessToggle(child['uid']),
                          ),
                        );
                      }),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildChildCard({
    required String name,
    required String arc,
    String? imageUrl,
    required double progress,
    required double height,
    required double width,
    required double scale,
    required ThemeData theme,
    required bool hasAccess,
    required VoidCallback onTap,
    required VoidCallback onToggleAccess,
  }) {
    return Material(
      child: GestureDetector(
        onTap: (){
          print("Tapped");
          onTap();
        },
        child: Container(
          width: width,
          margin: EdgeInsets.only(right: kIsWeb ? width * 0.15 : 0),
          padding: EdgeInsets.all(16 * scale),
          decoration: BoxDecoration(
            color: theme.cardColor,
            borderRadius: BorderRadius.circular(16 * scale),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.5),
                blurRadius: 8,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                height: height * 0.4,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12 * scale),
                  image: DecorationImage(
                    image: AssetImage(getArcImagePath(arc)),
                    fit: BoxFit.cover,
                  ),
                ),
              ),
              SizedBox(height: 12 * scale),
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  CircleAvatar(
                    radius: 16 * scale,
                    backgroundImage: imageUrl != null ? NetworkImage(imageUrl) : null,
                    child: imageUrl == null ? const Icon(Icons.person) : null,
                  ),
                  SizedBox(width: 8 * scale),
                  Expanded(
                    child: Text(
                      name,
                      style: TextStyle(
                        fontSize: 14 * scale,
                        fontWeight: FontWeight.bold,
                        color: theme.hintColor,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  SizedBox(width: 6 * scale),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: hasAccess ? Colors.green : Colors.red,
                      minimumSize: Size(64 * scale, 32 * scale),
                      padding: EdgeInsets.symmetric(horizontal: 12 * scale, vertical: 6 * scale),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12 * scale),
                      ),
                    ),
                    onPressed: onToggleAccess,
                    child: Text(
                      hasAccess ? "Access" : "Denied",
                      style: TextStyle(
                        fontSize: 12 * scale,
                        color: Colors.white,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
              SizedBox(height: 8 * scale),
              Text(
                arc,
                style: TextStyle(
                  fontSize: 13 * scale,
                  fontWeight: FontWeight.w500,
                  color: Colors.teal,
                ),
              ),
              SizedBox(height: 6 * scale),
              LinearProgressIndicator(
                value: (progress.clamp(0.0, 1.0)),
                minHeight: 6 * scale,
                backgroundColor: Colors.grey.shade300,
                color: Colors.teal,
              ),
            ],
          ),
        ),
      ),
    );
  }

  String getArcImagePath(String arc) {
    switch (arc.toLowerCase()) {
      case 'art':
        return 'assets/AA1.png';
      case 'entertainment':
        return 'assets/EA1.png';
      default:
        return 'assets/EA3.png';
    }
  }
}
