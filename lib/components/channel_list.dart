import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:cloud_firestore/cloud_firestore.dart' as fs;
import 'package:firebase_database/firebase_database.dart' as rtdb;
import 'package:Marketing_Fruit/components/glasspopup.dart';

enum _SearchMode { channels, messages }

class ChannelsPage extends StatefulWidget {
  final void Function(String channelId, {String? messageId}) onChannelTap;
  final String userRole;

  const ChannelsPage({
    super.key,
    required this.onChannelTap,
    required this.userRole,
  });

  @override
  State<ChannelsPage> createState() => _ChannelsPageState();
}

class _ChannelsPageState extends State<ChannelsPage> {
  DatabaseReference get channelsRef => FirebaseDatabase.instance.ref('channels');
  String? _currentUid;

  // Search state
  final TextEditingController _searchCtrl = TextEditingController();
  String _searchText = '';
  _SearchMode _mode = _SearchMode.channels;

  bool get _isAdmin => widget.userRole.toLowerCase() == 'admin';

  // Message search state
  bool _msgLoading = false;
  List<_MessageHit> _msgResults = [];
  Map<String, String> _channelNameMap = {}; // channelId -> channelName

  // Tunables
  int _cgLimit = 500;
  static const int _perChannelLimit = 150;
  static const int _maxChannelsToScan = 60;
  static const int _finalResultsCap = 500;

  Timer? _debounce;
  int _searchGeneration = 0;

  @override
  void initState() {
    super.initState();
    _currentUid = FirebaseAuth.instance.currentUser?.uid;
    _searchCtrl.addListener(() {
      final v = _searchCtrl.text.trim();
      if (v != _searchText) {
        setState(() => _searchText = v);
        if (_mode == _SearchMode.messages) {
          _debouncedRunMessageSearch();
        }
      }
    });
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<void> _guardOpenChannel(String channelId, {String? messageId}) async {
    try {
      final statusSnap =
      await channelsRef.child(channelId).child('status').get();
      final status = (statusSnap.value ?? 'Active').toString();

      if (!_isAdmin && status.toLowerCase() == 'paused') {
        if (!mounted) return;
        await showGlassPopup(
          context: context,
          title: 'Channel disabled',
          dismissible: true,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'This channel has been disabled by the admin.',
                style: TextStyle(fontSize: 16, color: Colors.white, height: 1.35),
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.black,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    elevation: 0,
                  ),
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text(
                    'OK',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
        return;
      }
    } catch (_) {
      // allow navigation on read error
    }

    widget.onChannelTap(channelId, messageId: messageId);
  }

  void _debouncedRunMessageSearch() {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 350), () {
      if (_mode == _SearchMode.messages) _runMessageSearch();
    });
  }

  Future<void> _ensureChannelNameMap() async {
    if (_channelNameMap.isNotEmpty) return;
    _channelNameMap = await _loadChannelNameMapForUser();
    if (mounted) setState(() {});
  }

  Future<void> _runMessageSearch() async {
    final query = _searchText.trim();
    _debounce?.cancel();

    if (query.isEmpty) {
      setState(() {
        _msgResults = [];
        _msgLoading = false;
      });
      return;
    }

    final int gen = ++_searchGeneration;
    setState(() {
      _msgLoading = true;
      _msgResults = [];
    });

    await _ensureChannelNameMap();
    final lc = query.toLowerCase();

    // Fast path: collectionGroup search
    try {
      final qs = await fs.FirebaseFirestore.instance
          .collectionGroup('messages')
          .orderBy('timestamp', descending: true)
          .limit(_cgLimit)
          .get();

      if (gen != _searchGeneration) return;

      final hits = <_MessageHit>[];
      for (final d in qs.docs) {
        final data = d.data();
        final type = (data['type'] as String?) ??
            (data['fileUrl'] != null ? 'file' : 'text');
        if (type != 'text') continue;

        final txt = (data['text'] as String?) ?? '';
        if (!txt.toLowerCase().contains(lc)) continue;

        final parent = d.reference.parent.parent; // channels/{channelId}
        final channelId = parent?.id ?? 'unknown';

        if (!_channelNameMap.containsKey(channelId)) continue;

        hits.add(_MessageHit(
          channelId: channelId,
          channelName: _channelNameMap[channelId] ?? '#$channelId',
          messageId: d.id,
          text: txt,
          name: (data['name'] as String?) ?? '',
          ts: (data['timestamp'] is fs.Timestamp)
              ? (data['timestamp'] as fs.Timestamp).toDate()
              : null,
        ));
      }

      hits.sort((a, b) =>
          (b.ts ?? DateTime.fromMillisecondsSinceEpoch(0))
              .compareTo(a.ts ?? DateTime.fromMillisecondsSinceEpoch(0)));

      if (mounted && gen == _searchGeneration) {
        setState(() {
          _msgResults = hits.take(_finalResultsCap).toList();
          _msgLoading = false;
        });
      }
      return;
    } on fs.FirebaseException catch (e) {
      final isIndexError = e.code == 'failed-precondition' &&
          (e.message?.contains('COLLECTION_GROUP_DESC') ?? false);
      if (!isIndexError) {
        if (mounted && gen == _searchGeneration) {
          setState(() => _msgLoading = false);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Search failed: ${e.message ?? e.code}')),
          );
        }
        return;
      }
      // else fall through to per-channel fallback
    } catch (e) {
      if (mounted && gen == _searchGeneration) {
        setState(() => _msgLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Search failed: $e')),
        );
      }
      return;
    }

