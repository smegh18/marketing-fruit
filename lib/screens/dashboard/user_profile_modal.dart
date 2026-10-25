import 'package:flutter/material.dart';

class UserProfileModal extends StatelessWidget {
  final String fullName;
  final String role;
  final String avatarUrl;
  final VoidCallback onClose;

  const UserProfileModal({
    super.key,
    required this.fullName,
    required this.role,
    required this.avatarUrl,
    required this.onClose,
  });

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Edit Profile'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          CircleAvatar(radius: 40, backgroundImage: NetworkImage(avatarUrl)),
          const SizedBox(height: 16),
          Text(fullName, style: const TextStyle(fontWeight: FontWeight.bold)),
          Text(role),
          const SizedBox(height: 16),
          const Text('Profile editing functionality goes here.'),
        ],
      ),
      actions: [
        TextButton(onPressed: onClose, child: const Text('Close')),
      ],
    );
  }
}
