import 'package:flutter/material.dart';

class NotificationDrawer extends StatelessWidget {
  final List<String> notifications;
  final VoidCallback onClose;
  final VoidCallback onReadAll;

  const NotificationDrawer({
    super.key,
    required this.notifications,
    required this.onClose,
    required this.onReadAll,
  });

  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: Column(
        children: [
          ListTile(
            title: const Text('Notifications', style: TextStyle(fontWeight: FontWeight.bold)),
            trailing: IconButton(icon: const Icon(Icons.close), onPressed: onClose),
          ),
          Expanded(
            child: notifications.isEmpty
                ? const Center(child: Text('No notifications'))
                : ListView.builder(
              itemCount: notifications.length,
              itemBuilder: (_, index) => ListTile(
                leading: const Icon(Icons.notifications),
                title: Text(notifications[index]),
              ),
            ),
          ),
          ElevatedButton(
            onPressed: onReadAll,
            child: const Text('Mark All as Read'),
          ),
        ],
      ),
    );
  }
}
