import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

class TimeAndPlaceSection extends StatefulWidget {
  final void Function(
      int startTimestamp,
      int endTimestamp,
      Map<String, String> placeFields,
      String mapsLink,
      double? latitude,
      double? longitude,
      ) onTimePlaceChanged;

  const TimeAndPlaceSection({
    super.key,
    required this.onTimePlaceChanged,
  });

  @override
  State<TimeAndPlaceSection> createState() => _TimeAndPlaceSectionState();
}

class _TimeAndPlaceSectionState extends State<TimeAndPlaceSection> {
  DateTime? _startDateTime;
  DateTime? _endDateTime;

  final TextEditingController _startController = TextEditingController();
  final TextEditingController _endController = TextEditingController();

  double? _pickedLatitude;
  double? _pickedLongitude;

  final Map<String, TextEditingController> _fields = {
    'Venue Name': TextEditingController(),
    'Address Line 1': TextEditingController(),
    'Address Line 2': TextEditingController(),
    'Landmark': TextEditingController(),
    'Area': TextEditingController(),
    'Zipcode': TextEditingController(),
  };
  final TextEditingController _mapsLinkController = TextEditingController();

  Future<void> _selectDateTime(BuildContext context, bool isStart) async {
    DateTime now = DateTime.now();
    DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: now,
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
    );
    if (pickedDate != null) {
      TimeOfDay? pickedTime = await showTimePicker(
        context: context,
        initialTime: TimeOfDay.fromDateTime(now),
      );
      if (pickedTime != null) {
        DateTime finalDateTime = DateTime(
          pickedDate.year,
          pickedDate.month,
          pickedDate.day,
          pickedTime.hour,
          pickedTime.minute,
        );
        setState(() {
          if (isStart) {
            _startDateTime = finalDateTime;
            _startController.text =
            "${finalDateTime.year}-${finalDateTime.month.toString().padLeft(2, '0')}-${finalDateTime.day.toString().padLeft(2, '0')} ${finalDateTime.hour.toString().padLeft(2, '0')}:${finalDateTime.minute.toString().padLeft(2, '0')}";
          } else {
            _endDateTime = finalDateTime;
            _endController.text =
            "${finalDateTime.year}-${finalDateTime.month.toString().padLeft(2, '0')}-${finalDateTime.day.toString().padLeft(2, '0')} ${finalDateTime.hour.toString().padLeft(2, '0')}:${finalDateTime.minute.toString().padLeft(2, '0')}";
          }
        });
        _triggerCallback();
      }
    }
  }

  void _triggerCallback() {
    widget.onTimePlaceChanged(
      _startDateTime?.millisecondsSinceEpoch ?? 0,
      _endDateTime?.millisecondsSinceEpoch ?? 0,
      _fields.map((k, v) => MapEntry(k, v.text)),
      _mapsLinkController.text,
      _pickedLatitude,
      _pickedLongitude,
    );
  }

  Widget _buildTextField(String label) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(label, style: const TextStyle(fontWeight: FontWeight.w600)),
      const SizedBox(height: 8),
      TextFormField(
        controller: _fields[label],
        onChanged: (_) => _triggerCallback(),
        decoration: InputDecoration(
          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
    ],
  );

  Future<void> _openMapPicker(BuildContext context) async {
    LatLng selected = const LatLng(22.720361, 75.868263); // Default: Indore/Ratlam
    Completer<GoogleMapController> controller = Completer();

    await showDialog(
      context: context,
      builder: (context) {
        LatLng? picked;
        Set<Marker> markers = {};
        return StatefulBuilder(
          builder: (context, setStateSB) => SizedBox(
            width: 600, // Responsive for web/desktop
            height: 450,
            child: AlertDialog(
              contentPadding: EdgeInsets.zero,
              content: SizedBox(
                width: 500,
                height: 350,
                child: GoogleMap(
                  initialCameraPosition: CameraPosition(
                    target: selected,
                    zoom: 12,
                  ),
                  onMapCreated: (GoogleMapController c) {
                    controller.complete(c);
                  },
                  markers: markers,
                  onTap: (LatLng latlng) {
                    setStateSB(() {
                      picked = latlng;
                      markers = {
                        Marker(
                          markerId: const MarkerId("picked-location"),
                          position: latlng,
                          infoWindow: const InfoWindow(title: "Selected Location"),
                        )
                      };
                    });
                  },
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text("Cancel"),
                ),
                ElevatedButton(
                  onPressed: () {
                    if (picked != null) {
                      _pickedLatitude = picked!.latitude;
                      _pickedLongitude = picked!.longitude;
                      String gMapsUrl = "https://www.google.com/maps/search/?api=1&query=${picked!.latitude},${picked!.longitude}";
                      _mapsLinkController.text = gMapsUrl;
                      _triggerCallback();
                    }
                    Navigator.pop(context);
                  },
                  child: const Text("Select Location"),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Container(
        width: MediaQuery.of(context).size.width * 0.9,
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextFormField(
              controller: _startController,
              readOnly: true,
              decoration: InputDecoration(
                hintText: 'Select Start Date & Time',
                suffixIcon: MouseRegion(
                  cursor: SystemMouseCursors.click,
                  child: const Icon(Icons.calendar_today),
                ),
                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              onTap: () => _selectDateTime(context, true),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _endController,
              readOnly: true,
              decoration: InputDecoration(
                hintText: 'Select End Date & Time',
                suffixIcon: MouseRegion(
                  cursor: SystemMouseCursors.click,
                  child: const Icon(Icons.calendar_today),
                ),
                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              onTap: () => _selectDateTime(context, false),
            ),
            const SizedBox(height: 24),
            ..._fields.keys.map(_buildTextField),
            const SizedBox(height: 16),
            GestureDetector(
              onTap: () => _openMapPicker(context),
              child: AbsorbPointer(
                // Prevents keyboard from appearing
                child: TextFormField(
                  controller: _mapsLinkController,
                  readOnly: true,
                  decoration: InputDecoration(
                    hintText: 'Tap to select exact location',
                    suffixIcon: MouseRegion(
                      cursor: SystemMouseCursors.click,
                      child: const Icon(Icons.location_on),
                    ),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
