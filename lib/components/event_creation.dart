import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:firebase_database/firebase_database.dart';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:Marketing_Fruit/components/publish_section.dart';
import 'package:Marketing_Fruit/components/question_section.dart';
import 'package:Marketing_Fruit/components/target_audience.dart';
import 'package:Marketing_Fruit/components/time_place_section.dart';
import 'add_NFTform.dart';
import 'attendees_section.dart';
import 'event_details.dart';

class PendingEventData {
  String? eventName;
  dynamic eventDescriptionDelta;
  Uint8List? eventLogoBytes;
  String? eventLogoExt;
  String? eventLogoBase64;
  Uint8List? eventBannerBytes;
  String? eventBannerExt;
  String? eventBannerBase64;
  List<Map<String, String>> targetAudiences = [];
  String? location;
  int? startTimestamp;
  int? endTimestamp;
  Map<String, String>? placeFields;
  String? mapsLink;
  double? eventLatitude;
  double? eventLongitude;
  List<Map<String, String>> vipList = [];
  List<Map<String, dynamic>> questions = [];
  String? shareLink;
  String? logoUrlCached;
  String? bannerUrlCached;

  List<Map<String, dynamic>> eventNFTs = [];
  List<String> eventNFTIds = [];

  Map<String, dynamic> toJson() => {
    "eventName": eventName,
    "eventDescription": eventDescriptionDelta,
    "logoUrl": logoUrlCached ?? '',
    "bannerUrl": bannerUrlCached ?? '',
    "targetAudiences": targetAudiences,
    "location": location,
    "start": startTimestamp,
    "end": endTimestamp,
    "placeFields": placeFields,
    "mapsLink": mapsLink,
    "eventLatitude": eventLatitude,
    "eventLongitude": eventLongitude,
    "vipList": vipList,
    "questions": questions,
    "shareLink": shareLink ?? '',
    "createdAt": ServerValue.timestamp,
    "eventNFT": eventNFTIds,
  };

  List<Map<String, dynamic>> getNFTList() => eventNFTs;
}

class EventCreationScreen extends StatefulWidget {
  const EventCreationScreen({super.key});
  @override
  State<EventCreationScreen> createState() => _EventCreationScreenState();
}

