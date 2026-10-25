import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:Marketing_Fruit/components/glasspopup.dart';

class ChannelAssociatesProfileSection extends StatefulWidget {
  final String channelId;
  final String schoolId; // Or guardianId, depending on association
  final String associateRole; // 'School' or 'Guardian'
  const ChannelAssociatesProfileSection({
    super.key,
    required this.channelId,
    required this.schoolId,
    this.associateRole = 'School', // default to School for backward compat
  });

  @override
  State<ChannelAssociatesProfileSection> createState() =>
      _ChannelAssociatesProfileSectionState();
}

class _ChannelAssociatesProfileSectionState
    extends State<ChannelAssociatesProfileSection> {
  bool removeFromChannel = false;
  bool restrictFromChannel = false;
  String? selectedAssociatedUserId; // for nested view
  String? selectedAssociatedRole; // 'Student' or 'Guardian'

  Future<Map<String, dynamic>> _fetchAssociate() async {
    // Fetch associate (school or guardian)'s profile from /users
    final ref = FirebaseDatabase.instance.ref('users/${widget.schoolId}');
    final snap = await ref.get();
    if (!snap.exists) return {};
    final map = snap.value as Map?;
    return map?.map((k, v) => MapEntry(k.toString(), v)) ?? {};
  }

  Future<List<Map<String, String>>> _fetchAssociatedStudents(
      Map<String, dynamic> associate) async {
    final usersSnap = await FirebaseDatabase.instance.ref('users').get();
    if (!usersSnap.exists || usersSnap.value == null) return [];
    final users = Map<String, dynamic>.from(usersSnap.value as Map);
    List<Map<String, String>> students = [];

    if (associate['role'] == 'School') {
      // For school, find all students with this 'school'
      final String schoolName =
          (associate['school']?.toString() ?? associate['first_name']?.toString() ?? '').trim();
      if (schoolName.isNotEmpty) {
        users.forEach((userId, data) {
          final u = Map<String, dynamic>.from(data);
          if (u['role'] == 'Student' && (u['school']?.toString() ?? '') == schoolName) {
            students.add({
              'userId': userId,
              'name':
                  '${u['first_name'] ?? ''} ${u['last_name'] ?? ''}'.trim(),
              'role': 'Student',
            });
          }
        });
      }
    } else if (associate['role'] == 'Guardian') {
      final guardianEmail = associate['email']?.toString();
      users.forEach((userId, data) {
        final u = Map<String, dynamic>.from(data);
        if (u['role'] == 'Student' &&
            (u['guardian_email']?.toString() ?? '') ==
                (guardianEmail ?? '')) {
          students.add({
            'userId': userId,
            'name':
                '${u['first_name'] ?? ''} ${u['last_name'] ?? ''}'.trim(),
            'role': 'Student',
          });
        }
      });
    }
    // For extensibility: add Brand/other role support as needed.
    return students;
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final containerWidth = screenWidth * 0.90;
    return FutureBuilder<Map<String, dynamic>>(
      future: _fetchAssociate(),
      builder: (context, snap) {
        final associate = snap.data ?? {};
        return Center(
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
                Align(
                  alignment: Alignment.topLeft,
                  child: IconButton(
                    icon: const Icon(Icons.arrow_back),
                    onPressed: () => Navigator.pop(context),
                  ),
                ),
                Center(
                  child: CircleAvatar(
                    radius: 40,
                    backgroundColor: Colors.green,
                    child: Icon(
                      associate['role'] == 'School'
                          ? Icons.school
                          : associate['role'] == 'Guardian'
                              ? Icons.family_restroom
                              : Icons.person,
                      size: 40,
                      color: Colors.white,
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Center(
                  child: Text(
                    associate['school'] ??
                        associate['first_name'] ??
                        associate['name'] ??
                        'Associate',
                    style: const TextStyle(
                        fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                ),
                Center(
                  child: Text(
                    associate['role']?.toString() ?? widget.associateRole,
                    style: const TextStyle(color: Colors.grey),
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _buildIconButton(
                      icon: Icons.call,
                      label: 'Call',
                      onTap: () => _showPopup(
                        'Phone Number',
                        associate['contact'] ??
                            associate['mobile'] ??
                            '+91 99999',
                      ),
                    ),
                    const SizedBox(width: 20),
                    _buildIconButton(
                      icon: Icons.email,
                      label: 'Mail',
                      onTap: () =>
                          _showPopup('Email Address', associate['email'] ?? ''),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                _buildToggleTile(
                  title: 'Remove from Channel',
                  value: removeFromChannel,
                  onChanged: (val) {
                    setState(() => removeFromChannel = val);
                    if (val) _showConfirmationDialogs();
                  },
                ),
                _buildToggleTile(
                  title: 'Restrict from Channel',
                  value: restrictFromChannel,
                  onChanged: (val) => setState(() => restrictFromChannel = val),
                ),
                const SizedBox(height: 24),

                // ===== Title only (button moved below the list) =====
                const Text(
                  'Associated Students',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 12),

                // ===== Students list + (moved) Remove All button below =====
                FutureBuilder<List<Map<String, String>>>(
                  future: _fetchAssociatedStudents(associate),
                  builder: (context, snap) {
                    final students = snap.data ?? [];
                    if (snap.connectionState == ConnectionState.waiting) {
                      return const Padding(
                        padding: EdgeInsets.symmetric(vertical: 8.0),
                        child: LinearProgressIndicator(),
                      );
                    }
                    if (students.isEmpty) {
                      return const Text('No students associated');
                    }

                    return Column(
                      children: [
                        ...students.map(
                          (student) => GestureDetector(
                            onTap: () => setState(() {
                              selectedAssociatedUserId = student['userId'];
                              selectedAssociatedRole = student['role'];
                            }),
                            child: _buildStudentRow(student['name'] ?? ''),
                          ),
                        ),
                        const SizedBox(height: 14),
                        Align(
                          alignment: Alignment.centerRight,
                          child: TextButton(
                            onPressed: () => _confirmRemoveAll(students),
                            child: const Text(
                              'Remove all students',
                              style: TextStyle(color: Colors.red),
                            ),
                          ),
                        ),
                      ],
                    );
                  },
                ),

                if (selectedAssociatedUserId != null &&
                    selectedAssociatedRole != null)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    child: ChannelAssociatesProfileSection(
                      channelId: widget.channelId,
                      schoolId: selectedAssociatedUserId!,
                      associateRole: selectedAssociatedRole!,
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }

  // ===============================
  // Glass-styled confirmation flow
  // ===============================
  void _showConfirmationDialogs() async {
    // First confirm
    final firstConfirm = await showGlassPopup<bool>(
      context: context,
      title: 'Are you sure?',
      dismissible: true,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'You are about to remove this school/guardian from the channel.',
            style: TextStyle(color: Colors.white, fontSize: 16, height: 1.35),
          ),
          const Spacer(),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  style: OutlinedButton.styleFrom(
                    side: BorderSide(color: Colors.white.withOpacity(0.7)),
                    foregroundColor: Colors.white,
                    padding:
                        const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10)),
                  ),
                  onPressed: () => Navigator.pop(context, false),
                  child: const Text('Cancel',
                      style: TextStyle(fontWeight: FontWeight.w600)),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.black,
                    padding:
                        const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10)),
                    elevation: 0,
                  ),
                  onPressed: () => Navigator.pop(context, true),
                  child: const Text('Sure',
                      style: TextStyle(
                          color: Colors.white, fontWeight: FontWeight.w700)),
                ),
              ),
            ],
          ),
        ],
      ),
    );

    if (firstConfirm == true) {
      // Second confirm: remove students?
      await showGlassPopup<void>(
        context: context,
        title: 'Remove associated students?',
        dismissible: true,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Do you want to remove associated students as well?',
              style: TextStyle(color: Colors.white, fontSize: 16, height: 1.35),
            ),
            const Spacer(),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    style: OutlinedButton.styleFrom(
                      side: BorderSide(color: Colors.white.withOpacity(0.7)),
                      foregroundColor: Colors.white,
                      padding:
                          const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10)),
                    ),
                    onPressed: () => Navigator.pop(context),
                    child: const Text('No',
                        style: TextStyle(fontWeight: FontWeight.w600)),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red,
                      padding:
                          const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10)),
                      elevation: 0,
                    ),
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Yes',
                        style: TextStyle(
                            color: Colors.white, fontWeight: FontWeight.w700)),
                  ),
                ),
              ],
            ),
          ],
        ),
      );
      // Implement cascading DB removal if needed
    }
  }

  // ===============================
  // Remove All (below list) flow
  // ===============================
  Future<void> _confirmRemoveAll(
      List<Map<String, String>> students) async {
    final confirmed = await showGlassPopup<bool>(
      context: context,
      title: 'Remove all students?',
      dismissible: true,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'This will remove ${students.length} student(s) from this association. You can’t undo this.',
            style:
                const TextStyle(color: Colors.white, fontSize: 16, height: 1.35),
          ),
          const Spacer(),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  style: OutlinedButton.styleFrom(
                    side: BorderSide(color: Colors.white.withOpacity(0.7)),
                    foregroundColor: Colors.white,
                    padding:
                        const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10)),
                  ),
                  onPressed: () => Navigator.pop(context, false),
                  child: const Text('Cancel',
                      style: TextStyle(fontWeight: FontWeight.w600)),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red,
                    padding:
                        const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10)),
                    elevation: 0,
                  ),
                  onPressed: () => Navigator.pop(context, true),
                  child: const Text('Remove all',
                      style: TextStyle(
                          color: Colors.white, fontWeight: FontWeight.w700)),
                ),
              ),
            ],
          ),
        ],
      ),
    );

    if (confirmed == true) {
      // TODO: Implement your removal logic here.
      // Example patterns (adjust to your schema):
      //
      // 1) If you store associations under:
      //    channels/<channelId>/associates/<schoolId>/students/<studentId>: true
      //    -> delete those children
      //
      // final ref = FirebaseDatabase.instance.ref(
      //   'channels/${widget.channelId}/associates/${widget.schoolId}/students',
      // );
      // await ref.remove();
      //
      // 2) Or if each student holds a pointer to the school/guardian,
      //    iterate and clear those fields:
      // final db = FirebaseDatabase.instance.ref('users');
      // for (final s in students) {
      //   await db.child(s['userId']!).update({'school': null, 'guardian_email': null});
      // }
      //
      // After successful removal, refresh:
      setState(() {
        selectedAssociatedUserId = null;
        selectedAssociatedRole = null;
      });
    }
  }

  // ===============================
  // Glass-styled simple popup
  // ===============================
  void _showPopup(String title, String content) {
    showGlassPopup<void>(
      context: context,
      title: title,
      dismissible: true,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(content,
              style: const TextStyle(
                  color: Colors.white, fontSize: 16, height: 1.35)),
          const Spacer(),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.black,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10)),
                elevation: 0,
              ),
              onPressed: () => Navigator.pop(context),
              child: const Text('Close',
                  style: TextStyle(
                      color: Colors.white, fontWeight: FontWeight.w700)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildToggleTile({
    required String title,
    required bool value,
    required Function(bool) onChanged,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10.0),
      child: Row(
        children: [
          Expanded(
              child: Text(title,
                  style: const TextStyle(fontWeight: FontWeight.w500))),
          Switch(value: value, onChanged: onChanged),
        ],
      ),
    );
  }

  Widget _buildStudentRow(String name) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 6),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          const Icon(Icons.person, color: Colors.green),
          const SizedBox(width: 12),
          Expanded(child: Text(name)),
          IconButton(
            icon: const Icon(Icons.delete, color: Colors.red),
            onPressed: () {
              // TODO: implement remove this student from DB if desired
            },
          )
        ],
      ),
    );
  }

  Widget _buildIconButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return Column(
      children: [
        InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.grey.shade200,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: Colors.blue),
          ),
        ),
        const SizedBox(height: 4),
        Text(label),
      ],
    );
  }
}
