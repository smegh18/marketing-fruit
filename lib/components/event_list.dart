import 'dart:convert';
import 'dart:math' as math;
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

class EventListPage extends StatefulWidget {
  final void Function(String id, {String? eventName}) onEventTap;
  const EventListPage({super.key, required this.onEventTap});

  @override
  State<EventListPage> createState() => _EventListPageState();
}

class _EventListPageState extends State<EventListPage> {
  // Convert any field to displayable string
  String displayString(dynamic field) {
    if (field is List) return field.join(', ');
    if (field is String) return field;
    if (field != null) return field.toString();
    return '';
  }

  String displayLogoUrl(dynamic url) {
    if (url == null) return '';
    if (url is String) return url;
    if (url is List && url.isNotEmpty) return url.first.toString();
    return '';
  }

  /// --- UNIVERSAL DESCRIPTION PARSER ---
  String parseDescription(dynamic desc) {
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
        return desc; // plain text already
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

  // Display event logo with placeholder/click
  Widget buildImageCell(String? graphicUrl, {double size = 40}) {
    return InkWell(
      onTap: () {
        if (graphicUrl != null && graphicUrl.isNotEmpty) {
          launchUrl(Uri.parse(graphicUrl), mode: LaunchMode.externalApplication);
        }
      },
      child: ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: graphicUrl != null && graphicUrl.isNotEmpty
            ? Image.network(
                graphicUrl,
                width: size,
                height: size,
                fit: BoxFit.cover,
                errorBuilder: (context, _, __) => Container(
                  width: size,
                  height: size,
                  color: Colors.grey[200],
                  child: const Icon(Icons.image, color: Colors.grey),
                ),
              )
            : Container(
                width: size,
                height: size,
                color: Colors.grey[200],
                child: const Icon(Icons.broken_image, color: Colors.grey),
              ),
      ),
    );
  }

  // Convert millis to readable date string
  String dateTimeString(dynamic timestamp) {
    if (timestamp == null) return '';
    try {
      final ts = timestamp is int ? timestamp : int.tryParse(timestamp.toString()) ?? 0;
      if (ts == 0) return '';
      final dt = DateTime.fromMillisecondsSinceEpoch(ts);
      return "${dt.day.toString().padLeft(2, '0')}-"
          "${dt.month.toString().padLeft(2, '0')}-"
          "${dt.year} "
          "${dt.hour.toString().padLeft(2, '0')}:"
          "${dt.minute.toString().padLeft(2, '0')}";
    } catch (_) {
      return '';
    }
  }

  // Show Start and End together
  String eventDateRange(Map<String, dynamic> item) {
    final startStr = dateTimeString(item['start']);
    final endStr = dateTimeString(item['end']);
    if (startStr.isEmpty && endStr.isEmpty) {
      return displayString(item['eventTime'] ?? item['eventDate'] ?? '');
    }
    if (startStr == endStr || endStr.isEmpty) return startStr;
    return "$startStr → $endStr";
  }

  /// One-line, ellipsized text with a fixed max width so the column doesn't expand.
  Widget _oneLine(String text, double maxWidth) {
    return ConstrainedBox(
      constraints: BoxConstraints(maxWidth: maxWidth),
      child: Text(
        text,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        softWrap: false,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final containerWidth = screenWidth * 0.90;

    return Center(
      child: Container(
        width: containerWidth,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
        ),
        child: LayoutBuilder(
          builder: (context, constraints) {
            // Give the Description column a reasonable max width (responsive).
            final double descColWidth =
                math.max(80, math.min(220, constraints.maxWidth * 0.35));

            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Event List',
                  style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 20),
                StreamBuilder<DatabaseEvent>(
                  stream: FirebaseDatabase.instance.ref('events').onValue,
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    }
                    if (snapshot.hasError) {
                      return Center(child: Text('Error: ${snapshot.error}'));
                    }
                    if (!snapshot.hasData || snapshot.data!.snapshot.value == null) {
                      return const Center(child: Text('No events found.'));
                    }

                    final Map<dynamic, dynamic> dbMap =
                        snapshot.data!.snapshot.value as Map;
                    final List<Map<String, dynamic>> data = dbMap.entries
                        .map((e) => {
                              'id': e.key,
                              ...Map<String, dynamic>.from(e.value as Map),
                            })
                        .toList();

                    print(data);

                    return SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: ConstrainedBox(
                        constraints: BoxConstraints(minWidth: constraints.maxWidth),
                        child: (FirebaseAuth.instance.currentUser == null)
                            ? DataTable(
                                columnSpacing: 48,
                                headingRowHeight: 48,
                                columns: const [
                                  DataColumn(label: Text('Image')),
                                  DataColumn(label: Text('Event Name')),
                                  DataColumn(label: Text('Organized By')),
                                  DataColumn(label: Text('Date/Time')),
                                  DataColumn(label: Text('Description')),
                                  DataColumn(label: Text('Attending')),
                                  DataColumn(label: Text('Action')),
                                ],
                                rows: data.map((item) {
                                  final description = parseDescription(
                                      item['eventDescription'] ?? item['description']);
                                  final logo = displayLogoUrl(item['logoUrl']);
                                  return DataRow(cells: [
                                    DataCell(buildImageCell(logo)),
                                    DataCell(
                                      MouseRegion(
                                        cursor: SystemMouseCursors.click,
                                        child: GestureDetector(
                                          onTap: () {
                                            widget.onEventTap(item['id'],eventName: item['eventName']);
                                          },
                                          child: Text(displayString(item['eventName'])),
                                        ),
                                      ),
                                    ),
                                    DataCell(Text(displayString(
                                        item['organizer'] ?? 'Marketing Fruit Team'))),
                                    DataCell(Text(eventDateRange(item))),
                                    // One-line, fixed-width description
                                    DataCell(_oneLine(description, descColWidth)),
                                    DataCell(
                                      Switch(
                                        value: item['attending'] == true,
                                        onChanged: (val) async {
                                          await FirebaseDatabase.instance
                                              .ref('events/${item['id']}')
                                              .update({'attending': val});
                                        },
                                      ),
                                    ),
                                    DataCell(
                                      Row(
                                        children: [
                                          IconButton(
                                            icon: const Icon(Icons.delete,
                                                size: 18, color: Colors.red),
                                            onPressed: () async {
                                              await FirebaseDatabase.instance
                                                  .ref('events/${item['id']}')
                                                  .remove();
                                            },
                                          ),
                                        ],
                                      ),
                                    ),
                                  ]);
                                }).toList(),
                              )
                            : DataTable(
                                columnSpacing: 48,
                                headingRowHeight: 48,
                                columns: const [
                                  DataColumn(label: Text('Image')),
                                  DataColumn(label: Text('Event Name')),
                                  DataColumn(label: Text('Organized By')),
                                  DataColumn(label: Text('Date/Time')),
                                  DataColumn(label: Text('Description')),
                                ],
                                rows: data.map((item) {
                                  final description = parseDescription(
                                      item['eventDescription'] ?? item['description']);
                                  final logo = displayLogoUrl(item['logoUrl']);
                                  return DataRow(cells: [
                                    DataCell(buildImageCell(logo)),
                                    DataCell(Text(displayString(item['eventName']))),
                                    DataCell(Text(displayString(
                                        item['organizedBy'] ?? 'Marketing Fruit Team'))),
                                    DataCell(Text(eventDateRange(item))),
                                    // One-line, fixed-width description
                                    DataCell(_oneLine(description, descColWidth)),
                                  ]);
                                }).toList(),
                              ),
                      ),
                    );
                  },
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}
