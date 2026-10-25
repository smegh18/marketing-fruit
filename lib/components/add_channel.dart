import 'dart:async';
import 'dart:convert';
import 'package:file_picker/file_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';

class AddChannelSection extends StatefulWidget {
  const AddChannelSection({super.key});

  @override
  State<AddChannelSection> createState() => _AddChannelSectionState();
}

class _AddChannelSectionState extends State<AddChannelSection>
    with SingleTickerProviderStateMixin {
  final _nameCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  final List<String> _roles = const ['Student', 'Guardian', 'Brand', 'School'];
  late TabController _tabController;

  // Selected members per role (Set by userId to avoid duplicates)
  final Map<String, Map<String, Map<String, String>>> _membersByRole = {
    'Student': {},
    'Guardian': {},
    'Brand': {},
    'School': {},
  };

  // Search input, focus and debounce per role
  final Map<String, TextEditingController> _searchCtrlByRole = {
    'Student': TextEditingController(),
    'Guardian': TextEditingController(),
    'Brand': TextEditingController(),
    'School': TextEditingController(),
  };
  final Map<String, FocusNode> _focusByRole = {
    'Student': FocusNode(),
    'Guardian': FocusNode(),
    'Brand': FocusNode(),
    'School': FocusNode(),
  };
  final Map<String, Timer?> _debounceByRole = {
    'Student': null,
    'Guardian': null,
    'Brand': null,
    'School': null,
  };

  // Suggestions that render INLINE (no Overlay headaches)
  final Map<String, List<Map<String, String>>> _suggestionsByRole = {
    'Student': [],
    'Guardian': [],
    'Brand': [],
    'School': [],
  };
  final Map<String, bool> _isSearchingByRole = {
    'Student': false,
    'Guardian': false,
    'Brand': false,
    'School': false,
  };

  Uint8List? _iconBytes;
  String? _iconExt;

  bool _showMembersSection = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: _roles.length, vsync: this);
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _descCtrl.dispose();
    for (final r in _roles) {
      _searchCtrlByRole[r]?.dispose();
      _focusByRole[r]?.dispose();
      _debounceByRole[r]?.cancel();
    }
    _tabController.dispose();
    super.dispose();
  }

  // ---------------- Image picker ----------------
  Future<void> _pickChannelIcon() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.image,
        withData: true,
      );
      if (result != null && result.files.single.bytes != null) {
        final f = result.files.single;
        setState(() {
          _iconBytes = f.bytes;
          _iconExt = (f.extension ?? 'png').toLowerCase();
        });
      } else {
        _snack('No image selected.');
      }
    } catch (e) {
      _snack('File picker failed: $e');
    }
  }

  // ---------------- Search (debounced) ----------------
  void _onSearchChanged(String role, String text) {
    _debounceByRole[role]?.cancel();
    _debounceByRole[role] = Timer(const Duration(milliseconds: 300), () async {
      await _runSuggestionQuery(role, text);
    });
  }

  Future<void> _runSuggestionQuery(String role, String rawQuery) async {
    final query = rawQuery.trim().toLowerCase();
    if (query.length < 2) {
      setState(() {
        _suggestionsByRole[role] = [];
      });
      return;
    }
    setState(() => _isSearchingByRole[role] = true);

    try {
      final ref = FirebaseDatabase.instance.ref('users');
      final snap = await ref.get();
      final List<Map<String, String>> matches = [];

      if (snap.exists && snap.value is Map) {
        final map = (snap.value as Map<Object?, Object?>);
        for (final entry in map.entries) {
          final userId = entry.key?.toString() ?? '';
          if (userId.isEmpty) continue;

          final user = (entry.value as Map<Object?, Object?>?) ?? {};
          final uRole = user['role']?.toString() ?? '';
          if (uRole != role) continue;

          final first = (user['first_name'] ?? '').toString();
          final last = (user['last_name'] ?? '').toString();
          final email = (user['email'] ?? '').toString();
          final name = '$first $last'.trim();

          if (first.toLowerCase().contains(query) ||
              last.toLowerCase().contains(query) ||
              name.toLowerCase().contains(query) ||
              email.toLowerCase().contains(query)) {
            matches.add({
              'userId': userId,
              'name': name.isEmpty ? email : name,
              'email': email,
            });
          }
        }
      }

      // Hide already selected users
      final selected = _membersByRole[role]!;
      final filtered = matches
          .where((m) => !selected.containsKey(m['userId']))
          .take(8)
          .toList();

      setState(() {
        _suggestionsByRole[role] = filtered;
      });
    } catch (e) {
      _snack('Search failed: $e');
    } finally {
      setState(() => _isSearchingByRole[role] = false);
    }
  }

  // ---------------- Add/Remove members ----------------
  void _addMember(String role, Map<String, String> user) {
    final id = user['userId'] ?? '';
    if (id.isEmpty) return;
    setState(() {
      _membersByRole[role]![id] = user;
      _suggestionsByRole[role] =
          _suggestionsByRole[role]!.where((s) => s['userId'] != id).toList();
      _searchCtrlByRole[role]!.clear();
    });
  }

  void _removeMember(String role, String userId) {
    setState(() {
      _membersByRole[role]!.remove(userId);
    });
  }

  // ---------------- Submit channel ----------------
  Future<void> _submitChannel() async {
    final name = _nameCtrl.text.trim();
    final desc = _descCtrl.text.trim();
    if (name.isEmpty) {
      _snack('Channel name is required');
      return;
    }

    try {
      final channelsRef = FirebaseDatabase.instance.ref('channels');
      final key = channelsRef.push().key;
      if (key == null) throw Exception('Failed to create channel key');

      // Upload icon if provided
      String logoUrl = '';
      if (_iconBytes != null && _iconExt != null) {
        logoUrl = await _uploadImageUniversal(
          base64String:
          kIsWeb ? base64Encode(_iconBytes!) : null, // base64 path for web
          bytes: _iconBytes,
          fileExt: _iconExt,
          storagePath: 'channels/$key/logo.${_iconExt!}',
        );
      }

      // Persist members as a map keyed by userId for stable structure
      final membersPayload = {
        for (final role in _roles)
          role: {
            for (final entry in _membersByRole[role]!.entries)
              entry.key: {
                'userId': entry.value['userId'],
                'name': entry.value['name'],
                'email': entry.value['email'],
              }
          }
      };

      final payload = {
        'name': name,
        'description': desc,
        'logo': logoUrl,
        'members': membersPayload,
        'created_at': DateTime.now().millisecondsSinceEpoch,
      };

      await channelsRef.child(key).set(payload);

      _snack('Channel "$name" created!');
      _clearAll();
    } catch (e) {
      _snack('Failed to create channel: $e');
    }
  }

  Future<String> _uploadImageUniversal({
    required String? base64String,
    required Uint8List? bytes,
    required String storagePath,
    required String? fileExt,
  }) async {
    final storageRef = FirebaseStorage.instance.ref().child(storagePath);
    TaskSnapshot snap;

    final contentType = _guessMimeType(fileExt);
    if (kIsWeb) {
      if (base64String == null || base64String.isEmpty) {
        throw Exception('No Base64 string provided for web upload');
      }
      final clean = base64String
          .replaceFirst(RegExp(r'data:image/[^;]+;base64,'), '')
          .replaceAll('\n', '')
          .trim();
      try {
        // Try direct base64
        snap = await storageRef.putString(
          clean,
          format: PutStringFormat.base64,
          metadata: SettableMetadata(contentType: contentType),
        );
      } catch (_) {
        // Fallback to bytes
        final fb = base64Decode(clean);
        snap = await storageRef.putData(
          fb,
          SettableMetadata(contentType: contentType),
        );
      }
    } else {
      if (bytes == null) throw Exception('No bytes provided for mobile upload');
      snap = await storageRef.putData(
        bytes,
        SettableMetadata(contentType: contentType),
      );
    }

    return await snap.ref.getDownloadURL();
  }

  String _guessMimeType(String? ext) {
    switch ((ext ?? '').toLowerCase()) {
      case 'jpg':
      case 'jpeg':
        return 'image/jpeg';
      case 'png':
        return 'image/png';
      case 'gif':
        return 'image/gif';
      case 'webp':
        return 'image/webp';
      default:
        return 'application/octet-stream';
    }
  }

  void _clearAll() {
    _nameCtrl.clear();
    _descCtrl.clear();
    setState(() {
      for (final r in _roles) {
        _membersByRole[r]!.clear();
        _searchCtrlByRole[r]!.clear();
        _suggestionsByRole[r] = [];
        _isSearchingByRole[r] = false;
      }
      _iconBytes = null;
      _iconExt = null;
      _showMembersSection = false;
    });
  }

  void _snack(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  // ---------------- UI ----------------
  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final containerWidth = screenWidth * 0.90;

    return SingleChildScrollView(
      child: Container(
        width: containerWidth,
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Channel Details',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 24),

            // Name
            const Text('Channel Name',
                style: TextStyle(fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            TextFormField(
              controller: _nameCtrl,
              decoration: InputDecoration(
                contentPadding:
                const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
            ),
            const SizedBox(height: 16),

            // Icon
            const Text('Channel Icon',
                style: TextStyle(fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            InkWell(
              onTap: _pickChannelIcon,
              borderRadius: BorderRadius.circular(32),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 28,
                    backgroundColor: Colors.white,
                    backgroundImage:
                    _iconBytes != null ? MemoryImage(_iconBytes!) : null,
                    child: _iconBytes == null
                        ? const Icon(Icons.image_outlined, color: Colors.black54)
                        : null,
                  ),
                  const SizedBox(width: 12),
                  Text(
                    _iconBytes != null ? 'Image selected' : 'Tap to choose image',
                    style: TextStyle(
                      color: _iconBytes != null ? Colors.green : Colors.black54,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Description
            const Text('Channel Description',
                style: TextStyle(fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            TextFormField(
              controller: _descCtrl,
              maxLines: 3,
              decoration: InputDecoration(
                contentPadding: const EdgeInsets.all(12),
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
            ),
            const SizedBox(height: 24),

            // Members
            ElevatedButton.icon(
              onPressed: () =>
                  setState(() => _showMembersSection = !_showMembersSection),
              icon: const Icon(Icons.group_add),
              label:
              Text(_showMembersSection ? 'Hide Members' : 'Add Members'),
            ),

            if (_showMembersSection) ...[
              const SizedBox(height: 16),
              TabBar(
                controller: _tabController,
                isScrollable: true,
                labelColor: Theme.of(context).colorScheme.primary,
                unselectedLabelColor: Colors.black87,
                tabs: _roles.map((r) => Tab(text: r)).toList(),
              ),
              const SizedBox(height: 10),
              SizedBox(
                height: 360,
                child: TabBarView(
                  controller: _tabController,
                  children: _roles.map((role) {
                    final selected = _membersByRole[role]!;
                    final suggestions = _suggestionsByRole[role]!;
                    final isSearching = _isSearchingByRole[role]!;
                    final searchCtrl = _searchCtrlByRole[role]!;
                    final focus = _focusByRole[role]!;

                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Selected chips
                        if (selected.isEmpty)
                          const Text('No members yet.',
                              style: TextStyle(color: Colors.black54)),
                        if (selected.isNotEmpty)
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: selected.values.map((user) {
                              final id = user['userId']!;
                              return Chip(
                                label: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(user['name'] ?? '',
                                        style: const TextStyle(
                                            fontWeight: FontWeight.bold)),
                                    Text(user['email'] ?? '',
                                        style:
                                        const TextStyle(fontSize: 10)),
                                  ],
                                ),
                                onDeleted: () => _removeMember(role, id),
                              );
                            }).toList(),
                          ),

                        const SizedBox(height: 12),

                        // Search box
                        TextField(
                          controller: searchCtrl,
                          focusNode: focus,
                          decoration: InputDecoration(
                            hintText: 'Search and add $role',
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 12,
                            ),
                            suffixIcon: isSearching
                                ? const Padding(
                              padding: EdgeInsets.all(10),
                              child: SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(
                                    strokeWidth: 2),
                              ),
                            )
                                : IconButton(
                              icon: const Icon(Icons.search),
                              onPressed: () => _runSuggestionQuery(
                                  role, searchCtrl.text),
                            ),
                          ),
                          onChanged: (v) => _onSearchChanged(role, v),
                        ),

                        // Inline suggestions
                        if (focus.hasFocus &&
                            suggestions.isNotEmpty) ...[
                          const SizedBox(height: 6),
                          Card(
                            margin: EdgeInsets.zero,
                            child: ConstrainedBox(
                              constraints:
                              const BoxConstraints(maxHeight: 200),
                              child: ListView.builder(
                                padding: EdgeInsets.zero,
                                itemCount: suggestions.length,
                                itemBuilder: (_, i) {
                                  final s = suggestions[i];
                                  return ListTile(
                                    dense: true,
                                    title: Text(s['name']?.isNotEmpty == true
                                        ? s['name']!
                                        : (s['email'] ?? '')),
                                    subtitle: Text(s['email'] ?? ''),
                                    trailing: const Icon(Icons.add),
                                    onTap: () => _addMember(role, s),
                                  );
                                },
                              ),
                            ),
                          ),
                        ],

                        const Spacer(),

                        // Summary (compact)
                        if (selected.isNotEmpty)
                          Align(
                            alignment: Alignment.centerLeft,
                            child: Text(
                              '${selected.length} selected',
                              style: const TextStyle(
                                  fontWeight: FontWeight.w600),
                            ),
                          ),
                      ],
                    );
                  }).toList(),
                ),
              ),
              const SizedBox(height: 16),
              _MembersSummaryFlat(membersByRole: _membersByRole),
            ],

            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                OutlinedButton(
                  onPressed: _clearAll,
                  child: const Text('Reset'),
                ),
                const SizedBox(width: 12),
                ElevatedButton(
                  onPressed: _submitChannel,
                  child: const Text('Add Channel'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// -------- Flat summary widget (works with Map keyed by userId) --------
class _MembersSummaryFlat extends StatelessWidget {
  final Map<String, Map<String, Map<String, String>>> membersByRole;
  const _MembersSummaryFlat({required this.membersByRole});

  @override
  Widget build(BuildContext context) {
    final entries = membersByRole.entries
        .where((e) => e.value.isNotEmpty)
        .toList();
    if (entries.isEmpty) {
      return const Text('No members added yet.',
          style: TextStyle(color: Colors.black54));
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Selected Members',
            style: TextStyle(fontWeight: FontWeight.w600)),
        const SizedBox(height: 8),
        Wrap(
          spacing: 10,
          runSpacing: 10,
          children: entries.map((e) {
            return Container(
              padding:
              const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              decoration: BoxDecoration(
                color: const Color(0xFFF7F8FA),
                border: Border.all(color: Colors.grey.shade300),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Wrap(
                spacing: 6,
                children: e.value.values.map((user) {
                  return Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text('${e.key}: ',
                          style:
                          const TextStyle(fontWeight: FontWeight.w600)),
                      Text(user['name'] ?? '',
                          style: const TextStyle(fontWeight: FontWeight.bold)),
                      Text(' (${user['email'] ?? ''})',
                          style: const TextStyle(fontSize: 10)),
                    ],
                  );
                }).toList(),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }
}
