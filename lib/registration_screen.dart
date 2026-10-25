import 'dart:convert';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:geocoding/geocoding.dart';
import 'package:intl/intl.dart';
import 'package:http/http.dart' as http;
import 'package:Marketing_Fruit/components/auth_service.dart';
import 'package:Marketing_Fruit/components/all_widgets.dart';
import 'package:Marketing_Fruit/components/orientation_wrapper.dart';
import 'package:Marketing_Fruit/screens/dashboard/main_layout.dart';
import 'package:Marketing_Fruit/screens/dashboard/main_layout_mobile.dart';
import 'package:universal_platform/universal_platform.dart';
import 'components/social_signin.dart';
import 'package:geolocator/geolocator.dart';

class RegistrationForm extends StatefulWidget {
  final String role;
  final VoidCallback onBackToLogin;
  final void Function(String userKey, int age) onNext;

  const RegistrationForm({
    super.key,
    required this.role,
    required this.onBackToLogin,
    required this.onNext,
  });

  @override
  State<RegistrationForm> createState() => _RegistrationFormState();
}

class _RegistrationFormState extends State<RegistrationForm> {
  final _formKey = GlobalKey<FormState>();
  final authService = AuthService();

  bool _isHovered = false;
  String newUserKey = "";

  final TextEditingController firstNameController = TextEditingController();
  final TextEditingController lastNameController = TextEditingController();
  final TextEditingController schoolController = TextEditingController();
  final TextEditingController dobController = TextEditingController();
  final TextEditingController positionController = TextEditingController();
  final TextEditingController locationController = TextEditingController();

  String? selectedGender;
  String? selectedBrandType;

  final List<String> brandTypes = ['Corporation', 'Sole Proprietorship', 'Non Profit'];

  bool _isFirstNameEmpty = false;
  bool _isLastNameEmpty = false;
  bool _isGenderEmpty = false;
  bool _isDOBEmpty = false;
  bool _isSchoolEmpty = false;
  bool _isPositionEmpty = false;
  bool _isLocationEmpty = false;
  bool _isBrandTypeEmpty = false;

  List<String> locationSuggestions = [];
  bool isSchoolStep = true;

  Position? studentDeviceLocation;


  Future<bool> _fetchStudentLocation() async {
    try {
      if (kIsWeb) {
        // On web, permission is handled by the browser
        studentDeviceLocation = await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.bestForNavigation);
      } else {
        bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
        if (!serviceEnabled) {
          _showErrorDialog("Location services are disabled on your device.");
          return false;
        }

        LocationPermission permission = await Geolocator.checkPermission();
        if (permission == LocationPermission.denied) {
          permission = await Geolocator.requestPermission();
          if (permission == LocationPermission.denied) {
            _showErrorDialog("Location permission is required to continue.");
            return false;
          }
        }

        if (permission == LocationPermission.deniedForever) {
          _showErrorDialog("Location permission permanently denied. Enable it in settings.");
          return false;
        }

        studentDeviceLocation = await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.bestForNavigation);
      }

