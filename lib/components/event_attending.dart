import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';

class EventAttendingSection extends StatefulWidget {
  final void Function(String id, {String? eventName}) onEventTap;
  const EventAttendingSection({super.key, required this.onEventTap});

  @override
  State<EventAttendingSection> createState() => _EventAttendingSectionState();
}

class _EventAttendingSectionState extends State<EventAttendingSection> {
  String? _userId;

  @override
  void initState() {
    super.initState();
    final user = FirebaseAuth.instance.currentUser;
    _userId = user?.uid;
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Text(
            'Events you are attending',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8.0),
          child: StreamBuilder<DatabaseEvent>(
            stream: FirebaseDatabase.instance.ref('events').onValue,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }
              if (snapshot.hasError) {
                return Center(child: Text('Error: ${snapshot.error}'));
              }
              if (!snapshot.hasData || snapshot.data!.snapshot.value == null || _userId == null) {
                return const Center(child: Text('No events found.'));
              }

              final Map<dynamic, dynamic> dbMap = snapshot.data!.snapshot.value as Map;
              final List<Map<String, dynamic>> attendingEvents = dbMap.entries
                  .where((entry) {
                final eventMap = entry.value as Map;
                final regUsers = eventMap['registeredUsers'];
                // Show event only if registeredUsers is a Map and contains user id
                return regUsers is Map && regUsers.containsKey(_userId);
              })
                  .map((e) => {
                'id': e.key,
                ...Map<String, dynamic>.from(e.value as Map),
              })
                  .toList();

              if (attendingEvents.isEmpty) {
                return const Center(child: Text('No attended events.'));
              }

              return GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 4,
                  crossAxisSpacing: 8,
                  mainAxisSpacing: 8,
                  childAspectRatio: 2.5,
                ),
                itemCount: attendingEvents.length,
                itemBuilder: (context, index) {
                  final event = attendingEvents[index];
                  return _buildEventCard(event);
                },
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildEventCard(Map<String, dynamic> event) {
    final String eventName = event['eventName'] ?? event['name'] ?? '';
    final String description = _parseDescription(event['eventDescription'] ?? event['description']);
    final String image = event['bannerUrl'] ?? event['logoUrl'] ?? '';
    final String id = event['id']?.toString() ?? '';

    return GestureDetector(
      onTap: () {
        widget.onEventTap(id, eventName: eventName);
      },
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          image: image.isEmpty
              ? null
              : DecorationImage(
            image: NetworkImage(image),
            fit: BoxFit.cover,
          ),
          color: Colors.grey.shade300,
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: Stack(
            children: [
              if (image.isEmpty)
                Center(
                  child: Icon(Icons.event,
                      size: 40, color: Colors.grey.shade600),
                ),
              Container(
                color: Colors.black.withOpacity(0.4),
              ),
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: Align(
                  alignment: Alignment.bottomLeft,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.end,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        eventName,
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        description,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 11,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: const [
                          Text(
                            'Read more',
                            style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 11),
                          ),
                          SizedBox(width: 2),
                          Icon(Icons.arrow_right_alt,
                              color: Colors.white, size: 14),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// --- UNIVERSAL DESCRIPTION PARSER ---
  String _parseDescription(dynamic desc) {
    if (desc == null) return '';
    if (desc is String) {
      try {
        final decoded = jsonDecode(desc);
        if (decoded is List) {
          return decoded
              .where((op) => op is Map && op.containsKey('insert'))
              .map((op) => op['insert'] ?? '')
              .join('')
              .toString()
              .trim();
        }
        if (decoded is Map && decoded['ops'] is List) {
          return (decoded['ops'] as List)
              .where((op) => op is Map && op.containsKey('insert'))
              .map((op) => op['insert'] ?? '')
              .join('')
              .toString()
              .trim();
        }
      } catch (_) {
        return desc;
      }
      return desc;
    }
    if (desc is List) {
      return desc
          .where((op) => op is Map && op.containsKey('insert'))
          .map((op) => op['insert'] ?? '')
          .join('')
          .toString()
          .trim();
    }
    if (desc is Map && desc['ops'] is List) {
      return (desc['ops'] as List)
          .where((op) => op is Map && op.containsKey('insert'))
          .map((op) => op['insert'] ?? '')
          .join('')
          .toString()
          .trim();
    }
    return '';
  }
}