    // Fallback: scan recent messages per channel
    try {
      final hits = <_MessageHit>[];
      for (final channelId in _channelNameMap.keys.take(_maxChannelsToScan)) {
        if (gen != _searchGeneration) return;

        try {
          final qs = await fs.FirebaseFirestore.instance
              .collection('channels')
              .doc(channelId)
              .collection('messages')
              .orderBy('timestamp', descending: true)
              .limit(_perChannelLimit)
              .get();

          if (gen != _searchGeneration) return;

          for (final d in qs.docs) {
            final data = d.data();
            final type = (data['type'] as String?) ??
                (data['fileUrl'] != null ? 'file' : 'text');
            if (type != 'text') continue;

            final txt = (data['text'] as String?) ?? '';
            if (!txt.toLowerCase().contains(lc)) continue;

            hits.add(_MessageHit(
              channelId: channelId,
              channelName: _channelNameMap[channelId] ?? '#$channelId',
              messageId: d.id,
              text: txt,
              name: (data['name'] as String?) ?? '',
              ts: (data['timestamp'] is fs.Timestamp)
                  ? (data['timestamp'] as fs.Timestamp).toDate()
                  : null,
            ));
          }
        } catch (_) {
          // ignore channel errors
        }
      }

      hits.sort((a, b) =>
          (b.ts ?? DateTime.fromMillisecondsSinceEpoch(0))
              .compareTo(a.ts ?? DateTime.fromMillisecondsSinceEpoch(0)));

      if (mounted && gen == _searchGeneration) {
        setState(() {
          _msgResults = hits.take(_finalResultsCap).toList();
          _msgLoading = false;
        });
      }
    } catch (e) {
      if (mounted && gen == _searchGeneration) {
        setState(() => _msgLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Search failed: $e')),
        );
      }
    }
  }

  Future<Map<String, String>> _loadChannelNameMapForUser() async {
    try {
      final snap = await channelsRef.get();
      if (!snap.exists || snap.value is! Map) return {};
      final map = Map<Object?, Object?>.from(snap.value as Map);

      final bool isAdmin = _isAdmin;
      final uid = _currentUid;
      final out = <String, String>{};

      for (final entry in map.entries) {
        final id = entry.key.toString();
        final m = (entry.value is Map)
            ? Map<Object?, Object?>.from(entry.value as Map)
            : {};
        final name = (m['name'] ?? '').toString().trim();
        final channelName = name.isEmpty ? '#$id' : name;

        if (isAdmin) {
          out[id] = channelName;
          continue;
        }

        final members = (m['members'] is Map)
            ? Map<Object?, Object?>.from(m['members'] as Map)
            : {};
        bool isMember = false;
        for (final roleMap in members.values) {
          if (roleMap is Map && uid != null && roleMap.containsKey(uid)) {
            isMember = true;
            break;
          }
        }
        if (isMember) out[id] = channelName;
      }
      return out;
    } catch (_) {
      return {};
    }
  }

  Future<void> _handleChannelTap(_ChannelWithId ch) async {
    await _guardOpenChannel(ch.id);
  }

  Future<void> _confirmDelete(BuildContext context, _ChannelWithId ch) async {
    final didConfirm =
        await showGlassPopup<bool>(
          context: context,
          title: 'Delete channel?',
          dismissible: true,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "Are you sure you want to delete '${ch.name}'? This action can’t be undone.",
                style: const TextStyle(
                  fontSize: 16,
                  color: Colors.white,
                  height: 1.35,
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
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      onPressed: () => Navigator.of(context).pop(false),
                      child: const Text('Cancel',
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
                          borderRadius: BorderRadius.circular(10),
                        ),
                        elevation: 0,
                      ),
                      onPressed: () => Navigator.of(context).pop(true),
                      child: const Text('Delete',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w700,
                          )),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ) ??
            false;

    if (didConfirm) {
      await channelsRef.child(ch.id).remove();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Channel "${ch.name}" deleted')),
        );
      }
    }
  }

  Future<void> _updateStatus(String channelId, String status) async {
    await channelsRef.child(channelId).update({'status': status});
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Status updated to $status')),
    );
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final horizontalPadding = screenWidth > 1000 ? screenWidth * 0.001 : 16.0;
    final isMessagesMode = _mode == _SearchMode.messages;

    // Platform-aware search layout
    final searchControls = kIsWeb
        ? Row(
      children: [
        _ModeToggle(
          mode: _mode,
          onChanged: (m) {
            setState(() {
              _mode = m;
              if (_mode == _SearchMode.channels) {
                _msgResults = [];
                _msgLoading = false;
              } else if (_searchText.isNotEmpty) {
                _debouncedRunMessageSearch();
              }
            });
          },
        ),
        const SizedBox(width: 12),
        Expanded(child: _SearchField(
          controller: _searchCtrl,
          hint: _mode == _SearchMode.channels
              ? 'Search channels by name or description…'
              : 'Search text inside messages across channels…',
          onSubmit: () {
            if (_mode == _SearchMode.messages) _runMessageSearch();
          },
          onClear: () {
            _searchCtrl.clear();
            setState(() {
              _searchText = '';
              _msgResults = [];
              _msgLoading = false;
            });
            FocusScope.of(context).unfocus();
          },
          hasText: _searchText.isNotEmpty,
        )),
        const SizedBox(width: 10),
        SizedBox(
          height: 42,
          child: ElevatedButton.icon(
            onPressed: _mode == _SearchMode.messages
                ? (_msgLoading ? null : _runMessageSearch)
                : null,
            icon: _mode == _SearchMode.messages
                ? (_msgLoading
                ? const SizedBox(
              height: 16,
              width: 16,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
                : const Icon(Icons.search))
                : const Icon(Icons.search, color: Colors.transparent),
            label: Text(_mode == _SearchMode.messages ? 'Search' : ' '),
            style: ElevatedButton.styleFrom(
              backgroundColor: _mode == _SearchMode.messages
                  ? const Color(0xFF3E6AF2)
                  : Colors.grey.shade200,
              foregroundColor: _mode == _SearchMode.messages
                  ? Colors.white
                  : Colors.grey.shade200,
            ),
          ),
        ),
      ],
    )
        : Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _ModeToggle(
          mode: _mode,
          onChanged: (m) {
            setState(() {
              _mode = m;
              if (_mode == _SearchMode.channels) {
                _msgResults = [];
                _msgLoading = false;
              } else if (_searchText.isNotEmpty) {
                _debouncedRunMessageSearch();
              }
            });
          },
        ),
        const SizedBox(height: 12),
        _SearchField(
          controller: _searchCtrl,
          hint: _mode == _SearchMode.channels
              ? 'Search channels by name or description…'
              : 'Search text inside messages across channels…',
          onSubmit: () {
            if (_mode == _SearchMode.messages) _runMessageSearch();
          },
          onClear: () {
            _searchCtrl.clear();
            setState(() {
              _searchText = '';
              _msgResults = [];
              _msgLoading = false;
            });
            FocusScope.of(context).unfocus();
          },
          hasText: _searchText.isNotEmpty,
        ),
        const SizedBox(height: 10),
        if (_mode == _SearchMode.messages)
          Align(
            alignment: Alignment.centerRight,
            child: SizedBox(
              height: 40,
              child: ElevatedButton.icon(
                onPressed: _msgLoading ? null : _runMessageSearch,
                icon: _msgLoading
                    ? const SizedBox(
                  height: 16,
                  width: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
                    : const Icon(Icons.search),
                label: const Text('Search'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF3E6AF2),
                  foregroundColor: Colors.white,
                ),
              ),
            ),
          ),
      ],
    );

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: horizontalPadding, vertical: 8),
      child: Container(
        width: double.infinity,
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(12),
          boxShadow: const [
            BoxShadow(color: Colors.black12, blurRadius: 6, offset: Offset(0, 3)),
          ],
        ),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Row(
                children: [
                  Text(
                    "Channels Page",
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  Spacer(),
                ],
              ),
              const SizedBox(height: 12),

              // Mode toggle + search (platform-aware)
              searchControls,

              const SizedBox(height: 16),

              // Content
              if (isMessagesMode)
                _InlineMessageResults(
                  results: _msgResults,
                  loading: _msgLoading,
                  query: _searchText,
                  onTap: (hit) =>
                      _guardOpenChannel(hit.channelId, messageId: hit.messageId),
                  onLoadMore: () {
                    if (_cgLimit < 2000) {
                      setState(() => _cgLimit += 500);
                      _runMessageSearch();
                    }
                  },
                  canLoadMore: _cgLimit < 2000,
                )
              else
                StreamBuilder<DatabaseEvent>(
                  stream: channelsRef.onValue,
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: Padding(
                          padding: EdgeInsets.all(24), child: CircularProgressIndicator()));
                    }
                    if (!snapshot.hasData ||
                        snapshot.data?.snapshot.value == null) {
                      return const Center(child: Padding(
                          padding: EdgeInsets.all(24), child: Text('No channels found.')));
                    }
                    final raw = snapshot.data!.snapshot.value;
                    if (raw is! Map) {
                      return const Center(
                          child: Padding(
                            padding: EdgeInsets.all(24),
                            child: Text('Unexpected data format.'),
                          ));
                    }

                    final map = raw;
                    final filterLc = _searchText.toLowerCase();

                    final channels = <_ChannelWithId>[];
                    for (final entry in map.entries) {
                      final ch = _ChannelWithId.fromJson(
                        entry.key.toString(),
                        entry.value,
                      );

                      if (!_isAdmin) {
                        final membersMap = (entry.value is Map &&
                            (entry.value as Map)['members'] is Map)
                            ? (entry.value as Map)['members'] as Map
                            : {};
                        bool isMember = false;
                        for (var roleMap in membersMap.values) {
                          if (roleMap is Map &&
                              _currentUid != null &&
                              roleMap.containsKey(_currentUid!)) {
                            isMember = true;
                            break;
                          }
                        }
                        if (!isMember) continue;
                      }

                      if (filterLc.isNotEmpty) {
                        final text =
                        '${ch.name} ${ch.description}'.toLowerCase();
                        if (!text.contains(filterLc)) continue;
                      }

                      channels.add(ch);
                    }

                    channels.sort(
                            (a, b) => b.createdOn.compareTo(a.createdOn));

                    return kIsWeb
                        ? _ChannelsTable(
                      channels: channels,
                      isAdmin: _isAdmin,
                      onChangeStatus: (id, status) => _updateStatus(id, status),
                      onDelete: (ch) => _confirmDelete(context, ch),
                      onChannelTap: (ch) => _handleChannelTap(ch),
                      currentUid: _currentUid,
                    )
                        : _ChannelsCards(
                      channels: channels,
                      isAdmin: _isAdmin,
                      onChangeStatus: (id, status) => _updateStatus(id, status),
                      onDelete: (ch) => _confirmDelete(context, ch),
                      onChannelTap: (ch) => _handleChannelTap(ch),
                      currentUid: _currentUid,
                    );

                  },
                ),
            ],
          ),
        ),
      ),
    );
  }
}

