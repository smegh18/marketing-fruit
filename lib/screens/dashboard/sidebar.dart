import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:Marketing_Fruit/login_screen.dart';
import 'package:Marketing_Fruit/screens/dashboard/theme_provider.dart';

class SidebarWidget extends StatefulWidget {
  final ValueChanged<int> onItemSelected;
  final int selectedIndex;
  final String userRole;

  const SidebarWidget({
    super.key,
    required this.onItemSelected,
    required this.selectedIndex,
    required this.userRole,
  });

  @override
  State<SidebarWidget> createState() => _SidebarWidgetState();
}

class _SidebarWidgetState extends State<SidebarWidget> with SingleTickerProviderStateMixin {
  bool _isCollapsed = false;
  bool _financeExpanded = false;
  bool _marketplaceExpanded = false;
  static const int profileSidebarIndex = 9999; // Chosen to not collide with other indices

  int _profileIndexForRole(String roleLower) {
    return profileSidebarIndex;
  }

  static const int financeOffset = 100;
  static const int marketplaceOffset = 200;

  String? _photoUrl;              // resolved profile photo URL (nullable)
  String? _displayName;           // resolved display name for the name text
  StreamSubscription<DatabaseEvent>? _userSub;

  // ---------- Base Menus ----------
  final List<Map<String, dynamic>> _adminMenu = const [
    {'icon': Icons.dashboard_outlined, 'label': 'Dashboard'},
    {'icon': Icons.video_collection, 'label': 'Content'},
    {'icon': Icons.people, 'label': 'Users'},
    // {'icon': Icons.storefront, 'label': 'Marketplace'},
    {'icon': Icons.image, 'label': 'NFT'},
    {'icon': Icons.shopping_bag_outlined, 'label': 'Products'},
    {'icon': Icons.subscriptions, 'label': 'Subscription'},
    {'icon': Icons.calculate_outlined, 'label': 'Add Game Finance'},
    {'icon': Icons.event_outlined, 'label': 'Events'},
    {'icon': Icons.confirmation_num_outlined, 'label': 'Tickets'},
    {'icon': Icons.satellite_alt, 'label': 'Channels'},
    {'icon': Icons.book, 'label': 'Books'},
  ];

  final List<Map<String, dynamic>> _menuItems = const [
    {'icon': Icons.dashboard_outlined, 'label': 'Dashboard'},
    {'icon': Icons.attach_money_outlined, 'label': 'Finance'},
    {'icon': Icons.school, 'label': 'Study'},
    {'icon': Icons.storefront, 'label': 'Marketplace'},
    {'icon': Icons.message_outlined, 'label': 'Messages'},
    {'icon': Icons.group_outlined, 'label': 'Community'},
    {'icon': Icons.event_outlined, 'label': 'Event'},
    {'icon': Icons.video_collection, 'label': 'Content Section'},
  ];

  final List<Map<String, dynamic>> _financeSubItems = const [
    {'icon': Icons.videogame_asset_outlined, 'label': 'Game Finance'},
    {'icon': Icons.currency_bitcoin, 'label': 'NFT & Crypto'},
  ];

  final List<Map<String, dynamic>> _marketplaceSubItems = const [
    {'icon': Icons.sim_card, 'label': 'Sim Shop'},
    {'icon': Icons.shopping_bag_outlined, 'label': 'Merchandise'},
    {'icon': Icons.image, 'label': 'NFT'},
  ];

  // ---------- Role Menus (Brand/Guardian/School) ----------
  List<Map<String, dynamic>> get _brandItems => [
        _adminMenu[0], // Dashboard
        _adminMenu[2], // Users
        _adminMenu[7], // Events
        {'icon': Icons.message_outlined, 'label': 'Messages'},
        _adminMenu[9], // Channels
        // {'icon': Icons.person, 'label': 'Profile'}, // <-- NEW (index 5)
      ];