class _EventCreationScreenState extends State<EventCreationScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;
  final PendingEventData _eventData = PendingEventData();
  String? _pendingEventId;

  static final List<String> _stepLabels = [
    'Event Details',
    'Target Audience',
    'Time and Place',
    'Attendees',
    'Questions',
    'Sponsor NFT',
    'Publish'
  ];

  List<Widget> get pages => [
    EventDetailsSection(
      onFormChanged: (data) {
        _eventData.eventName = data.eventName;
        _eventData.eventDescriptionDelta = data.descriptionJson;
        _eventData.eventLogoBytes = data.eventLogoBytes;
        _eventData.eventLogoExt = data.eventLogoExtension;
        _eventData.eventLogoBase64 =
        data.eventLogoBytes != null ? base64Encode(data.eventLogoBytes!) : null;
        _eventData.eventBannerBytes = data.eventBannerBytes;
        _eventData.eventBannerExt = data.eventBannerExtension;
        _eventData.eventBannerBase64 =
        data.eventBannerBytes != null ? base64Encode(data.eventBannerBytes!) : null;
      },
    ),
    TargetAudienceSection(onAudienceChanged: (audiences, location) {
      _eventData.targetAudiences = audiences;
      _eventData.location = location;
    }),
    TimeAndPlaceSection(onTimePlaceChanged: (
        int startTimestamp,
        int endTimestamp,
        Map<String, String> fields,
        String mapsLink,
        double? latitude,
        double? longitude,
        ) {
      _eventData.startTimestamp = startTimestamp;
      _eventData.endTimestamp = endTimestamp;
      _eventData.placeFields = fields;
      _eventData.mapsLink = mapsLink;
      _eventData.eventLatitude = latitude;
      _eventData.eventLongitude = longitude;
    }),
    AttendeesSection(onVIPsChanged: (vipList) {
      _eventData.vipList = vipList;
    }),
    QuestionsSection(onQuestionsChanged: (questions) {
      _eventData.questions = questions;
    }),
    AddNFTFormScreen(
      onBrandComplete: (nftObj, nftId) {
        setState(() {
          _eventData.eventNFTs.add(nftObj);
          _eventData.eventNFTIds.add(nftId);
        });
      },
    ),
    PublishSection(
      onPublish: _publishEventToDatabase,
      pendingEventId: _pendingEventId,
      nftListGetter: () => _eventData.getNFTList(),
    ),
  ];

  Future<String> uploadImageUniversal({
    required String? base64String,
    required Uint8List? bytes,
    required String storagePath,
    required String? fileExt,
  }) async {
    final storageRef = FirebaseStorage.instance.ref().child(storagePath);
    TaskSnapshot snapshot;
    if (kIsWeb) {
      if (base64String == null || base64String.isEmpty) {
        throw Exception("No Base64 string provided for web upload");
      }
      final cleanBase64 = base64String
          .replaceFirst(RegExp(r'data:image/[^;]+;base64,'), '')
          .replaceAll('\n', '')
          .trim();
      try {
        snapshot = await storageRef.putString(
          cleanBase64,
          format: PutStringFormat.base64,
          metadata: SettableMetadata(contentType: _guessMimeType(fileExt)),
        );
      } catch (e) {
        print("putString failed, trying putData: $e");
        final fallbackBytes = base64Decode(cleanBase64);
        snapshot = await storageRef.putData(
          fallbackBytes,
          SettableMetadata(contentType: _guessMimeType(fileExt)),
        );
      }
    } else {
      if (bytes == null) {
        throw Exception("No bytes provided for mobile upload");
      }
      snapshot = await storageRef.putData(
        bytes,
        SettableMetadata(contentType: _guessMimeType(fileExt)),
      );
    }
    final url = await snapshot.ref.getDownloadURL();
    return url;
  }

  String _guessMimeType(String? ext) {
    switch (ext?.toLowerCase()) {
      case 'jpg':
      case 'jpeg':
        return 'image/jpeg';
      case 'png':
        return 'image/png';
      case 'gif':
        return 'image/gif';
      default:
        return 'application/octet-stream';
    }
  }

  Future<void> _saveToPendingEvents() async {
    if (_eventData.eventName == null ||
        _eventData.eventLogoBytes == null ||
        _eventData.eventLogoExt == null ||
        _eventData.eventBannerBytes == null ||
        _eventData.eventBannerExt == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill all event details.')),
      );
      return;
    }
    try {
      String eventId =
          _pendingEventId ?? DateTime.now().millisecondsSinceEpoch.toString();
      // Set shareLink before saving:
      _eventData.shareLink = 'https://app.marketingfruit.net/events/$eventId';

      if (_pendingEventId == null) {
        final logoUrl = await uploadImageUniversal(
          base64String: _eventData.eventLogoBase64,
          bytes: _eventData.eventLogoBytes,
          fileExt: _eventData.eventLogoExt,
          storagePath: "events/$eventId/logo.${_eventData.eventLogoExt}",
        );
        final bannerUrl = await uploadImageUniversal(
          base64String: _eventData.eventBannerBase64,
          bytes: _eventData.eventBannerBytes,
          fileExt: _eventData.eventBannerExt,
          storagePath: "events/$eventId/banner.${_eventData.eventBannerExt}",
        );
        _eventData.logoUrlCached = logoUrl;
        _eventData.bannerUrlCached = bannerUrl;
      }
      final eventRef =
      FirebaseDatabase.instance.ref("pendingEvents/$eventId");
      await eventRef.set(_eventData.toJson());
      setState(() {
        _pendingEventId ??= eventId;
      });
    } catch (e, st) {
      print("Storage/DB upload error: $e\n$st");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to save event: $e')),
      );
    }
  }

  Future<void> _publishEventToDatabase() async {
    if (_pendingEventId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No pending event to publish!')),
      );
      return;
    }

    final String userId = FirebaseAuth.instance.currentUser?.uid ?? '';
    final db = FirebaseDatabase.instance;
    final pendingRef = db.ref("pendingEvents/$_pendingEventId");
    final eventsRef = db.ref("events/$_pendingEventId");
    final userRef = db.ref("users/$userId");

    final snapshot = await pendingRef.get();

    if (!snapshot.exists) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Pending event not found.")),
      );
      return;
    }

    final userSnap = await userRef.get();
    String organizer;
    if (userSnap.exists) {
      final userData = Map<String, dynamic>.from(userSnap.value as Map);
      final role = userData['role']?.toString().toLowerCase();
      if (role == 'brand') {
        organizer = userData['brand_name']?.toString() ?? "Brand";
      } else if (role == 'school') {
        organizer = userData['school']?.toString() ?? "School";
      } else {
        organizer = "Marketing Fruit Team";
      }
    } else {
      organizer = "Marketing Fruit Team";
    }

    final event = Map<String, dynamic>.from(snapshot.value as Map);
    event['organizer'] = organizer;
    event['eventNFT'] = _eventData.eventNFTIds;

    // Ensure shareLink is set correctly upon publishing (for redundancy/proof)
    event['shareLink'] = 'https://app.marketingfruit.net/events/$_pendingEventId';

    await eventsRef.set(event);
    await pendingRef.remove();

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Event published!")),
    );
    setState(() => _pendingEventId = null);
  }

  Future<void> _nextPage() async {
    await _saveToPendingEvents();
    if (_currentPage < pages.length - 1) {
      _pageController.nextPage(
          duration: const Duration(milliseconds: 300), curve: Curves.easeInOut);
      setState(() => _currentPage++);
    }
  }

  void _previousPage() {
    if (_currentPage > 0) {
      _pageController.previousPage(
          duration: const Duration(milliseconds: 300), curve: Curves.easeInOut);
      setState(() => _currentPage--);
    }
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final containerWidth = screenWidth * 0.9;
    return Scaffold(
      backgroundColor: Colors.grey[100],
      body: Center(
        child: Container(
          width: containerWidth,
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              EventTimelineSection(currentStep: _currentPage, labels: _stepLabels),
              const SizedBox(height: 16),
              Expanded(
                child: PageView(
                  controller: _pageController,
                  physics: const NeverScrollableScrollPhysics(),
                  onPageChanged: (page) => setState(() => _currentPage = page),
                  children: pages,
                ),
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  if (_currentPage > 0)
                    ElevatedButton(
                      onPressed: _previousPage,
                      child: const Text("Previous"),
                    ),
                  if (_currentPage < pages.length - 1)
                    Padding(
                      padding: const EdgeInsets.only(left: 8.0),
                      child: ElevatedButton(
                        onPressed: _nextPage,
                        child: const Text("Next"),
                      ),
                    ),
                ],
              )
            ],
          ),
        ),
      ),
    );
  }
}

