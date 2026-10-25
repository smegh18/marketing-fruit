import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';

class HistorySection extends StatelessWidget {
  const HistorySection({super.key, this.height = 320});

  final double height;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: height,
      child: Card(
        elevation: 3,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                children: const [
                  Icon(Icons.history, color: Colors.green),
                  SizedBox(width: 8),
                  Text(
                    "History",
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Table headers
              Row(
                children: const [
                  Expanded(
                    flex: 3,
                    child: Text(
                      "User",
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                  Expanded(
                    flex: 2,
                    child: Text(
                      "Role",
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                  Expanded(
                    flex: 2,
                    child: Text(
                      "Time",
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ),
              const Divider(thickness: 1),

              // Live data from Firebase
              Expanded(
                child: StreamBuilder<DatabaseEvent>(
                  // Most recent 25 users by last_login
                  stream: FirebaseDatabase.instance
                      .ref('users')
                      .orderByChild('last_login')
                      .limitToLast(25)
                      .onValue,
                  builder: (context, snap) {
                    if (snap.hasError) {
                      return _centerText('Failed to load history');
                    }
                    if (!snap.hasData) {
                      return const Center(child: CircularProgressIndicator());
                    }

                    final raw = snap.data!.snapshot.value;
                    if (raw == null || raw is! Map) {
                      // No users or no last_login yet
                      return _centerText('No recent activity');
                    }

                    // Convert to list of rows
                    final List<_HistoryRow> rows = [];
                    (raw).forEach((id, v) {
                      if (v is! Map) return;
                      final map = Map<String, dynamic>.from(v);
                      final role = (map['role'] as String?)?.trim();
                      final name = _displayName(map, fallback: id.toString());
                      final last = _parseMillis(map['last_login']);
                      if (last == null) return; // skip users without last_login

                      rows.add(_HistoryRow(
                        user: name,
                        role: role?.isNotEmpty == true ? role! : '—',
                        lastLoginMs: last,
                      ));
                    });

                    if (rows.isEmpty) {
                      return _centerText('No recent activity');
                    }

                    // Sort by most recent first and cap the list
                    rows.sort((a, b) => b.lastLoginMs.compareTo(a.lastLoginMs));
                    final visible = rows.take(15).toList();

                    return ListView.separated(
                      itemCount: visible.length,
                      separatorBuilder: (_, __) => const Divider(height: 1),
                      itemBuilder: (context, i) {
                        final r = visible[i];
                        return Padding(
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          child: Row(
                            children: [
                              Expanded(
                                flex: 3,
                                child: Text(
                                  r.user,
                                  style: const TextStyle(fontSize: 16),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              Expanded(
                                flex: 2,
                                child: Row(
                                  children: [
                                    const Icon(Icons.person,
                                        size: 20, color: Colors.blueGrey),
                                    const SizedBox(width: 6),
                                    Flexible(
                                      child: Text(
                                        r.role,
                                        style: const TextStyle(fontSize: 14),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Expanded(
                                flex: 2,
                                child: Text(
                                  _formatMillis(r.lastLoginMs),
                                  style: const TextStyle(fontSize: 14),
                                ),
                              ),
                            ],
                          ),
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

  static Widget _centerText(String s) =>
      Center(child: Text(s, style: const TextStyle(color: Colors.black54)));

  static String _displayName(Map<String, dynamic> m, {required String fallback}) {
    final first = (m['first_name'] ?? '').toString().trim();
    final last  = (m['last_name']  ?? '').toString().trim();
    final email = (m['email']      ?? '').toString().trim();

    if (first.isNotEmpty && last.isNotEmpty) return '$first $last';
    if (first.isNotEmpty) return first;
    if (email.isNotEmpty) return email;
    return fallback;
  }

  static int? _parseMillis(dynamic v) {
    if (v == null) return null;
    if (v is int) return v;
    if (v is double) return v.toInt();
    if (v is String) {
      final p = int.tryParse(v);
      return p;
    }
    return null;
  }

  static String _formatMillis(int ms) {
    final dt = DateTime.fromMillisecondsSinceEpoch(ms);
    // 26/Jul 02:43
    final day = dt.day.toString().padLeft(2, '0');
    const months = [
      'Jan','Feb','Mar','Apr','May','Jun','Jul','Aug','Sep','Oct','Nov','Dec'
    ];
    final mon = months[dt.month - 1];
    final h = dt.hour % 12 == 0 ? 12 : dt.hour % 12;
    final mm = dt.minute.toString().padLeft(2, '0');
    final ampm = dt.hour >= 12 ? 'pm' : 'am';
    return '$day/$mon ${h.toString().padLeft(2, '0')}:$mm $ampm';
  }
}

class _HistoryRow {
  final String user;
  final String role;
  final int lastLoginMs;
  _HistoryRow({
    required this.user,
    required this.role,
    required this.lastLoginMs,
  });
}
