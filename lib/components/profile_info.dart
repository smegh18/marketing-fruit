import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:geocoding/geocoding.dart';
import 'package:http/http.dart' as http;
import 'package:file_picker/file_picker.dart';
import 'package:url_launcher/url_launcher.dart';

/// Roles:
///   Student, Guardian, School, Brand
///
/// Student/Guardian: Bio (+ Resume only for Student)
/// School/Brand: <Entity> Information + Website + Representative section
class ProfileInformationSection extends StatefulWidget {
  final double width;
  final bool disabled;
  final String userId;

  /// Pass explicit role if you have it; otherwise it auto-detects from DB.
  final String role;

  const ProfileInformationSection({
    super.key,
    required this.width,
    required this.userId,
    this.role = '',
    this.disabled = false,
  });

  @override
  State<ProfileInformationSection> createState() =>
      _ProfileInformationSectionState();
}

class _ProfileInformationSectionState extends State<ProfileInformationSection> {
  final dbRef = FirebaseDatabase.instance.ref();

  Map<String, dynamic> studentData = {};
  bool isLoading = true;

  bool _uploadingPhoto = false;
  bool _uploadingResume = false;
  bool _removingPhoto = false;
  bool _removingResume = false;

  String effectiveRole = 'Student'; // default

  @override
  void initState() {
    super.initState();
    _fetchStudentData();
  }

  // --- Web reverse geocode for country/state (optional) ---
  Future<Map<String, String>> reverseGeocode(
      double latitude, double longitude, String apiKey) async {
    final url = Uri.parse(
      'https://maps.googleapis.com/maps/api/geocode/json?latlng=$latitude,$longitude&key=$apiKey',
    );

    final response = await http.get(url);
    if (response.statusCode == 200) {
      final jsonData = json.decode(response.body);
      if (jsonData['status'] == 'OK') {
        final results = jsonData['results'];
        String? country;
        String? state;

        for (var component in results.first['address_components']) {
          final types = List<String>.from(component['types']);
          if (types.contains('country')) {
            country = component['long_name'];
          } else if (types.contains('administrative_area_level_1')) {
            state = component['long_name'];
          }
        }

        return {'country': country ?? '', 'state': state ?? ''};
      } else {
        throw Exception('Geocoding API error: ${jsonData['status']}');
      }
    } else {
      throw Exception('HTTP error: ${response.statusCode}');
    }
  }

  // Try to pull a recent lat/lng from "location history"
  Map<String, double>? _extractLastKnownLatLng(Map<String, dynamic> data) {
    final hist = data['location history'];
    if (hist is! Map) return null;

    // Prefer "Accurate Location" if present, else any map
    Map<dynamic, dynamic>? bucket;
    if (hist['Accurate Location'] is Map) {
      bucket = hist['Accurate Location'] as Map;
    } else if (hist['Approx Location'] is Map) {
      bucket = hist['Approx Location'] as Map;
    } else if (hist.isNotEmpty) {
      bucket = hist.values.firstWhere((v) => v is Map, orElse: () => null);
    }
    if (bucket == null) return null;

    // bucket structure: { "YYYY-MM-DD": { "HH:mm" or timeKey: {lat, lng} } }
    // Walk from latest date -> latest time to find lat/lng.
    try {
      final dates = bucket.keys.map((e) => e.toString()).toList()..sort();
      for (final d in dates.reversed) {
        final dayMap = bucket[d];
        if (dayMap is Map) {
          final times = dayMap.keys.map((e) => e.toString()).toList()..sort();
          for (final t in times.reversed) {
            final rec = dayMap[t];
            if (rec is Map &&
                rec['latitude'] != null &&
                rec['longitude'] != null) {
              final lat = double.tryParse(rec['latitude'].toString());
              final lng = double.tryParse(rec['longitude'].toString());
              if (lat != null && lng != null) {
                return {'latitude': lat, 'longitude': lng};
              }
            }
          }
        }
      }
    } catch (_) {
      // ignore parse errors
    }
    return null;
  }

  String _resolveRoleFromData(Map<String, dynamic> data) {
    String fromProp = widget.role.trim();
    if (fromProp.isNotEmpty) return fromProp;

    final candidates = [
      data['role'],
      data['userRole'],
      data['account_type'],
    ].where((e) => e != null && e.toString().trim().isNotEmpty).toList();

    if (candidates.isEmpty) return 'Student';
    return candidates.first.toString();
  }