class EventTimelineSection extends StatelessWidget {
  final int currentStep;
  final List<String> labels;
  const EventTimelineSection({super.key, required this.currentStep, required this.labels});
  @override
  Widget build(BuildContext context) {
    final containerWidth = MediaQuery.of(context).size.width * 0.9;
    return Center(
      child: Container(
        width: containerWidth,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Event List Timeline', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 24),
            Row(
              children: [
                for (int i = 0; i < labels.length; i++) ...[
                  _StepItem(
                    stepNumber: (i + 1).toString(),
                    label: labels[i],
                    isActive: i == currentStep,
                    isCompleted: i < currentStep,
                  ),
                  if (i != labels.length - 1)
                    const Expanded(child: Divider(thickness: 1, color: Colors.grey)),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _StepItem extends StatelessWidget {
  final String stepNumber;
  final String label;
  final bool isActive;
  final bool isCompleted;
  const _StepItem({required this.stepNumber, required this.label, required this.isActive, required this.isCompleted});
  @override
  Widget build(BuildContext context) {
    Color fillColor = isActive ? Colors.blue : isCompleted ? Colors.green : Colors.white;
    Color textColor = isActive || isCompleted ? Colors.white : Colors.black;
    return Row(
      children: [
        CircleAvatar(
          radius: 14,
          backgroundColor: fillColor,
          child: Text(stepNumber, style: TextStyle(color: textColor, fontSize: 12, fontWeight: FontWeight.bold)),
        ),
        const SizedBox(width: 6),
        Text(label, style: TextStyle(
          color: isActive ? Colors.black : isCompleted ? Colors.green : Colors.grey,
          fontWeight: isActive || isCompleted ? FontWeight.bold : FontWeight.normal,
        )),
      ],
    );
  }
}
