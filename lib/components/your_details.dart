import 'package:flutter/material.dart';

class YourDetailsSection extends StatefulWidget {
  final String userName;
  final String schoolName;
  final String contact;
  final String email;
  final void Function(Map<String, dynamic> details)? onSubmitDetails;
  final VoidCallback? onRegisterClicked; // For parent confirmation async logic

  const YourDetailsSection({
    super.key,
    required this.userName,
    required this.schoolName,
    required this.contact,
    required this.email,
    this.onSubmitDetails,
    this.onRegisterClicked,
  });

  @override
  State<YourDetailsSection> createState() => _YourDetailsSectionState();
}

class _YourDetailsSectionState extends State<YourDetailsSection> {
  bool isEditing = false;

  late TextEditingController _userNameController;
  late TextEditingController _schoolNameController;
  late TextEditingController _contactController;
  late TextEditingController _emailController;

  @override
  void initState() {
    super.initState();
    // ignore: prefer_initializing_formals
    _userNameController = TextEditingController(text: widget.userName);
    _schoolNameController = TextEditingController(text: widget.schoolName);
    _contactController = TextEditingController(text: widget.contact);
    _emailController = TextEditingController(text: widget.email);
  }

  void _toggleEdit() {
    setState(() {
      // Optionally could auto-save here
      isEditing = !isEditing;
    });
  }

  void _submitDetails() {
    if (widget.onSubmitDetails != null) {
      widget.onSubmitDetails!(
          {
            'userName': _userNameController.text,
            'schoolName': _schoolNameController.text,
            'contact': _contactController.text,
            'email': _emailController.text,
          }
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black12,
              blurRadius: 8,
              spreadRadius: 2,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Your Details',
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _userNameController,
              readOnly: !isEditing,
              decoration: InputDecoration(
                labelText: 'User Name',
                border: const OutlineInputBorder(),
                filled: isEditing,
                fillColor: isEditing ? Colors.yellow.shade100 : Colors.transparent,
              ),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _schoolNameController,
              readOnly: !isEditing,
              decoration: InputDecoration(
                labelText: 'School Name',
                border: const OutlineInputBorder(),
                filled: isEditing,
                fillColor: isEditing ? Colors.yellow.shade100 : Colors.transparent,
              ),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _contactController,
              readOnly: !isEditing,
              keyboardType: TextInputType.phone,
              decoration: InputDecoration(
                labelText: 'Contact Details',
                border: const OutlineInputBorder(),
                filled: isEditing,
                fillColor: isEditing ? Colors.yellow.shade100 : Colors.transparent,
              ),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _emailController,
              readOnly: !isEditing,
              keyboardType: TextInputType.emailAddress,
              decoration: InputDecoration(
                labelText: 'Email ID',
                border: const OutlineInputBorder(),
                filled: isEditing,
                fillColor: isEditing ? Colors.yellow.shade100 : Colors.transparent,
              ),
            ),
            const SizedBox(height: 16),
            Align(
              alignment: Alignment.centerRight,
              child: ElevatedButton.icon(
                onPressed: _toggleEdit,
                icon: Icon(isEditing ? Icons.save : Icons.edit),
                label: Text(isEditing ? 'Save' : 'Edit'),
              ),
            ),
            const SizedBox(height: 32),
            Center(
              child: ElevatedButton(
                onPressed: () {
                  _submitDetails();
                  if (widget.onRegisterClicked != null) {
                    widget.onRegisterClicked!();
                  }
                },
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                ),
                child: const Text(
                  'Register for This Event',
                  style: TextStyle(fontSize: 18),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