  List<Map<String, dynamic>> get _guardianItems => const [
        {'icon': Icons.dashboard_outlined, 'label': 'Dashboard'},
        {'icon': Icons.message_outlined, 'label': 'Messages'},
        {'icon': Icons.satellite_alt, 'label': 'Channels'},
        {'icon': Icons.event_outlined, 'label': 'Event'},
        // {'icon': Icons.person, 'label': 'Profile'}, // <-- NEW (index 5)
      ];

  List<Map<String, dynamic>> get _schoolItems => const [
        {'icon': Icons.dashboard_outlined, 'label': 'Dashboard'},
        {'icon': Icons.message_outlined, 'label': 'Messages'},
        {'icon': Icons.satellite_alt, 'label': 'Channels'},
        {'icon': Icons.event_available_outlined, 'label': 'Events'},
        // {'icon': Icons.person, 'label': 'Profile'}, // <-- NEW (index 5)
      ];

  @override
  void initState() {
    super.initState();

    // expand groups if a subindex is selected initially
    if (widget.selectedIndex >= financeOffset &&
        widget.selectedIndex < financeOffset + _financeSubItems.length) {
      _financeExpanded = true;
    }
    if (widget.selectedIndex >= marketplaceOffset &&
        widget.selectedIndex < marketplaceOffset + _marketplaceSubItems.length) {
      _marketplaceExpanded = true;
    }

    _startProfileWatch(); // photo + display name
  }

