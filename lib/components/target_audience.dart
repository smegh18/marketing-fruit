import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class TargetAudienceSection extends StatefulWidget {
  final void Function(List<Map<String, String>> audience, String location) onAudienceChanged;
  const TargetAudienceSection({super.key, required this.onAudienceChanged});

  @override
  State<TargetAudienceSection> createState() => _TargetAudienceSectionState();
}

class _TargetAudienceSectionState extends State<TargetAudienceSection> {
  final List<String> allCategories = ['Student', 'Guardian', 'Brand', 'School'];
  String? selectedCategory;
  String? selectedAudience;
  final TextEditingController locationController = TextEditingController();
  List<Map<String, String>> audienceList = [];

  // --- New for Suggestions ---
  List<String> locationSuggestions = [];
  OverlayEntry? _suggestionsOverlay;
  final FocusNode _locationFocusNode = FocusNode();

  List<String> get audienceOptions {
    switch (selectedCategory) {
      case 'Student': return ['Undergraduate', 'Postgraduate', 'School Students'];
      case 'Brand': return ['Tech', 'Fashion', 'FMCG'];
      case 'School': return ['Public', 'Private', 'International'];
      default: return [];
    }
  }

  @override
  void initState() {
    super.initState();
    _locationFocusNode.addListener(_handleLocationFocus);
  }

  @override
  void dispose() {
    _locationFocusNode.removeListener(_handleLocationFocus);
    locationController.dispose();
    _removeSuggestionsOverlay();
    super.dispose();
  }

  void _handleLocationFocus() {
    if (!_locationFocusNode.hasFocus) _removeSuggestionsOverlay();
  }

  void _addAudience() {
    if (selectedCategory == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Please select a category")));
      return;
    }
    if (selectedCategory == 'Guardian') {
      setState(() {
        audienceList.add({'category': 'Guardian', 'audience': ''});
      });
      widget.onAudienceChanged(audienceList, locationController.text);
      return;
    }
    if (selectedAudience == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Please select audience")));
      return;
    }
    setState(() {
      audienceList.add({'category': selectedCategory!, 'audience': selectedAudience!});
      selectedAudience = null;
    });
    widget.onAudienceChanged(audienceList, locationController.text);
  }

  void _removeAudience(int index) {
    setState(() {
      audienceList.removeAt(index);
    });
    widget.onAudienceChanged(audienceList, locationController.text);
  }

  // --- Google Places Suggestion Logic ---
  Future<void> fetchLocationSuggestions(String input) async {
    if (input.trim().length < 3) {
      setState(() => locationSuggestions = []);
      _removeSuggestionsOverlay();
      return;
    }
    final url = Uri.parse(
      'https://us-central1-marketingfruit-9e24d.cloudfunctions.net/placesProxy?input=${Uri.encodeComponent(input.trim())}',
    );
    try {
      final response = await http.get(url);
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['status'] == 'OK') {
          setState(() {
            locationSuggestions = List<String>.from(
              data['predictions'].map((p) => p['description'] as String),
            );
          });
          _showSuggestionsOverlay();
        }
      }
    } catch (e) {
      print("Location fetch error: $e");
    }
  }

  void _showSuggestionsOverlay() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _removeSuggestionsOverlay(); // remove old if present

      if (!_locationFocusNode.hasFocus || locationSuggestions.isEmpty) return;

      // final RenderBox box = context.findRenderObject() as RenderBox;
      final RenderBox? fieldBox = _locationKey.currentContext?.findRenderObject() as RenderBox?;

      final fieldOffset = fieldBox?.localToGlobal(Offset.zero) ?? Offset.zero;
      final fieldHeight = fieldBox?.size.height ?? 50;
      // final fieldWidth = fieldBox?.size.width ?? 300;

      _suggestionsOverlay = OverlayEntry(
        builder: (context) => Positioned(
          left: fieldOffset.dx,
          top: fieldOffset.dy + fieldHeight + 4,
          width: fieldBox?.size.width ?? 300,
          child: Material(
            color: Colors.transparent,
            child: Card(
              margin: EdgeInsets.zero,
              child: ListView.builder(
                padding: EdgeInsets.zero,
                itemCount: locationSuggestions.length,
                shrinkWrap: true,
                itemBuilder: (_, i) => ListTile(
                  title: Text(locationSuggestions[i]),
                  onTap: () {
                    locationController.text = locationSuggestions[i];
                    widget.onAudienceChanged(audienceList, locationController.text);
                    setState(() => locationSuggestions = []);
                    _removeSuggestionsOverlay();
                    FocusScope.of(context).requestFocus(FocusNode());
                  },
                ),
              ),
            ),
          ),
        ),
      );
      Overlay.of(context).insert(_suggestionsOverlay!);
    });
  }

  void _removeSuggestionsOverlay() {
    _suggestionsOverlay?.remove();
    _suggestionsOverlay = null;
  }

  // Unique key for the location field for overlay placement
  final GlobalKey _locationKey = GlobalKey();

  @override
  Widget build(BuildContext context) {
    final containerWidth = MediaQuery.of(context).size.width * 0.9;
    return Center(
      child: Container(
        width: containerWidth,
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Target Audience', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 24),
            const Text('Choose Category', style: TextStyle(fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            Wrap(
              spacing: 10,
              children: allCategories.map((category) => ChoiceChip(
                label: Text(category),
                selected: selectedCategory == category,
                onSelected: (_) {
                  setState(() {
                    if (selectedCategory == category) {
                      selectedCategory = null;
                      selectedAudience = null;
                    } else {
                      selectedCategory = category;
                      selectedAudience = null;
                    }
                  });
                },
              )).toList(),
            ),
            const SizedBox(height: 24),
            if (selectedCategory != null && selectedCategory != 'Guardian' && audienceOptions.isNotEmpty) ...[
              const Text('Select Audience', style: TextStyle(fontWeight: FontWeight.w600)),
              const SizedBox(height: 8),
              DropdownButtonFormField<String>(
                value: selectedAudience,
                items: audienceOptions.map((audience) => DropdownMenuItem<String>(value: audience, child: Text(audience))).toList(),
                onChanged: (value) { setState(() { selectedAudience = value; }); },
                decoration: InputDecoration(
                  contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
              const SizedBox(height: 16),
            ],
            ElevatedButton(onPressed: _addAudience, child: const Text('Add Audience')),
            const SizedBox(height: 24),
            if (audienceList.isNotEmpty) ...[
              const Text('Selected Audiences', style: TextStyle(fontWeight: FontWeight.w600)),
              const SizedBox(height: 8),
              ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: audienceList.length,
                separatorBuilder: (_, __) => const Divider(),
                itemBuilder: (_, index) {
                  final item = audienceList[index];
                  final displayText =
                  item['category'] == 'Guardian' ? 'Guardian' : "${item['category']} - ${item['audience']}";
                  return ListTile(
                    title: Text(displayText),
                    trailing: IconButton(
                      icon: const Icon(Icons.delete, color: Colors.red),
                      onPressed: () => _removeAudience(index),
                    ),
                  );
                },
              ),
              const SizedBox(height: 16),
            ],
            // ---- Location input with autocomplete ----
            Stack(
              children: [
                TextFormField(
                  key: _locationKey,
                  controller: locationController,
                  focusNode: _locationFocusNode,
                  onChanged: (v) {
                    widget.onAudienceChanged(audienceList, v);
                    fetchLocationSuggestions(v);
                  },
                  decoration: InputDecoration(
                    labelText: 'Location',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
