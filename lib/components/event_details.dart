import 'dart:typed_data';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_quill/flutter_quill.dart' hide Text;
import 'package:file_picker/file_picker.dart';

class EventDetailsData {
  final String eventName;
  final String descriptionJson; // Quill Delta, as JSON string
  final QuillController descriptionController;
  final Uint8List? eventLogoBytes;
  final String? eventLogoExtension;
  final Uint8List? eventBannerBytes;
  final String? eventBannerExtension;

  EventDetailsData({
    required this.eventName,
    required this.descriptionJson,
    required this.descriptionController,
    this.eventLogoBytes,
    this.eventLogoExtension,
    this.eventBannerBytes,
    this.eventBannerExtension,
  });
}

class EventDetailsSection extends StatefulWidget {
  final void Function(EventDetailsData) onFormChanged;

  const EventDetailsSection({super.key, required this.onFormChanged});

  @override
  State<EventDetailsSection> createState() => _EventDetailsSectionState();
}

class _EventDetailsSectionState extends State<EventDetailsSection> {
  final _eventNameController = TextEditingController();
  final QuillController _descriptionController = QuillController.basic();

  Uint8List? eventLogoBytes;
  String? eventLogoExtension;
  Uint8List? eventBannerBytes;
  String? eventBannerExtension;

  @override
  void initState() {
    super.initState();
    // Listen for description changes so save works reliably
    _descriptionController.addListener(notifyParent);
  }

  @override
  void dispose() {
    _eventNameController.dispose();
    _descriptionController.removeListener(notifyParent);
    _descriptionController.dispose();
    super.dispose();
  }

  void notifyParent() {
    widget.onFormChanged(EventDetailsData(
      eventName: _eventNameController.text,
      descriptionJson: jsonEncode(_descriptionController.document.toDelta().toJson()), // Always JSON string
      descriptionController: _descriptionController,
      eventLogoBytes: eventLogoBytes,
      eventLogoExtension: eventLogoExtension,
      eventBannerBytes: eventBannerBytes,
      eventBannerExtension: eventBannerExtension,
    ));
  }

  Future<void> _pickImage({required bool isLogo}) async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.image,
        withData: true,
      );
      if (result != null && result.files.single.bytes != null) {
        final pickedFile = result.files.single;
        setState(() {
          if (isLogo) {
            eventLogoBytes = pickedFile.bytes;
            eventLogoExtension = pickedFile.extension ?? 'png';
          } else {
            eventBannerBytes = pickedFile.bytes;
            eventBannerExtension = pickedFile.extension ?? 'png';
          }
        });
        notifyParent();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("No image selected.")),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("File picker failed: $e")),
      );
    }
  }

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
            const Text(
              'Event Details',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 24),

            const Text('Event Name', style: TextStyle(fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            TextFormField(
              controller: _eventNameController,
              onChanged: (_) => notifyParent(),
              decoration: InputDecoration(
                hintText: 'Enter event name',
                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
            const SizedBox(height: 24),

            const Text('Event Description', style: TextStyle(fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            Container(
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey.shade300),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                children: [
                  QuillSimpleToolbar(controller: _descriptionController),
                  Container(
                    padding: const EdgeInsets.all(12),
                    height: 150,
                    child: QuillEditor(
                      controller: _descriptionController,
                      focusNode: FocusNode(),
                      scrollController: ScrollController(),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            const Text('Event Logo', style: TextStyle(fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            GestureDetector(
              onTap: () => _pickImage(isLogo: true),
              child: DottedBorderContainer(
                height: 120,
                width: double.infinity,
                child: eventLogoBytes != null
                    ? Stack(
                  fit: StackFit.expand,
                  children: [
                    Image.memory(eventLogoBytes!, fit: BoxFit.contain),
                    Positioned(
                      top: 5,
                      right: 8,
                      child: GestureDetector(
                        onTap: () {
                          setState(() {
                            eventLogoBytes = null;
                            eventLogoExtension = null;
                          });
                          notifyParent();
                        },
                        child: CircleAvatar(
                          radius: 13,
                          backgroundColor: Colors.black.withOpacity(0.6),
                          child: const Icon(Icons.close, color: Colors.white, size: 14),
                        ),
                      ),
                    ),
                  ],
                )
                    : const Center(
                  child: Text(
                    'Tap here to upload event logo',
                    style: TextStyle(color: Colors.grey),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 24),

            const Text('Banner (Landscape Only)', style: TextStyle(fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            GestureDetector(
              onTap: () => _pickImage(isLogo: false),
              child: DottedBorderContainer(
                height: 120,
                width: double.infinity,
                child: eventBannerBytes != null
                    ? Stack(
                  fit: StackFit.expand,
                  children: [
                    Image.memory(eventBannerBytes!, fit: BoxFit.cover),
                    Positioned(
                      top: 5,
                      right: 8,
                      child: GestureDetector(
                        onTap: () {
                          setState(() {
                            eventBannerBytes = null;
                            eventBannerExtension = null;
                          });
                          notifyParent();
                        },
                        child: CircleAvatar(
                          radius: 13,
                          backgroundColor: Colors.black.withOpacity(0.6),
                          child: const Icon(Icons.close, color: Colors.white, size: 14),
                        ),
                      ),
                    ),
                  ],
                )
                    : const Center(
                  child: Text(
                    'Tap here to upload banner (landscape image)',
                    style: TextStyle(color: Colors.grey),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              "Please upload only a landscape image.",
              style: TextStyle(color: Colors.grey, fontSize: 12, fontStyle: FontStyle.italic),
            ),
          ],
        ),
      ),
    );
  }
}

class DottedBorderContainer extends StatelessWidget {
  final double height;
  final double width;
  final Widget child;

  const DottedBorderContainer({
    super.key,
    required this.height,
    required this.width,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: height,
      width: width,
      decoration: BoxDecoration(
        border: Border.all(
          color: Colors.grey.shade400,
          style: BorderStyle.solid,
          width: 1.3,
        ),
        borderRadius: BorderRadius.circular(12),
      ),
      child: child,
    );
  }
}