  @override
  void didUpdateWidget(covariant SidebarWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.selectedIndex >= financeOffset &&
        widget.selectedIndex < financeOffset + _financeSubItems.length) {
      setState(() => _financeExpanded = true);
    }
    if (widget.selectedIndex >= marketplaceOffset &&
        widget.selectedIndex < marketplaceOffset + _marketplaceSubItems.length) {
      setState(() => _marketplaceExpanded = true);
    }
  }

  @override
  void dispose() {
    _userSub?.cancel();
    super.dispose();
  }

  // ---------- Profile + Name Watching ----------
  Future<void> _startProfileWatch() async {
    final user = FirebaseAuth.instance.currentUser;
    final role = widget.userRole.trim().toLowerCase();

    if (user == null) {
      setState(() {
        _photoUrl = null;
        _displayName = _defaultNameForRole(role);
      });
      return;
    }

    // initial display name from Auth while RTDB loads
    _displayName = _bestDisplayName(
      roleLower: role,
      authDisplayName: user.displayName,
      email: user.email,
    );

    final wantsPhoto = role == 'student' || role == 'brand' || role == 'guardian' || role == 'school';

    // Try to resolve photo for Student + Brand + Guardian + School
    if (wantsPhoto) {
      if ((user.photoURL ?? '').trim().isNotEmpty) {
        _photoUrl = user.photoURL!.trim();
      } else {
        final resolved = await _resolvePhotoUrl(user.uid);
        if (mounted) _photoUrl = resolved;
      }
    } else {
      // Admin remains letter avatar by design
      _photoUrl = null;
    }

    if (mounted) setState(() {});

    // Watch RTDB for live changes to name/photo
    final userRef = FirebaseDatabase.instance.ref('users/${user.uid}');
    _userSub = userRef.onValue.listen((event) async {
      final data = (event.snapshot.value is Map)
          ? Map<String, dynamic>.from(event.snapshot.value as Map)
          : <String, dynamic>{};

      // Update name using role-specific resolution
      final roleName = _getRoleAwareName(role, data);
      if (roleName != null && roleName.trim().isNotEmpty) {
        _displayName = roleName.trim();
      } else {
        // fallback to best guess (auth/displayName/email)
        _displayName = _bestDisplayName(
          roleLower: role,
          authDisplayName: FirebaseAuth.instance.currentUser?.displayName,
          email: FirebaseAuth.instance.currentUser?.email,
        );
      }

      if (wantsPhoto) {
        final candidate = _firstNonEmptyUrl([
          data['profilePhotoUrl'],
          data['profile_photo_url'],
          data['photoURL'],
          data['avatar'],
          data['profile_photo'],
          data['profile_pic'],
          data['photo'],
        ]);

        if (candidate != null && candidate != _photoUrl) {
          _photoUrl = candidate;
        } else if ((_photoUrl == null || _photoUrl!.isEmpty)) {
          final storageUrl = await _tryStoragePaths(user.uid);
          if (storageUrl != null) _photoUrl = storageUrl;
        }
      }

      if (mounted) setState(() {});
    });
  }

  /// Role-aware display name resolution from RTDB
  String? _getRoleAwareName(String roleLower, Map<String, dynamic> data) {
    switch (roleLower) {
      case 'student':
      case 'guardian':
        // Prefer firstName + lastName; fallbacks included
        final composed = _composeFullName(
          data['firstName'] ?? data['first_name'],
          data['lastName'] ?? data['last_name'],
        );
        if (composed.isNotEmpty) return composed;

        // Secondary fallbacks (common keys)
        final possiblePerson = [
          data['fullName'],
          data['full_name'],
          data['name'],
          data['displayName'],
          data['display_name'],
          data['username'],
        ];
        for (final v in possiblePerson) {
          if (v is String && v.trim().isNotEmpty) return v.trim();
        }
        return null;

      case 'school':
        final possibleSchool = [
          data['schoolName'],
          data['school_name'],
          data['nameOfSchool'],
          data['name_of_school'],
          data['instituteName'],
          data['institute_name'],
          data['organization'],
          data['org'],
          data['name'], // final fallback
          data['displayName'],
        ];
        for (final v in possibleSchool) {
          if (v is String && v.trim().isNotEmpty) return v.trim();
        }
        return null;

      case 'brand':
        final possibleBrand = [
          data['brandName'],
          data['brand_name'],
          data['companyName'],
          data['company_name'],
          data['organization'],
          data['org'],
          data['name'], // final fallback
          data['displayName'],
        ];
        for (final v in possibleBrand) {
          if (v is String && v.trim().isNotEmpty) return v.trim();
        }
        return null;

      default:
        // Admin/others: try generic
        return _getNameFromData(data);
    }
  }

  String _composeFullName(dynamic first, dynamic last) {
    final f = (first is String) ? first.trim() : '';
    final l = (last is String) ? last.trim() : '';
    if (f.isEmpty && l.isEmpty) return '';
    if (f.isEmpty) return l;
    if (l.isEmpty) return f;
    return '$f $l';
  }

  String? _getNameFromData(Map<String, dynamic> data) {
    final possible = [
      data['fullName'],
      data['full_name'],
      data['name'],
      data['displayName'],
      data['display_name'],
      data['username'],
      (data['firstName'] != null || data['lastName'] != null)
          ? '${(data['firstName'] ?? '').toString()} ${(data['lastName'] ?? '').toString()}'
          : null,
      (data['first_name'] != null || data['last_name'] != null)
          ? '${(data['first_name'] ?? '').toString()} ${(data['last_name'] ?? '').toString()}'
          : null,
    ];

    for (final val in possible) {
      if (val is String && val.trim().isNotEmpty) return val;
    }
    return null;
  }

  String _bestDisplayName({required String roleLower, String? authDisplayName, String? email}) {
    // If RTDB hasn't arrived yet, provide a reasonable interim value
    if (authDisplayName != null && authDisplayName.trim().isNotEmpty) {
      return authDisplayName.trim();
    }
    if (email != null && email.contains('@')) {
      final base = email.split('@').first;
      if (base.trim().isNotEmpty) return base.trim();
    }
    return _defaultNameForRole(roleLower);
  }

  String _defaultNameForRole(String roleLower) {
    switch (roleLower) {
      case 'student':
      case 'guardian':
        return 'Guest User';
      case 'school':
        return 'Your School';
      case 'brand':
        return 'Your Brand';
      case 'admin':
        return 'Marketing Fruit';
      default:
        return 'User';
    }
  }

  Future<String?> _resolvePhotoUrl(String uid) async {
    // RTDB first
    try {
      final snap = await FirebaseDatabase.instance.ref('users/$uid').get();
      if (snap.exists && snap.value is Map) {
        final data = Map<String, dynamic>.from(snap.value as Map);
        final candidate = _firstNonEmptyUrl([
          data['profilePhotoUrl'],
          data['profile_photo_url'],
          data['photoURL'],
          data['avatar'],
          data['photo'],
          data['profile_pic'],
        ]);
        if (candidate != null) return candidate;
      }
    } catch (_) {
      // ignore and try storage
    }

    // Storage fallback
    return _tryStoragePaths(uid);
  }

  Future<String?> _tryStoragePaths(String uid) async {
    final storage = FirebaseStorage.instance.ref();
    final paths = [
      'users/$uid/profile.jpg',
      'users/$uid/profile.jpeg',
      'users/$uid/profile.png',
    ];

    for (final p in paths) {
      try {
        final url = await storage.child(p).getDownloadURL();
        if ((url).trim().isNotEmpty) return url;
      } catch (_) {
        // try next
      }
    }
    return null;
  }

  String? _firstNonEmptyUrl(List<dynamic> candidates) {
    for (final c in candidates) {
      if (c is String) {
        final s = c.trim();
        if (s.isNotEmpty) {
          final parsed = Uri.tryParse(s);
          if (parsed != null && parsed.hasScheme && parsed.hasAuthority) {
            return s;
          }
        }
      }
    }
    return null;
  }

  // ---------- UI helpers ----------
  Widget _buildTile({
    required bool isSelected,
    required Widget child,
    required Key key,
  }) {
    final theme = Theme.of(context);
    if (isSelected) {
      return Container(
        key: key,
        decoration: BoxDecoration(
          color: theme.highlightColor,
          border: const Border(
            right: BorderSide(color: Color(0xFF005DB2), width: 4),
          ),
        ),
        child: child,
      );
    }
    return Container(key: key, child: child);
  }

  List<Widget> _buildSimpleList(List<Map<String, dynamic>> items, String roleKey) {
    return List<Widget>.generate(items.length, (idx) {
      final item = items[idx];
      final isSelected = widget.selectedIndex == idx;
      return _buildTile(
        isSelected: isSelected,
        key: ValueKey('$roleKey-$idx-${item['label']}'),
        child: ListTile(
          leading: Icon(item['icon'], color: Theme.of(context).colorScheme.onSurface),
          title: _isCollapsed ? null : Text(item['label'], style: Theme.of(context).textTheme.bodyMedium),
          onTap: () => widget.onItemSelected(idx),
        ),
      );
    });
  }

  // ---------- Menu rendering ----------
  List<Widget> _buildMenu() {
    final role = widget.userRole.trim().toLowerCase();

    if (role == "admin") {
      return _buildSimpleList(_adminMenu, 'admin');
    }

    if (role == "brand") {
      return _buildSimpleList(_brandItems, 'brand');
    }

    if (role == "guardian") {
      return _buildSimpleList(_guardianItems, 'guardian');
    }

    if (role == "school") {
      return _buildSimpleList(_schoolItems, 'school');
    }

    // Student: full main menu with expandable groups
    if (role == "student") {
      List<Widget> menu = [];
      for (int i = 0; i < _menuItems.length; i++) {
        final item = _menuItems[i];
        final label = item['label'] as String;
        final isSelected = widget.selectedIndex == i;

        if (label == 'Finance') {
          menu.add(_buildTile(
            isSelected: isSelected,
            key: ValueKey('main-$label'),
            child: ListTile(
              leading: Icon(item['icon'], color: Theme.of(context).colorScheme.onSurface),
              title: AnimatedCrossFade(
                firstChild: const SizedBox.shrink(),
                secondChild: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(label, style: Theme.of(context).textTheme.bodyMedium),
                    Icon(_financeExpanded ? Icons.expand_less : Icons.expand_more),
                  ],
                ),
                crossFadeState: _isCollapsed ? CrossFadeState.showFirst : CrossFadeState.showSecond,
                duration: const Duration(milliseconds: 200),
              ),
              onTap: () {
                setState(() => _financeExpanded = !_financeExpanded);
                // No call to onItemSelected here: expand/collapse only
              },
            ),
          ));

          if (_financeExpanded) {
            for (int j = 0; j < _financeSubItems.length; j++) {
              final subItem = _financeSubItems[j];
              final subIndex = financeOffset + j;
              final isSelectedSub = widget.selectedIndex == subIndex;
              menu.add(_buildTile(
                isSelected: isSelectedSub,
                key: ValueKey('sub-$label-${subItem['label']}'),
                child: Padding(
                  padding: EdgeInsets.only(left: _isCollapsed ? 16.0 : 40.0),
                  child: ListTile(
                    leading: Icon(subItem['icon'], size: 20, color: Theme.of(context).colorScheme.onSurface),
                    title: _isCollapsed
                        ? null
                        : Text(subItem['label'],
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          fontWeight: isSelectedSub ? FontWeight.bold : FontWeight.normal,
                        )),
                    onTap: () => widget.onItemSelected(subIndex),
                  ),
                ),
              ));
            }
          }
        } else if (label == 'Marketplace') {
          menu.add(_buildTile(
            isSelected: isSelected,
            key: ValueKey('main-$label'),
            child: ListTile(
              leading: Icon(item['icon'], color: Theme.of(context).colorScheme.onSurface),
              title: AnimatedCrossFade(
                firstChild: const SizedBox.shrink(),
                secondChild: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(label, style: Theme.of(context).textTheme.bodyMedium),
                    Icon(_marketplaceExpanded ? Icons.expand_less : Icons.expand_more),
                  ],
                ),
                crossFadeState: _isCollapsed ? CrossFadeState.showFirst : CrossFadeState.showSecond,
                duration: const Duration(milliseconds: 200),
              ),
              onTap: () {
                setState(() => _marketplaceExpanded = !_marketplaceExpanded);
                // No call to onItemSelected here: expand/collapse only
              },
            ),
          ));

          if (_marketplaceExpanded) {
            for (int j = 0; j < _marketplaceSubItems.length; j++) {
              final subItem = _marketplaceSubItems[j];
              final subIndex = marketplaceOffset + j;
              final isSelectedSub = widget.selectedIndex == subIndex;
              menu.add(_buildTile(
                isSelected: isSelectedSub,
                key: ValueKey('sub-$label-${subItem['label']}'),
                child: Padding(
                  padding: EdgeInsets.only(left: _isCollapsed ? 16.0 : 40.0),
                  child: ListTile(
                    leading: Icon(subItem['icon'], size: 20, color: Theme.of(context).colorScheme.onSurface),
                    title: _isCollapsed
                        ? null
                        : Text(subItem['label'],
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          fontWeight: isSelectedSub ? FontWeight.bold : FontWeight.normal,
                        )),
                    onTap: () => widget.onItemSelected(subIndex),
                  ),
                ),
              ));
            }
          }
        } else {
          menu.add(_buildTile(
            isSelected: isSelected,
            key: ValueKey('main-$label'),
            child: ListTile(
              leading: Icon(item['icon'], color: Theme.of(context).colorScheme.onSurface),
              title: _isCollapsed
                  ? null
                  : Text(label,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                  )),
              onTap: () => widget.onItemSelected(i),
            ),
          ));
        }
      }
      return menu;
    }

    // Fallback: show Dashboard only
    final item = _adminMenu[0];
    return [
      _buildTile(
        isSelected: widget.selectedIndex == 0,
        key: const ValueKey('only-dashboard-fallback'),
        child: ListTile(
          leading: Icon(item['icon'], color: Theme.of(context).colorScheme.onSurface),
          title: _isCollapsed ? null : Text(item['label'], style: Theme.of(context).textTheme.bodyMedium),
          onTap: () => widget.onItemSelected(0),
        ),
      ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final pixelRatio = MediaQuery.of(context).devicePixelRatio;
    const baselinePixelRatio = 1.0;
    double scaleFactor = 1.0;
    if (pixelRatio > baselinePixelRatio) {
      scaleFactor = (baselinePixelRatio / pixelRatio) * 0.9;
    }
    final role = widget.userRole.trim().toLowerCase();

    // Show photo avatar for Student + Brand + Guardian + School
    final bool wantsPhotoAvatar = role == 'student' || role == 'brand' || role == 'guardian' || role == 'school';
    final bool hasPhoto = (_photoUrl?.trim().isNotEmpty ?? false);

    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      width: _isCollapsed ? 70 * (scaleFactor + 0.25) : 260 * (scaleFactor + 0.25),
      color: theme.cardColor,
      child: Column(
        children: [
          SizedBox(height: 16 * scaleFactor),
          Align(
            alignment: _isCollapsed ? Alignment.topCenter : Alignment.topRight,
            child: IconButton(
              icon: Icon(_isCollapsed ? Icons.table_rows : Icons.arrow_left),
              onPressed: () => setState(() => _isCollapsed = !_isCollapsed),
            ),
          ),

          if (!_isCollapsed) ...[
            MouseRegion(
              cursor: SystemMouseCursors.click,
              child: GestureDetector(
                onTap: () {
                  final idx = _profileIndexForRole(role);
                  widget.onItemSelected(idx);
                },
                child: Column(
                  children: [
                    wantsPhotoAvatar
                        ? (hasPhoto
                            ? _ProfileAvatar(
                                radius: 30 * scaleFactor,
                                photoUrl: _photoUrl,
                              )
                            : (role == 'student' || role == 'guardian'
                                ? _ProfileAvatar(
                                    radius: 30 * scaleFactor,
                                    photoUrl: null, // falls back to person icon
                                  )
                                : _RoleBadgeAvatar(
                                    radius: 30 * scaleFactor,
                                    roleLetter: _roleLetter(role),
                                  )))
                        : _RoleBadgeAvatar(
                            radius: 30 * scaleFactor,
                            roleLetter: _roleLetter(role),
                          ),

                    // ------- Name under avatar (role-aware) -------
                    SizedBox(height: 8 * scaleFactor),
                    _NameLine(
                      name: _displayName ?? _defaultNameForRole(role),
                      color: theme.textTheme.titleMedium?.color ?? colorScheme.onSurface,
                      maxWidth: 200 * (scaleFactor + 0.25),
                      textStyle: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600),
                    ),
                  ],
                ),
              ),
            ),
            SizedBox(height: 10 * scaleFactor),
            if (role == "admin") ...[
              // Text('Marketing Fruit', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
              Text('ADMIN', style: theme.textTheme.bodySmall?.copyWith(color: colorScheme.outline)),
              SizedBox(height: 20 * scaleFactor),
            ],
          ],

          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              IconButton(
                tooltip: 'Toggle Theme',
                icon: Icon(
                  Provider.of<ThemeProvider>(context).isDarkMode ? Icons.dark_mode : Icons.light_mode,
                  color: colorScheme.primary,
                ),
                onPressed: () => Provider.of<ThemeProvider>(context, listen: false).toggleTheme(),
              ),
              if (!_isCollapsed && role == "student")
                IconButton(
                  tooltip: 'Notifications',
                  icon: Icon(Icons.notifications_none_outlined, color: colorScheme.primary),
                  onPressed: () {},
                ),
            ],
          ),

          if (!_isCollapsed && role == "student") ...[
            SizedBox(height: 10 * scaleFactor),
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 12 * scaleFactor),
            ),
            SizedBox(height: 20 * scaleFactor),
            Divider(thickness: 1, color: colorScheme.outlineVariant),
          ],

          Expanded(
            child: ListView(
              key: ValueKey(_isCollapsed.toString() + role),
              children: _buildMenu(),
            ),
          ),

          Padding(
            padding: EdgeInsets.all(12.0 * scaleFactor),
            child: Column(
              children: [
                if (role == "student" || role == "brand" || role == "guardian" || role == "school") ...[
                  _buildPillButton(
                    icon: Icons.person,
                    label: "Profile",
                    onTap: () => widget.onItemSelected(profileSidebarIndex),
                  ),
                  SizedBox(height: 8 * scaleFactor),
                ],
                _buildPillButton(icon: Icons.chat_bubble_outline, label: "Chat Support", onTap: () {}),
                SizedBox(height: 8 * scaleFactor),
                _buildPillButton(icon: Icons.logout, label: "Logout", onTap: () {
                  FirebaseAuth.instance.signOut();
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const LoginScreen()),
                  );
                }),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPillButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    final pixelRatio = MediaQuery.of(context).devicePixelRatio;
    const baselinePixelRatio = 1.0;
    double scaleFactor = 1.0;
    if (pixelRatio > baselinePixelRatio) {
      scaleFactor = (baselinePixelRatio / pixelRatio) * 0.9;
    }
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(30),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: EdgeInsets.symmetric(
          vertical: 10 * scaleFactor,
          horizontal: _isCollapsed ? 10 * scaleFactor : 20 * scaleFactor,
        ),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
          borderRadius: BorderRadius.circular(30),
        ),
        child: Row(
          mainAxisAlignment: _isCollapsed ? MainAxisAlignment.center : MainAxisAlignment.start,
          children: [
            Icon(icon, color: Theme.of(context).colorScheme.primary),
            if (!_isCollapsed) ...[
              SizedBox(width: 10 * scaleFactor),
              Text(label, style: Theme.of(context).textTheme.bodyMedium),
            ],
          ],
        ),
      ),
    );
  }

  // Map role -> single letter
  String _roleLetter(String roleLower) {
    switch (roleLower) {
      case 'admin':
        return 'A';
      case 'brand':
        return 'B';
      case 'guardian':
        return 'G';
      case 'school':
        return 'S';
      default:
        return 'U';
    }
  }
}

