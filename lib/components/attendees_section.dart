import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_quill/flutter_quill.dart';
import 'package:flutter_quill/quill_delta.dart';
import 'package:intl/intl.dart';

class AttendeesSection extends StatefulWidget {
  final void Function(List<Map<String, String>>) onVIPsChanged;
  const AttendeesSection({super.key, required this.onVIPsChanged});

  @override
  State<AttendeesSection> createState() => _AttendeesSectionState();
}

class _AttendeesSectionState extends State<AttendeesSection> {
  final List<Map<String, String>> vipList = [];

  void _showVIPDialog({Map<String, String>? vip, int? indexToUpdate}) {
    final firstNameController = TextEditingController(text: vip?['name']?.split(' ').first ?? '');
    final lastNameController = TextEditingController(
        text: vip?['name']?.split(' ').length == 2 ? vip!['name']!.split(' ')[1] : '');
    final professionController = TextEditingController(text: vip?['profession'] ?? '');
    final organizationController = TextEditingController(text: vip?['organization'] ?? '');
    final emailController = TextEditingController(text: vip?['email'] ?? '');
    final phoneController = TextEditingController(text: vip?['phone'] ?? '');
    final linkedinController = TextEditingController(text: vip?['linkedin'] ?? '');
    final appearanceTimeController = TextEditingController(text: vip?['appearanceTime'] ?? '');
    final roleController = TextEditingController(text: vip?['role'] ?? '');

    // Quill description controller; parse from JSON string if editing
    QuillController descriptionController;
    if (vip != null && vip['description'] != null && vip['description']!.isNotEmpty) {
      try {
        final descriptionDelta = Delta.fromJson(jsonDecode(vip['description']!));
        descriptionController = QuillController(
          document: Document.fromDelta(descriptionDelta),
          selection: TextSelection.collapsed(offset: 0),
        );
      } catch (_) {
        // fallback to basic if corrupted
        descriptionController = QuillController.basic();
      }
    } else {
      descriptionController = QuillController.basic();
    }

    Future<void> pickDateTime() async {
      DateTime? pickedDate = await showDatePicker(
        context: context,
        initialDate: DateTime.now(),
        firstDate: DateTime(2020),
        lastDate: DateTime(2100),
      );
      if (pickedDate != null) {
        TimeOfDay? pickedTime = await showTimePicker(
          context: context,
          initialTime: TimeOfDay.now(),
        );
        if (pickedTime != null) {
          final selectedDateTime = DateTime(
            pickedDate.year,
            pickedDate.month,
            pickedDate.day,
            pickedTime.hour,
            pickedTime.minute,
          );
          appearanceTimeController.text =
              DateFormat('yyyy-MM-dd HH:mm').format(selectedDateTime);
        }
      }
    }

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(indexToUpdate != null ? 'Edit VIP' : 'Add VIP'),
        content: SingleChildScrollView(
          child: Column(
            children: [
              TextFormField(controller: firstNameController, decoration: const InputDecoration(labelText: 'First Name')),
              TextFormField(controller: lastNameController, decoration: const InputDecoration(labelText: 'Last Name')),
              TextFormField(controller: professionController, decoration: const InputDecoration(labelText: 'Profession')),
              TextFormField(controller: organizationController, decoration: const InputDecoration(labelText: 'Organization')),
              TextFormField(controller: emailController, decoration: const InputDecoration(labelText: 'Email')),
              TextFormField(controller: phoneController, decoration: const InputDecoration(labelText: 'Phone')),
              TextFormField(controller: linkedinController, decoration: const InputDecoration(labelText: 'LinkedIn Profile')),
              GestureDetector(
                onTap: pickDateTime,
                child: AbsorbPointer(
                  child: TextFormField(
                    controller: appearanceTimeController,
                    decoration: const InputDecoration(labelText: 'Appearance Time'),
                  ),
                ),
              ),
              const SizedBox(height: 8),
              const Text('Description', style: TextStyle(fontWeight: FontWeight.w600), textAlign: TextAlign.start),
              const SizedBox(height: 8),
              Container(
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey.shade300),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  children: [
                    QuillSimpleToolbar(controller: descriptionController),
                    Container(
                      padding: const EdgeInsets.all(12),
                      width: MediaQuery.of(context).size.width * 0.7,
                      height: 140,
                      child: QuillEditor(
                        controller: descriptionController,
                        focusNode: FocusNode(),
                        scrollController: ScrollController(),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () {
              if (firstNameController.text.isEmpty ||
                  lastNameController.text.isEmpty ||
                  professionController.text.isEmpty ||
                  organizationController.text.isEmpty ||
                  emailController.text.isEmpty ||
                  phoneController.text.isEmpty ||
                  linkedinController.text.isEmpty ||
                  appearanceTimeController.text.isEmpty) {
                _showAlert('Please fill in all fields.');
                return;
              }

              Navigator.of(context).pop();

              // Role Dialog
              showDialog(
                context: context,
                builder: (_) => AlertDialog(
                  title: const Text("VIP's Role in Event"),
                  content: TextFormField(
                    controller: roleController,
                    decoration: const InputDecoration(labelText: 'Role'),
                  ),
                  actions: [
                    TextButton(
                      onPressed: () {
                        if (roleController.text.isEmpty) {
                          _showAlert('Please enter the role.');
                          return;
                        }

                        // Store Quill description as JSON string!
                        final newVIP = {
                          'name': '${firstNameController.text} ${lastNameController.text}',
                          'profession': professionController.text,
                          'organization': organizationController.text,
                          'email': emailController.text,
                          'phone': phoneController.text,
                          'linkedin': linkedinController.text,
                          'appearanceTime': appearanceTimeController.text,
                          'description': jsonEncode(descriptionController.document.toDelta().toJson()),
                          'role': roleController.text,
                        };

                        setState(() {
                          if (indexToUpdate != null) {
                            vipList[indexToUpdate] = newVIP;
                          } else {
                            vipList.add(newVIP);
                          }
                          widget.onVIPsChanged(vipList);
                        });

                        Navigator.of(context).pop();
                      },
                      child: Text(indexToUpdate != null ? 'Update VIP' : 'Add VIP'),
                    )
                  ],
                ),
              );
            },
            child: const Text('Next'),
          )
        ],
      ),
    );
  }

  void _showAlert(String message) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Missing Fields'),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  void _deleteVIP(int index) {
    setState(() {
      vipList.removeAt(index);
      widget.onVIPsChanged(vipList);
    });
  }

  // Helper to display description as plain text for table/list
  String _plainDescription(String? descJson) {
    if (descJson == null || descJson.isEmpty) return '';
    try {
      final delta = Delta.fromJson(jsonDecode(descJson));
      return delta.map((op) => (op.value is String ? op.value : '')).join().trim();
    } catch (_) {
      return descJson; // fallback to raw
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final containerWidth = screenWidth * 0.90;

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
            // Header Row with title and button
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'VIP Guests',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                ElevatedButton(
                  onPressed: () => _showVIPDialog(),
                  child: const Text('Add VIP'),
                ),
              ],
            ),
            const SizedBox(height: 24),
            // VIP List Table
            if (vipList.isNotEmpty)
              ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: vipList.length,
                separatorBuilder: (_, __) => const Divider(),
                itemBuilder: (_, index) {
                  final vip = vipList[index];
                  return Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(Icons.star, size: 40, color: Colors.amber),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(vip['name'] ?? '', style: const TextStyle(fontWeight: FontWeight.bold)),
                            Text('Profession: ${vip['profession'] ?? ''}'),
                            Text('Organization: ${vip['organization'] ?? ''}'),
                            Text('Email: ${vip['email'] ?? ''}'),
                            Text('Phone: ${vip['phone'] ?? ''}'),
                            Text('LinkedIn: ${vip['linkedin'] ?? ''}'),
                            Text('Appearance Time: ${vip['appearanceTime'] ?? ''}'),
                            Text('Description: ${_plainDescription(vip['description'])}'),
                            Text('Role: ${vip['role'] ?? ''}'),
                          ],
                        ),
                      ),
                      Column(
                        children: [
                          IconButton(
                            icon: const Icon(Icons.edit, color: Colors.blue),
                            onPressed: () => _showVIPDialog(vip: vip, indexToUpdate: index),
                          ),
                          IconButton(
                            icon: const Icon(Icons.delete, color: Colors.red),
                            onPressed: () => _deleteVIP(index),
                          ),
                        ],
                      ),
                    ],
                  );
                },
              )
            else
              const Text('No VIP guests added yet.'),
          ],
        ),
      ),
    );
  }
}