/* ========= Mode Toggle & Search Widgets ========= */

class _ModeToggle extends StatelessWidget {
  final _SearchMode mode;
  final ValueChanged<_SearchMode> onChanged;

  const _ModeToggle({
    required this.mode,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return ToggleButtons(
      isSelected: [
        mode == _SearchMode.channels,
        mode == _SearchMode.messages,
      ],
      onPressed: (i) => onChanged(i == 0 ? _SearchMode.channels : _SearchMode.messages),
      borderRadius: BorderRadius.circular(10),
      constraints: const BoxConstraints(minHeight: 40, minWidth: 110),
      children: const [
        Padding(
          padding: EdgeInsets.symmetric(horizontal: 8),
          child: Text('Channels'),
        ),
        Padding(
          padding: EdgeInsets.symmetric(horizontal: 8),
          child: Text('Messages'),
        ),
      ],
    );
  }
}

class _SearchField extends StatelessWidget {
  final TextEditingController controller;
  final String hint;
  final VoidCallback onSubmit;
  final VoidCallback onClear;
  final bool hasText;

  const _SearchField({
    required this.controller,
    required this.hint,
    required this.onSubmit,
    required this.onClear,
    required this.hasText,
  });

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      textInputAction: TextInputAction.search,
      onSubmitted: (_) => onSubmit(),
      decoration: InputDecoration(
        hintText: hint,
        isDense: true,
        prefixIcon: const Icon(Icons.search),
        suffixIcon: hasText
            ? IconButton(
          tooltip: 'Clear',
          icon: const Icon(Icons.clear),
          onPressed: onClear,
        )
            : null,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      ),
    );
  }
}