  String _readPosition(Map<String, dynamic> data) {
    // Prefer explicit representative_position, else fallback to position
    final rep = (data['representative_position'] ?? '').toString();
    if (rep.trim().isNotEmpty) return rep.trim();
    final pos = (data['position'] ?? '').toString();
    return pos.trim();
  }

  Future<void> _fetchStudentData() async {
    final snapshot = await dbRef.child('users/${widget.userId}').get();

    Map<String, dynamic> data = {};
    if (snapshot.exists) {
      data = Map<String, dynamic>.from(snapshot.value as Map);
    }

    // ---- Role detection (prop > DB > fallback) ----
    effectiveRole = _resolveRoleFromData(data);

    // ---- Location: support Map, String, or none ----
    String country = data['country']?.toString() ?? '';
    String state = data['state']?.toString() ?? '';
    String locationText = data['location_text']?.toString() ?? '';

    double? lat;
    double? lng;

    final dynamic loc = data['location']; // may be Map or String or null
    if (loc is Map) {
      try {
        final m = Map<String, dynamic>.from(loc);
        lat = double.tryParse(m['latitude']?.toString() ?? '');
        lng = double.tryParse(m['longitude']?.toString() ?? '');
      } catch (_) {
        // ignore
      }
    } else if (loc is String && loc.trim().isNotEmpty) {
      locationText = loc.trim(); // keep the user-friendly string
    }

    // If we still don't have lat/lng, try "location history"
    if (lat == null || lng == null) {
      final last = _extractLastKnownLatLng(data);
      if (last != null) {
        lat = last['latitude'];
        lng = last['longitude'];
      }
    }

    // Optionally reverse-geocode to fill country/state (if empty)
    if ((country.isEmpty || state.isEmpty) && lat != null && lng != null) {
      try {
        if (kIsWeb) {
          final result = await reverseGeocode(
            lat,
            lng,
            'AIzaSyBFGd1hXyEqZVJqC34aDDeO7U1tYPn_Snk', // replace with yours
          );
          country = country.isEmpty ? (result['country'] ?? '') : country;
          state = state.isEmpty ? (result['state'] ?? '') : state;
        } else {
          final placemarks = await placemarkFromCoordinates(lat, lng);
          if (placemarks.isNotEmpty) {
            final place = placemarks.first;
            country = country.isEmpty ? (place.country ?? '') : country;
            state = state.isEmpty ? (place.administrativeArea ?? '') : state;
          }
        }
      } catch (e) {
        debugPrint('Reverse geocoding error: $e');
      }
    }

    // If School/Brand, normalize representative position (fetch from 'position' fallback)
    final isSchool = effectiveRole.toLowerCase() == 'school';
    final isBrand = effectiveRole.toLowerCase() == 'brand';
    final isSchoolOrBrand = isSchool || isBrand;
    final repPos = _readPosition(data);

    setState(() {
      studentData = {
        ...data,
        if (country.isNotEmpty) 'country': country,
        if (state.isNotEmpty) 'state': state,
        if (locationText.isNotEmpty) 'location_text': locationText,
        if (isSchoolOrBrand && repPos.isNotEmpty)
          'representative_position': repPos,
      };
      isLoading = false;
    });
  }

  void _saveField(String key, String value) {
    setState(() => studentData[key] = value);
    dbRef.child('users/${widget.userId}/$key').set(value);
  }

  Future<String> _uploadBytesToStorage({
    required Uint8List bytes,
    required String storagePath,
    required String contentType,
  }) async {
    final ref = FirebaseStorage.instance.ref().child(storagePath);
    final metadata = SettableMetadata(contentType: contentType);
    final task = await ref.putData(bytes, metadata);
    return await task.ref.getDownloadURL();
  }

  Future<void> _pickAndUploadProfilePhoto() async {
    if (_uploadingPhoto) return;
    setState(() => _uploadingPhoto = true);

    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.image,
        allowMultiple: false,
        withData: true,
      );
      if (result == null || result.files.isEmpty) {
        setState(() => _uploadingPhoto = false);
        return;
      }