/// Circular avatar showing a network photo with graceful fallback (Student/Guardian etc.)
class _ProfileAvatar extends StatelessWidget {
  final double radius;
  final String? photoUrl;

  const _ProfileAvatar({
    required this.radius,
    required this.photoUrl,
  });

  @override
  Widget build(BuildContext context) {
    final url = photoUrl?.trim();
    if (url == null || url.isEmpty) {
      return CircleAvatar(
        radius: radius,
        child: Icon(Icons.person, size: radius),
      );
    }

    return ClipOval(
      child: SizedBox(
        width: radius * 2,
        height: radius * 2,
        child: Image.network(
          url,
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) {
            return CircleAvatar(
              radius: radius,
              child: Icon(Icons.person, size: radius),
            );
          },
        ),
      ),
    );
  }
}

/// Single-letter badge avatar for Admin/Brand/Guardian/School (when no photo)
class _RoleBadgeAvatar extends StatelessWidget {
  final double radius;
  final String roleLetter;

  const _RoleBadgeAvatar({
    required this.radius,
    required this.roleLetter,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return CircleAvatar(
      radius: radius,
      backgroundColor: theme.colorScheme.primary.withOpacity(0.15),
      child: Text(
        roleLetter,
        style: theme.textTheme.titleMedium?.copyWith(
          fontWeight: FontWeight.bold,
          fontSize: radius * 0.9,
          color: theme.colorScheme.primary,
        ),
      ),
    );
  }
}

/// Name line with ellipsis under the avatar
class _NameLine extends StatelessWidget {
  final String name;
  final Color color;
  final double maxWidth;
  final TextStyle? textStyle;

  const _NameLine({
    required this.name,
    required this.color,
    required this.maxWidth,
    this.textStyle,
  });

  @override
  Widget build(BuildContext context) {
    final style = (textStyle ?? Theme.of(context).textTheme.titleSmall)?.copyWith(color: color);
    return ConstrainedBox(
      constraints: BoxConstraints(maxWidth: maxWidth),
      child: Text(
        name,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        textAlign: TextAlign.center,
        style: style,
      ),
    );
  }
}