/* ========= Inline Messages Results ========= */

class _InlineMessageResults extends StatelessWidget {
  final List<_MessageHit> results;
  final bool loading;
  final String query;
  final ValueChanged<_MessageHit> onTap;
  final VoidCallback onLoadMore;
  final bool canLoadMore;

  const _InlineMessageResults({
    required this.results,
    required this.loading,
    required this.query,
    required this.onTap,
    required this.onLoadMore,
    required this.canLoadMore,
  });

  String _formatTime(DateTime? t) {
    if (t == null) return '';
    final h = t.hour % 12 == 0 ? 12 : t.hour % 12;
    final mm = t.minute.toString().padLeft(2, '0');
    final ampm = t.hour >= 12 ? 'pm' : 'am';
    return '$h:$mm $ampm';
  }

  @override
  Widget build(BuildContext context) {
    if (loading) {
      return const Center(child: Padding(
          padding: EdgeInsets.all(24), child: CircularProgressIndicator()));
    }
    if (results.isEmpty) {
      return const Center(child: Padding(
          padding: EdgeInsets.all(24), child: Text('No results')));
    }

    return Column(
      children: [
        // Use shrinkWrap ListView so the whole page can scroll
        ListView.separated(
          itemCount: results.length,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          separatorBuilder: (_, __) => const Divider(height: 1),
          itemBuilder: (_, i) {
            final r = results[i];
            return InkWell(
              onTap: () => onTap(r),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Channel name first (pill)
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: const Color(0xFFEEF2FF),
                            borderRadius: BorderRadius.circular(999),
                            border: Border.all(color: const Color(0xFFDDE3FF)),
                          ),
                          child: Text(
                            (r.channelName.isEmpty ? '#unknown' : r.channelName),
                            style: const TextStyle(
                              fontWeight: FontWeight.w700,
                              fontSize: 12.5,
                              color: Color(0xFF334155),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),

                    // Message text with highlight
                    _HighlightedText(text: r.text, query: query),

                    const SizedBox(height: 4),

                    // Meta: sender • time
                    Row(
                      children: [
                        Icon(Icons.person_outline,
                            size: 14, color: Colors.grey.shade600),
                        const SizedBox(width: 4),
                        Flexible(
                          child: Text(
                            '${(r.name.isEmpty ? "Unknown" : r.name)} • ${_formatTime(r.ts)}',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey.shade700,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          },
        ),
        if (canLoadMore)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: TextButton.icon(
              onPressed: onLoadMore,
              icon: const Icon(Icons.unfold_more),
              label: const Text('Load more recent messages'),
            ),
          ),
      ],
    );
  }
}

class _HighlightedText extends StatelessWidget {
  final String text;
  final String query;

  const _HighlightedText({
    required this.text,
    required this.query,
  });

  @override
  Widget build(BuildContext context) {
    if (query.isEmpty) {
      return Text(
        text,
        maxLines: 3,
        overflow: TextOverflow.ellipsis,
        style: const TextStyle(
          fontWeight: FontWeight.w600,
          fontSize: 13.5,
        ),
      );
    }

    final lcText = text.toLowerCase();
    final lcQuery = query.toLowerCase();
    final spans = <TextSpan>[];

    int start = 0;
    while (true) {
      final idx = lcText.indexOf(lcQuery, start);
      if (idx < 0) {
        spans.add(TextSpan(text: text.substring(start)));
        break;
      }
      if (idx > start) {
        spans.add(TextSpan(text: text.substring(start, idx)));
      }
      spans.add(
        TextSpan(
          text: text.substring(idx, idx + lcQuery.length),
          style: const TextStyle(
            backgroundColor: Color(0xFFFFF3B0),
            fontWeight: FontWeight.w700,
          ),
        ),
      );
      start = idx + lcQuery.length;
      if (start >= text.length) break;
    }

    return RichText(
      maxLines: 3,
      overflow: TextOverflow.ellipsis,
      text: TextSpan(
        style: const TextStyle(
          color: Colors.black,
          fontSize: 13.5,
          fontWeight: FontWeight.w600,
        ),
        children: spans,
      ),
    );
  }
}

class _ChannelsCards extends StatelessWidget {
  final List<_ChannelWithId> channels;
  final bool isAdmin;
  final void Function(String id, String status) onChangeStatus;
  final void Function(_ChannelWithId ch) onDelete;
  final void Function(_ChannelWithId ch) onChannelTap;
  final String? currentUid;

  const _ChannelsCards({
    required this.channels,
    required this.isAdmin,
    required this.onChangeStatus,
    required this.onDelete,
    required this.onChannelTap,
    required this.currentUid,
  });

  @override
  Widget build(BuildContext context) {
    if (channels.isEmpty) {
      return const Padding(
        padding: EdgeInsets.all(24),
        child: Center(child: Text('No channels found.')),
      );
    }

    // Use a shrink-wrapped, non-scrollable ListView so the outer page scroll works
    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: channels.length,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (context, i) {
        final ch = channels[i];

        return Material(
          elevation: 2,
          borderRadius: BorderRadius.circular(12),
          color: Colors.white,
          child: InkWell(
            borderRadius: BorderRadius.circular(12),
            onTap: () => onChannelTap(ch),
            child: Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey.shade200),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header row: name + optional status chip (non-admin paused)
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          ch.name,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: Colors.blue,
                            decoration: TextDecoration.underline,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 8),
                      if (!isAdmin && ch.status.toLowerCase() == 'paused')
                        const _PausedPill(),
                      if (isAdmin) ...[
                        const SizedBox(width: 8),
                        _StatusActions(
                          status: ch.status,
                          onChangeStatus: (s) => onChangeStatus(ch.id, s),
                          onDelete: () => onDelete(ch),
                        ),
                      ],
                    ],
                  ),

                  const SizedBox(height: 8),

                  // Description
                  if (ch.description.isNotEmpty)
                    Text(
                      ch.description,
                      style: TextStyle(
                        color: Colors.grey.shade800,
                        fontSize: 14,
                        height: 1.35,
                      ),
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                    ),

                  const SizedBox(height: 12),

                  // Meta row: unread badge, created on (admin only)
                  Row(
                    children: [
                      _UnreadBadge(channelId: ch.id, currentUid: currentUid),
                      const Spacer(),
                      if (isAdmin)
                        Row(
                          children: [
                            const Icon(Icons.event, size: 16, color: Colors.black54),
                            const SizedBox(width: 6),
                            Text(
                              _fmtDate(ch.createdOn),
                              style: const TextStyle(
                                fontSize: 13,
                                color: Colors.black87,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  String _fmtDate(DateTime d) {
    final mm = d.month.toString().padLeft(2, '0');
    final dd = d.day.toString().padLeft(2, '0');
    return '${d.year}-$mm-$dd';
  }
}


/* ========= Table Widgets ========= */

class _ChannelsTable extends StatelessWidget {
  final List<_ChannelWithId> channels;
  final bool isAdmin;
  final void Function(String id, String status) onChangeStatus;
  final void Function(_ChannelWithId ch) onDelete;
  final void Function(_ChannelWithId ch) onChannelTap;
  final String? currentUid;

  const _ChannelsTable({
    required this.channels,
    required this.isAdmin,
    required this.onChangeStatus,
    required this.onDelete,
    required this.onChannelTap,
    required this.currentUid,
  });

  @override
  Widget build(BuildContext context) {
    return Scrollbar(
      thumbVisibility: true,
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: LayoutBuilder(
          builder: (context, constraints) {
            // Give the table a definite width so the Rows with Expanded have finite constraints
            final double tableWidth = (constraints.maxWidth.isFinite && constraints.maxWidth > 0)
                ? constraints.maxWidth
                : 0;
            final double effectiveWidth = MediaQuery.of(context).size.width * 0.78;

            return SizedBox(
              width: effectiveWidth,
              child: Column(
                children: [
                  // Header
                  Container(
                    color: Colors.grey[200],
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    child: _TableRowWidget(
                      cells: [
                        const _HeaderCell('Channel Name', flex: 3),
                        const _HeaderCell('Description', flex: 3),
                        const _HeaderCell.icon(Icons.notifications, flex: 1),
                        if (isAdmin) const _HeaderCell('Created On', flex: 2),
                        if (isAdmin) const _HeaderCell('Status', flex: 2),
                      ],
                    ),
                  ),
                  const Divider(height: 1, thickness: 1),

                  // Rows
                  ...channels.map(
                        (ch) => Column(
                      children: [
                        _TableRowWidget(
                          cells: [
                            _BodyCell(
                              GestureDetector(
                                onTap: () => onChannelTap(ch),
                                child: MouseRegion(
                                  cursor: SystemMouseCursors.click,
                                  child: Row(
                                    children: [
                                      Text(
                                        ch.name,
                                        style: const TextStyle(
                                          color: Colors.blue,
                                          decoration: TextDecoration.underline,
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      if (!isAdmin &&
                                          ch.status.toLowerCase() == 'paused')
                                        const _PausedPill(),
                                    ],
                                  ),
                                ),
                              ),
                              flex: 3,
                            ),
                            _BodyCell(Text(ch.description), flex: 3),
                            _BodyCell(
                              Center(
                                child: _UnreadBadge(
                                  channelId: ch.id,
                                  currentUid: currentUid,
                                ),
                              ),
                              flex: 1,
                            ),
                            if (isAdmin) _BodyCell(Text(_fmtDate(ch.createdOn)), flex: 2),
                            if (isAdmin)
                              _BodyCell(
                                Align(
                                  alignment: Alignment.centerLeft,
                                  child: _StatusActions(
                                    status: ch.status,
                                    onChangeStatus: (s) => onChangeStatus(ch.id, s),
                                    onDelete: () => onDelete(ch),
                                  ),
                                ),
                                flex: 2,
                              ),
                          ],
                        ),
                        const Divider(height: 1),
                      ],
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  String _fmtDate(DateTime d) {
    final mm = d.month.toString().padLeft(2, '0');
    final dd = d.day.toString().padLeft(2, '0');
    return '${d.year}-$mm-$dd';
  }
}


class _PausedPill extends StatelessWidget {
  const _PausedPill();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: Colors.orange.withOpacity(0.12),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: Colors.orange.withOpacity(0.4)),
      ),
      child: const Text(
        'Paused',
        style: TextStyle(
          fontSize: 11,
          color: Colors.orange,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

class _TableRowWidget extends StatelessWidget {
  final List<Widget> cells;
  const _TableRowWidget({required this.cells});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: cells,
      ),
    );
  }
}

class _HeaderCell extends StatelessWidget {
  final String? label;
  final IconData? icon;
  final int flex;

  const _HeaderCell(this.label, {this.flex = 1}) : icon = null;
  const _HeaderCell.icon(this.icon, {this.flex = 1}) : label = null;

  @override
  Widget build(BuildContext context) {
    final child = label != null
        ? Text(label!, style: const TextStyle(fontWeight: FontWeight.bold))
        : Icon(icon, size: 20);
    return Expanded(
      flex: flex,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 6),
        child: child,
      ),
    );
  }
}

class _BodyCell extends StatelessWidget {
  final Widget child;
  final int flex;
  const _BodyCell(this.child, {this.flex = 1});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      flex: flex,
      child: Padding(
        padding: const EdgeInsets.all(6),
        child: child,
      ),
    );
  }
}

/* ========= Models ========= */

class _ChannelWithId {
  final String id;
  final String name;
  final String description;
  final DateTime createdOn;
  final int notifications;
  final String status;

  _ChannelWithId({
    required this.id,
    required this.name,
    required this.description,
    required this.createdOn,
    required this.notifications,
    required this.status,
  });

  static DateTime _parseCreatedAt(dynamic value) {
    if (value == null) return DateTime.now();
    if (value is int) {
      return value > 20000000000
          ? DateTime.fromMillisecondsSinceEpoch(value)
          : DateTime.fromMillisecondsSinceEpoch(value * 1000);
    }
    if (value is double) {
      final v = value.round();
      return v > 20000000000
          ? DateTime.fromMillisecondsSinceEpoch(v)
          : DateTime.fromMillisecondsSinceEpoch(v * 1000);
    }
    if (value is String) {
      try {
        return DateTime.parse(value);
      } catch (_) {
        final asInt = int.tryParse(value);
        if (asInt != null) {
          return asInt > 20000000000
              ? DateTime.fromMillisecondsSinceEpoch(asInt)
              : DateTime.fromMillisecondsSinceEpoch(asInt * 1000);
        }
      }
    }
    return DateTime.now();
  }

  static int _toInt(dynamic v) {
    if (v == null) return 0;
    if (v is int) return v;
    if (v is double) return v.round();
    if (v is String) return int.tryParse(v) ?? 0;
    return 0;
  }

  factory _ChannelWithId.fromJson(String id, dynamic json) {
    final map = (json is Map) ? json : <String, dynamic>{};
    return _ChannelWithId(
      id: id,
      name: (map['name'] ?? "").toString(),
      description: (map['description'] ?? "").toString(),
      createdOn: _parseCreatedAt(map['created_at']),
      notifications: _toInt(map['notifications']),
      status: (map['status'] ?? 'Active').toString(),
    );
  }
}

class _StatusActions extends StatelessWidget {
  final String status; // 'Active' | 'Paused' | others
  final ValueChanged<String> onChangeStatus;
  final VoidCallback onDelete;

  const _StatusActions({
    required this.status,
    required this.onChangeStatus,
    required this.onDelete,
  });

  Color get _statusColor =>
      status == 'Active'
          ? Colors.green
          : (status == 'Paused' ? Colors.orange : Colors.grey);

  @override
  Widget build(BuildContext context) {
    final isActive = status == 'Active';
    final isPaused = status == 'Paused';

    return PopupMenuButton<String>(
      tooltip: 'Change status / Delete',
      onSelected: (value) {
        if (value == 'active') onChangeStatus('Active');
        if (value == 'paused') onChangeStatus('Paused');
        if (value == 'delete') onDelete();
      },
      elevation: 0,
      color: Colors.transparent,
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      constraints: const BoxConstraints(minWidth: 280),
      padding: EdgeInsets.zero,
      itemBuilder: (context) => [
        PopupMenuItem<String>(
          enabled: false,
          padding: EdgeInsets.zero,
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              gradient: const LinearGradient(
                colors: [Color(0xFFDED08B), Color(0xFF918D64)],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  InkWell(
                    onTap: () => Navigator.pop(context, 'active'),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 12),
                      child: Row(
                        children: [
                          Icon(
                            Icons.check_circle,
                            size: 18,
                            color: isActive
                                ? Colors.greenAccent.shade700
                                : Colors.black87,
                          ),
                          const SizedBox(width: 10),
                          const Expanded(
                            child: Text(
                              'Active',
                              style: TextStyle(
                                  fontWeight: FontWeight.w600,
                                  color: Colors.white),
                            ),
                          ),
                          if (isActive)
                            const Icon(Icons.check,
                                size: 18, color: Colors.white),
                        ],
                      ),
                    ),
                  ),
                  Container(
                    height: 1,
                    margin: const EdgeInsets.symmetric(horizontal: 10),
                    color: Colors.white54,
                  ),

                  InkWell(
                    onTap: () => Navigator.pop(context, 'paused'),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 12),
                      child: Row(
                        children: [
                          Icon(
                            Icons.pause_circle_filled,
                            size: 18,
                            color: isPaused
                                ? Colors.amber.shade900
                                : Colors.black87,
                          ),
                          const SizedBox(width: 10),
                          const Expanded(
                            child: Text(
                              'Paused',
                              style: TextStyle(
                                  fontWeight: FontWeight.w600,
                                  color: Colors.white),
                            ),
                          ),
                          if (isPaused)
                            const Icon(Icons.check,
                                size: 18, color: Colors.white),
                        ],
                      ),
                    ),
                  ),
                  Container(
                    height: 1,
                    margin: const EdgeInsets.symmetric(horizontal: 10),
                    color: Colors.white54,
                  ),

                  InkWell(
                    onTap: () => Navigator.pop(context, 'delete'),
                    child: const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                      child: Row(
                        children: [
                          Icon(Icons.delete_outline, color: Colors.red, size: 18),
                          SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              'Delete',
                              style: TextStyle(
                                fontWeight: FontWeight.w600,
                                color: Colors.red,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        decoration: BoxDecoration(
          color: _statusColor.withOpacity(0.12),
          border: Border.all(color: _statusColor.withOpacity(0.3)),
          borderRadius: BorderRadius.circular(999),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              status == 'Active' ? Icons.check_circle : Icons.pause_circle_filled,
              size: 18,
              color: _statusColor,
            ),
            const SizedBox(width: 6),
            Text(
              status,
              style: TextStyle(fontWeight: FontWeight.w600, color: _statusColor),
            ),
            const SizedBox(width: 4),
            const Icon(Icons.arrow_drop_down, size: 18),
          ],
        ),
      ),
    );
  }
}

/* ===========================
   Unread Badge (per channel)
   =========================== */

class _UnreadBadge extends StatelessWidget {
  final String channelId;
  final String? currentUid;

  const _UnreadBadge({required this.channelId, required this.currentUid});

  @override
  Widget build(BuildContext context) {
    if (currentUid == null || currentUid!.isEmpty) {
      return const SizedBox.shrink();
    }

    final readsRef =
    rtdb.FirebaseDatabase.instance.ref('channels/$channelId/reads/${currentUid!}');

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
            .collection('channels')
            .doc(channelId)
            .collection('messages')
            .orderBy('timestamp', descending: false);

        if (lastRead != null) {
          q = q.where('timestamp', isGreaterThan: lastRead);
        }

        return StreamBuilder<fs.QuerySnapshot>(
          stream: q.snapshots(),
          builder: (context, qs) {
            if (!qs.hasData) return const SizedBox.shrink();
            final unread = qs.data!.docs.length;
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

/* ===========================
   Shared types
   =========================== */

class _MessageHit {
  final String channelId;
  final String channelName;
  final String messageId;
  final String text;
  final String name;
  final DateTime? ts;

  _MessageHit({
    required this.channelId,
    required this.channelName,
    required this.messageId,
    required this.text,
    required this.name,
    required this.ts,
  });
}