      final file = result.files.single;
      final bytes = file.bytes;
      if (bytes == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not read image bytes. Try again.')),
        );
        setState(() => _uploadingPhoto = false);
        return;
      }

      final ext = (file.extension ?? 'jpg').toLowerCase();
      final contentType = ext == 'png' ? 'image/png' : 'image/jpeg';
      final path =
          'users/${widget.userId}/profile/photo_${DateTime.now().millisecondsSinceEpoch}.$ext';

      final url = await _uploadBytesToStorage(
        bytes: bytes,
        storagePath: path,
        contentType: contentType,
      );

      _saveField('profile_photo', url);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Profile photo updated.')),
      );
    } catch (e) {
      debugPrint('Photo upload error: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to upload photo: $e')),
      );
    } finally {
      if (mounted) setState(() => _uploadingPhoto = false);
    }
  }

  Future<void> _pickAndUploadResume() async {
    if (_uploadingResume) return;
    setState(() => _uploadingResume = true);

    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: const ['pdf'],
        allowMultiple: false,
        withData: true,
      );
      if (result == null || result.files.isEmpty) {
        setState(() => _uploadingResume = false);
        return;
      }

      final file = result.files.single;
      final bytes = file.bytes;
      if (bytes == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not read PDF bytes. Try again.')),
        );
        setState(() => _uploadingResume = false);
        return;
      }

      final safeName = (file.name.isNotEmpty ? file.name : 'resume.pdf')
          .replaceAll(RegExp(r'[^a-zA-Z0-9._-]'), '_');

      final path =
          'users/${widget.userId}/resume/resume_${DateTime.now().millisecondsSinceEpoch}_$safeName';

      final url = await _uploadBytesToStorage(
        bytes: bytes,
        storagePath: path,
        contentType: 'application/pdf',
      );

      _saveField('resume_url', url);
      _saveField('resume_name', safeName);

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Resume uploaded.')),
      );
    } catch (e) {
      debugPrint('Resume upload error: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to upload resume: $e')),
      );
    } finally {
      if (mounted) setState(() => _uploadingResume = false);
    }
  }

  Future<void> _openResume() async {
    final urlStr = (studentData['resume_url'] ?? '').toString();
    if (urlStr.isEmpty) return;
    final uri = Uri.tryParse(urlStr);
    if (uri == null) return;
    if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not open resume link.')),
      );
    }
  }

  Future<void> _removeProfilePhoto() async {
    if (_removingPhoto) return;
    final photoUrl = (studentData['profile_photo'] ?? '').toString();
    if (photoUrl.isEmpty) return;

    setState(() => _removingPhoto = true);
    try {
      await FirebaseStorage.instance.refFromURL(photoUrl).delete();
    } catch (_) {}
    _saveField('profile_photo', '');
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Profile photo removed.')),
    );
    if (mounted) setState(() => _removingPhoto = false);
  }

  Future<void> _removeResume() async {
    if (_removingResume) return;
    final resumeUrl = (studentData['resume_url'] ?? '').toString();
    if (resumeUrl.isEmpty) return;

    setState(() => _removingResume = true);
    try {
      await FirebaseStorage.instance.refFromURL(resumeUrl).delete();
    } catch (_) {}
    _saveField('resume_url', '');
    _saveField('resume_name', '');
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Resume removed.')),
    );
    if (mounted) setState(() => _removingResume = false);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final fullWidth = MediaQuery.of(context).size.width;
    final width = fullWidth * widget.width;
    final horizontalPadding = kIsWeb ? 0.0 : 12.0;

    if (isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    final photoUrl = (studentData['profile_photo'] ?? '').toString();
    final resumeName = (studentData['resume_name'] ?? '').toString();
    final hasResume = (studentData['resume_url'] ?? '').toString().isNotEmpty;

    final r = effectiveRole.toLowerCase();
    final bool isSchool = r == 'school';
    final bool isBrand = r == 'brand';
    final bool isGuardian = r == 'guardian';
    final bool isStudentOrGuardian = !(isSchool || isBrand);

    final String entityLabel = isSchool ? 'School' : (isBrand ? 'Brand' : '');
    final String entityInfoKey = isSchool
        ? 'school_info'
        : (isBrand ? 'brand_info' : 'bio');

    return IgnorePointer(
      ignoring: widget.disabled,
      child: Opacity(
        opacity: widget.disabled ? 0.85 : 1.0,
        child: Container(
          height: MediaQuery.of(context).size.height * 0.9,
          width: kIsWeb ? width : null,
          margin: kIsWeb
              ? EdgeInsets.zero
              : EdgeInsets.symmetric(horizontal: horizontalPadding),
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: theme.cardColor,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.18),
                blurRadius: 8,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isSchool
                      ? 'School Profile'
                      : (isBrand ? 'Brand Profile' : 'Profile Information'),
                  style: GoogleFonts.poppins(
                    fontWeight: FontWeight.bold,
                    fontSize: 22,
                    color: theme.hintColor,
                  ),
                ),
                const SizedBox(height: 14),

                // ---- PROFILE PHOTO ----
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    CircleAvatar(
                      radius: 36,
                      backgroundColor: Colors.grey.shade300,
                      backgroundImage:
                          photoUrl.isNotEmpty ? NetworkImage(photoUrl) : null,
                      child: photoUrl.isEmpty
                          ? Icon(Icons.person, size: 36, color: Colors.grey.shade700)
                          : null,
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Row(
                        children: [
                          ElevatedButton.icon(
                            onPressed: widget.disabled || _uploadingPhoto
                                ? null
                                : _pickAndUploadProfilePhoto,
                            icon: _uploadingPhoto
                                ? const SizedBox(
                                    height: 16,
                                    width: 16,
                                    child: CircularProgressIndicator(strokeWidth: 2),
                                  )
                                : const Icon(Icons.upload_file),
                            label: Text(photoUrl.isEmpty ? 'Upload Photo' : 'Replace Photo'),
                          ),
                          if (photoUrl.isNotEmpty) ...[
                            const SizedBox(width: 8),
                            IconButton(
                              tooltip: 'Delete photo',
                              onPressed: widget.disabled || _removingPhoto
                                  ? null
                                  : _removeProfilePhoto,
                              icon: _removingPhoto
                                  ? const SizedBox(
                                      height: 20,
                                      width: 20,
                                      child: CircularProgressIndicator(strokeWidth: 2),
                                    )
                                  : const Icon(Icons.delete, color: Colors.red),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ],
                ),

                const Divider(height: 30, thickness: 0.8),

                if (isStudentOrGuardian)
                  ..._buildStudentGuardianSection(
                    hasResume,
                    resumeName,
                    isGuardian: isGuardian,
                  )
                else
                  ..._buildSchoolBrandSection(entityLabel, entityInfoKey),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ---- Student & Guardian: Bio + (Resume only for Student) + personal fields ----
  List<Widget> _buildStudentGuardianSection(
    bool hasResume,
    String resumeName, {
    required bool isGuardian,
  }) {
    final theme = Theme.of(context);

    final widgets = <Widget>[
      Padding(
        padding: const EdgeInsets.only(top: 8.0, bottom: 12.0),
        child: EditableTextField(
          label: "Bio",
          value: studentData['bio'] ?? '',
          hint: "Write your bio",
          minLines: 2,
          maxLines: 4,
          readOnly: widget.disabled,
          onSave: (val) => _saveField('bio', val),
        ),
      ),
      const Divider(height: 30, thickness: 0.8),
    ];

    // --- Resume block: show ONLY for Student (not for Guardian) ---
    if (!isGuardian) {
      widgets.addAll([
        Row(
          children: [
            Expanded(
              child: Row(
                children: [
                  ElevatedButton.icon(
                    onPressed: widget.disabled || _uploadingResume
                        ? null
                        : _pickAndUploadResume,
                    icon: _uploadingResume
                        ? const SizedBox(
                            height: 16,
                            width: 16,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.picture_as_pdf),
                    label: Text(hasResume ? 'Replace Resume' : 'Upload Resume'),
                  ),
                  if (hasResume) ...[
                    const SizedBox(width: 8),
                    IconButton(
                      tooltip: 'Open resume',
                      onPressed: _openResume,
                      icon: const Icon(Icons.open_in_new),
                    ),
                    const SizedBox(width: 8),
                    IconButton(
                      tooltip: 'Delete resume',
                      onPressed: widget.disabled || _removingResume
                          ? null
                          : _removeResume,
                      icon: _removingResume
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.delete, color: Colors.red),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
        if (hasResume)
          Padding(
            padding: const EdgeInsets.only(top: 6.0),
            child: Row(
              children: [
                const Icon(Icons.description, size: 16),
                const SizedBox(width: 6),
                Flexible(
                  child: Text(
                    resumeName.isNotEmpty ? resumeName : 'resume.pdf',
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.poppins(fontSize: 14),
                  ),
                ),
              ],
            ),
          ),
        const Divider(height: 30, thickness: 0.8),
      ]);
    }

    // ---- Personal fields ----
    // For Guardian: remove School Name + Country + State
    final baseWeb = <Widget>[
      _buildRowFields(['first_name', 'last_name'], ['First Name', 'Last Name']),
      _buildField('Mobile Number', 'mobile'),
      _buildField('Email', 'email', isEmail: true),
      _buildField('Password', 'password', isPassword: true),
      _buildRowFields(['gender', 'dob'], ['Gender', 'DOB']),
      if (!isGuardian) _buildField('School Name', 'school'),
      if (!isGuardian)
        _buildRowFields(['country', 'state'], ['Country', 'State']),
    ];

    final baseMobile = <Widget>[
      _buildField('First Name', 'first_name'),
      _buildField('Last Name', 'last_name'),
      _buildField('Mobile Number', 'mobile'),
      _buildField('Email', 'email', isEmail: true),
      _buildField('Password', 'password', isPassword: true),
      _buildField('Gender', 'gender'),
      _buildField('DOB', 'dob'),
      if (!isGuardian) _buildField('School Name', 'school'),
      if (!isGuardian) _buildField('Country', 'country'),
      if (!isGuardian) _buildField('State', 'state'),
    ];

    widgets.addAll(kIsWeb ? baseWeb : baseMobile);

    return widgets;
  }

  // ---- School & Brand ----
  List<Widget> _buildSchoolBrandSection(String entityLabel, String entityInfoKey) {
    final theme = Theme.of(context);
    final isSchool = entityLabel == 'School';
    final nameKey = isSchool ? 'school' : 'brand';

    // Pre-resolve position from Firebase (already normalized in state)
    final representativePosition =
        (studentData['representative_position'] ?? '').toString();

    return [
      // Information (multi-line)
      Padding(
        padding: const EdgeInsets.only(top: 8.0, bottom: 12.0),
        child: EditableTextField(
          label: '$entityLabel Information',
          value: studentData[entityInfoKey] ?? '',
          hint: 'Tell us about your $entityLabel',
          minLines: 3,
          maxLines: 6,
          readOnly: widget.disabled,
          onSave: (val) => _saveField(entityInfoKey, val),
        ),
      ),
      const Divider(height: 30, thickness: 0.8),

      // Website
      _buildUrlField('$entityLabel Website', 'website'),

      const Divider(height: 30, thickness: 0.8),

      // Representative Heading
      Text(
        '$entityLabel Representative',
        style: GoogleFonts.poppins(
          fontWeight: FontWeight.w700,
          fontSize: 18,
          color: theme.hintColor,
        ),
      ),
      const SizedBox(height: 12),

      ...(kIsWeb
          ? [
              _buildField('$entityLabel Name', nameKey),
              _buildRowFields(['first_name', 'last_name'], ['First Name', 'Last Name']),
              _buildField('Location', 'location_text'),
              // Representative Position from Firebase (read-only)
              _buildField('Representative Position', 'representative_position',
                  readOnly: true),
              _buildField('Gender', 'gender'),
              _buildField('DOB', 'dob'),
              // Country/State intentionally omitted for School & Brand
              _buildField('Email', 'email', isEmail: true),
              _buildField('Mobile Number', 'mobile'),
            ]
          : [
              _buildField('$entityLabel Name', nameKey),
              _buildField('First Name', 'first_name'),
              _buildField('Last Name', 'last_name'),
              _buildField('Location', 'location_text'),
              _buildField('Representative Position', 'representative_position',
                  readOnly: true),
              _buildField('Gender', 'gender'),
              _buildField('DOB', 'dob'),
              _buildField('Email', 'email', isEmail: true),
              _buildField('Mobile Number', 'mobile'),
            ]),

      if (representativePosition.isEmpty &&
          (studentData['position'] ?? '').toString().isNotEmpty)
        Padding(
          padding: const EdgeInsets.only(top: 6.0),
          child: Text(
            'Note: Using position fetched from your account data.',
            style: GoogleFonts.poppins(fontSize: 12, color: theme.hintColor.withOpacity(0.7)),
          ),
        ),
    ];
  }

  // ---- Field builders ----
  Widget _buildField(
    String label,
    String key, {
    bool isEmail = false,
    bool isPassword = false,
    bool readOnly = false,
  }) {
    final theme = Theme.of(context);
    final value = studentData[key]?.toString() ?? '';

    final effectiveReadOnly = readOnly || isPassword || isEmail || widget.disabled;

    return Padding(
      padding: const EdgeInsets.only(bottom: 14.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "$label:",
            style: GoogleFonts.poppins(
              fontWeight: FontWeight.w600,
              color: theme.hintColor,
              fontSize: 16,
            ),
          ),
          EditableTextField(
            label: label,
            value: isPassword ? '********' : value,
            hint: isPassword
                ? 'Tap to change password'
                : (isEmail ? 'Tap to verify/change email' : 'Enter $label'),
            onSave: effectiveReadOnly ? null : (val) => _saveField(key, val),
            onTap: effectiveReadOnly
                ? null
                : (isEmail
                    ? () => _showEmailOTPDialog(context)
                    : (isPassword
                        ? () => _showPasswordChangeDialog(context)
                        : null)),
            readOnly: effectiveReadOnly,
          ),
        ],
      ),
    );
  }

  Widget _buildUrlField(String label, String key) {
    final theme = Theme.of(context);
    final value = studentData[key]?.toString() ?? '';

    return Padding(
      padding: const EdgeInsets.only(bottom: 14.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "$label:",
            style: GoogleFonts.poppins(
              fontWeight: FontWeight.w600,
              color: theme.hintColor,
              fontSize: 16,
            ),
          ),
          Row(
            children: [
              Expanded(
                child: EditableTextField(
                  label: label,
                  value: value,
                  hint: 'https://your-${label.toLowerCase().replaceAll(' ', '-')}.com',
                  onSave: (val) => _saveField(key, val),
                  readOnly: widget.disabled,
                ),
              ),
              const SizedBox(width: 8),
              IconButton(
                tooltip: 'Open',
                onPressed: value.trim().isEmpty
                    ? null
                    : () async {
                        Uri? uri = Uri.tryParse(value.trim());
                        if (uri != null &&
                            (uri.isScheme('http') || uri.isScheme('https'))) {
                          await launchUrl(uri, mode: LaunchMode.externalApplication);
                        } else {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Invalid website URL')),
                          );
                        }
                      },
                icon: const Icon(Icons.open_in_new),
                color: theme.hintColor,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildRowFields(List<String> keys, List<String> labels) {
    return Row(
      children: List.generate(keys.length, (index) {
        return Expanded(child: _buildField(labels[index], keys[index]));
      }),
    );
  }

  // Stubs for optional flows
  void _showEmailOTPDialog(BuildContext context) {}
  void _showPasswordChangeDialog(BuildContext context) {}
}

class EditableTextField extends StatefulWidget {
  final String label;
  final String value;
  final bool readOnly;
  final VoidCallback? onTap;
  final Function(String)? onSave;

  final String? hint;
  final int? minLines;
  final int? maxLines;

  const EditableTextField({
    super.key,
    required this.label,
    required this.value,
    this.readOnly = false,
    this.onTap,
    this.onSave,
    this.hint,
    this.minLines,
    this.maxLines,
  });

  @override
  State<EditableTextField> createState() => _EditableTextFieldState();
}

class _EditableTextFieldState extends State<EditableTextField> {
  bool isEditing = false;
  late TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.value);
  }

  @override
  void didUpdateWidget(covariant EditableTextField oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.value != widget.value) {
      _controller.text = widget.value;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    final int resolvedMinLines = widget.minLines ?? 1;
    final int resolvedMaxLines = widget.maxLines ?? 1;

    final bool showPlaceholder =
        !isEditing && _controller.text.trim().isEmpty && (widget.hint?.isNotEmpty ?? false);

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: (isEditing && !widget.readOnly)
              ? TextField(
                  controller: _controller,
                  autofocus: true,
                  minLines: resolvedMinLines,
                  maxLines: resolvedMaxLines,
                  decoration: InputDecoration(
                    isDense: true,
                    border: const OutlineInputBorder(),
                    hintText: widget.hint,
                  ),
                )
              : GestureDetector(
                  onTap: widget.onTap,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 10.0),
                    child: showPlaceholder
                        ? Text(
                            widget.hint!,
                            style: GoogleFonts.poppins(
                              color: theme.hintColor.withOpacity(0.6),
                              fontStyle: FontStyle.italic,
                              fontSize: 16,
                            ),
                          )
                        : Text(
                            _controller.text,
                            style: GoogleFonts.poppins(
                              color: theme.hintColor,
                              fontSize: 16,
                            ),
                          ),
                  ),
                ),
        ),
        if (!widget.readOnly)
          IconButton(
            icon: Icon(
              isEditing ? Icons.check : Icons.edit,
              color: theme.hintColor,
            ),
            onPressed: () {
              if (isEditing && widget.onSave != null) {
                widget.onSave!(_controller.text);
              }
              setState(() => isEditing = !isEditing);
            },
          ),
      ],
    );
  }
}