      return studentDeviceLocation != null;
    } catch (e) {
      _showErrorDialog("Unable to fetch location. Please try again.");
      return false;
    }
  }


  Future<void> fetchLocationSuggestions(String input) async {
    if (input.trim().length < 3) return;

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
        }
      }
    } catch (e) {
      print("Location fetch error: $e");
    }
  }

  int _calculateAge(DateTime birthDate) {
    DateTime today = DateTime.now();
    int age = today.year - birthDate.year;
    if (today.month < birthDate.month ||
        (today.month == birthDate.month && today.day < birthDate.day)) {
      age--;
    }
    return age;
  }

  void _showErrorDialog(String message) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      showDialog(
        context: context,
        builder: (_) => AlertDialog(
          title: const Text("Input Error"),
          content: Text(message),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("OK"),
            ),
          ],
        ),
      );
    });
  }

  void _validateFields() {
    setState(() {
      _isFirstNameEmpty = firstNameController.text.isEmpty;
      _isLastNameEmpty = lastNameController.text.isEmpty;
      _isGenderEmpty = selectedGender == null;
      _isDOBEmpty = dobController.text.isEmpty;
      _isPositionEmpty = positionController.text.isEmpty;
      _isSchoolEmpty = schoolController.text.isEmpty;
      _isLocationEmpty = locationController.text.isEmpty;
      _isBrandTypeEmpty = selectedBrandType == null;
    });
  }

  Future<String> _saveToFirebase() async {
    Map<String, dynamic> data = {};


    switch (widget.role) {
      case 'Student':
        data = {
          "first_name": firstNameController.text,
          "last_name": lastNameController.text,
          "gender": selectedGender,
          "dob": dobController.text,
          "school": schoolController.text,
          if (studentDeviceLocation != null)
            "location": {
              "latitude": studentDeviceLocation!.latitude,
              "longitude": studentDeviceLocation!.longitude,
            },
        };
        break;

      case 'Guardian':
        data = {
          "first_name": firstNameController.text,
          "last_name": lastNameController.text,
          "gender": selectedGender,
          "dob": dobController.text,
        };
        break;
      case 'School':
        data = {
          "school": schoolController.text,
          "location": locationController.text,
          "first_name": firstNameController.text,
          "last_name": lastNameController.text,
          "gender": selectedGender,
          "dob": dobController.text,
          "position": positionController.text,
        };
        break;
      case 'Brand':
        data = {
          "brand_name": schoolController.text,
          "location": locationController.text,
          "brand_type": selectedBrandType,
          "first_name": firstNameController.text,
          "last_name": lastNameController.text,
          "gender": selectedGender,
          "dob": dobController.text,
          "position": positionController.text,
        };
        break;
    }

    return await authService.saveUserBasicInfo(newUserKey, data, widget.role);
  }




  Future<void> _handleNext() async {
    _validateFields();

    if ((widget.role == 'School' || widget.role == 'Brand') && isSchoolStep) {
      if (_isSchoolEmpty || _isLocationEmpty || (widget.role == 'Brand' && _isBrandTypeEmpty)) return;
      setState(() => isSchoolStep = false);
      return;
    }

    if (widget.role == 'Guardian') {
      try {
        DateTime dob = DateFormat("M/d/yyyy").parse(dobController.text.trim());
        if (_calculateAge(dob) < 18) {
          _showErrorDialog("Guardians must be at least 18 years old.");
          return;
        }
      } catch (_) {
        _showErrorDialog("Enter a valid Date of Birth (e.g., MM/DD/YYYY).");
        return;
      }
    }

    if ((widget.role == 'Student' && (_isFirstNameEmpty || _isLastNameEmpty || _isGenderEmpty || _isDOBEmpty || _isSchoolEmpty)) ||
        (widget.role == 'Guardian' && (_isFirstNameEmpty || _isLastNameEmpty || _isGenderEmpty || _isDOBEmpty)) ||
        ((widget.role == 'School' || widget.role == 'Brand') && (!_isFirstNameEmpty || !_isLastNameEmpty || !_isGenderEmpty || !_isDOBEmpty || !_isPositionEmpty))) {
      // Valid for all paths
    }

    if (widget.role == 'Student') {
      bool locationFetched = await _fetchStudentLocation();
      if (!locationFetched) return;
    }

    newUserKey = await _saveToFirebase();


    int age = 100;
    try {
      DateTime parsedDOB = DateFormat("M/d/yyyy").parse(dobController.text);
      age = _calculateAge(parsedDOB);
    } catch (_) {}

    widget.onNext(newUserKey, age);
  }

  @override
  Widget build(BuildContext context) {
    return Form(
      key: _formKey,
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              "Signup and Get Access To Simulator",
              style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold, color: Colors.white),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            if ((widget.role == 'School' || widget.role == 'Brand') && isSchoolStep) ...[
              AllWidgets.buildTextField(
                label: widget.role == 'Brand' ? "Brand Name" : "School Name",
                controller: schoolController,
                hint: "Enter ${widget.role == 'Brand' ? "Brand" : "School"} Name",
                isError: _isSchoolEmpty,
              ),
              const SizedBox(height: 15),
              TextField(
                controller: locationController,
                onChanged: fetchLocationSuggestions,
                decoration: InputDecoration(
                  labelText: "Location",
                  errorText: _isLocationEmpty ? "Required" : null,
                  filled: true,
                  fillColor: Colors.white,
                ),
              ),
              for (var suggestion in locationSuggestions.take(5))
                ListTile(
                  title: Text(suggestion),
                  onTap: () {
                    setState(() {
                      locationController.text = suggestion;
                      locationSuggestions = [];
                    });
                  },
                ),
              if (widget.role == 'Brand') ...[
                const SizedBox(height: 15),
                DropdownButtonFormField<String>(
                  value: selectedBrandType,
                  items: brandTypes.map((type) {
                    return DropdownMenuItem(value: type, child: Text(type));
                  }).toList(),
                  onChanged: (val) => setState(() => selectedBrandType = val),
                  decoration: const InputDecoration(labelText: "Type"),
                ),
              ],
            ] else ...[
              Row(
                children: [
                  Expanded(
                    child: AllWidgets.buildTextField(
                      label: "First Name",
                      controller: firstNameController,
                      hint: "Enter First Name",
                      isError: _isFirstNameEmpty,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: AllWidgets.buildTextField(
                      label: "Last Name",
                      controller: lastNameController,
                      hint: "Enter Last Name",
                      isError: _isLastNameEmpty,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 15),
              Row(
                children: [
                  Expanded(
                    child: AllWidgets.buildGenderDropdown(
                      selectedGender: selectedGender,
                      onChanged: (val) => setState(() => selectedGender = val),
                      showError: _isGenderEmpty,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: AllWidgets.buildDatePicker(
                      context: context,
                      dobController: dobController,
                      showError: _isDOBEmpty,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 15),
              if (widget.role == 'Student') ...[
                AllWidgets.buildTextField(
                  label: "School",
                  controller: schoolController,
                  hint: "Enter School Name",
                  isError: _isSchoolEmpty,
                ),
                const SizedBox(height: 15),
              ],
              if (widget.role == 'School' || widget.role == 'Brand') ...[
                AllWidgets.buildTextField(
                  label: "Position",
                  controller: positionController,
                  hint: "e.g. Principal / Coordinator",
                  isError: _isPositionEmpty,
                ),
              ],
            ],
            const SizedBox(height: 20),
            AllWidgets.buildLoginButton(
              text: "Next",
              isHovered: _isHovered,
              onHoverEnter: () => setState(() => _isHovered = true),
              onHoverExit: () => setState(() => _isHovered = false),
              onPressed: _handleNext,
            ),
            const SizedBox(height: 20),
            const Text("or continue with", style: TextStyle(color: Colors.white, fontSize: 16)),
            const SizedBox(height: 10),
            AllWidgets.buildSocialButtons(
              onGoogleTap: () async {
                bool success = await signInWithGoogle(widget.role);
                if (success) {
                  final uid = FirebaseAuth.instance.currentUser?.uid;
                  await FirebaseDatabase.instance.ref('users/$uid/last_login').set(ServerValue.timestamp);
                  if(AuthService().isNewUser()){
                    WidgetsBinding.instance.addPostFrameCallback((_) {
                      Navigator.of(context, rootNavigator: true).push(
                        MaterialPageRoute(
                          builder: (_) => kIsWeb
                            ? MainLayout(userRole: widget.role, nftindex: 8)
                            : MainLayoutMobile(userRole: widget.role),
                        ),
                      );
                    });
                  } else {
                    WidgetsBinding.instance.addPostFrameCallback((_) {
                      Navigator.of(context, rootNavigator: true).push(
                        MaterialPageRoute(
                          builder: (_) => kIsWeb
                            ? MainLayout(userRole: widget.role)
                            : MainLayoutMobile(userRole: widget.role),
                        ),
                      );
                    });
                  }

                }
              },
              onFacebookTap: () async {
                bool success = await signInWithFacebook(widget.role);
                if (success) {
                  final uid = FirebaseAuth.instance.currentUser?.uid;
                  await FirebaseDatabase.instance.ref('users/$uid/last_login').set(ServerValue.timestamp);
                  if(AuthService().isNewUser()){
                    WidgetsBinding.instance.addPostFrameCallback((_) {
                      Navigator.of(context, rootNavigator: true).push(
                        MaterialPageRoute(
                          builder: (_) => kIsWeb
                            ? MainLayout(userRole: widget.role, nftindex: 8)
                            : MainLayoutMobile(userRole: widget.role),
                        ),
                      );
                    });
                  } else {
                    WidgetsBinding.instance.addPostFrameCallback((_) {
                      Navigator.of(context, rootNavigator: true).push(
                        MaterialPageRoute(
                          builder: (_) => kIsWeb
                            ? MainLayout(userRole: widget.role)
                            : MainLayoutMobile(userRole: widget.role),
                        ),
                      );
                    });
                  }
                }
              },
            ),
            const SizedBox(height: 20),
            GestureDetector(
              onTap: widget.onBackToLogin,
              child: const Text(
                "Back to Login",
                style: TextStyle(color: Colors.white, decoration: TextDecoration.underline, fontSize: 16),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class LocationService {
  Future<bool> _handlePermission() async {
    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied || permission == LocationPermission.deniedForever) {
      permission = await Geolocator.requestPermission();
    }
    return permission == LocationPermission.always || permission == LocationPermission.whileInUse;
  }

  Future<Map<String, dynamic>?> getLocationAndAddress() async {
    if (!UniversalPlatform.isWeb) {
      bool granted = await _handlePermission();
      if (!granted) return null;
    }

    try {
      Position position = await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.bestForNavigation);
      List<Placemark> placemarks = await placemarkFromCoordinates(position.latitude, position.longitude);
      Placemark place = placemarks.first;

      return {
        'latitude': position.latitude,
        'longitude': position.longitude,
        'country': place.country ?? '',
        'state': place.administrativeArea ?? ''
      };
    } catch (e) {
      print("Location error: $e");
      return null;
    }
  }
}
