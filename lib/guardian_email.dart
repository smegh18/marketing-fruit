import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:Marketing_Fruit/components/all_widgets.dart';

import 'components/auth_service.dart';

class GuardianEmailFlow extends StatefulWidget {
  final String userId;
  final void Function() onNext;

  const GuardianEmailFlow({
    super.key,
    required this.userId,
    required this.onNext,
  });

  @override
  State<GuardianEmailFlow> createState() => _GuardianEmailFlowState();
}

class _GuardianEmailFlowState extends State<GuardianEmailFlow> {
  final TextEditingController emailController = TextEditingController();
  bool isHovered = false;
  bool isChecked = false;
  bool isEmailEmpty = false;
  final authService = AuthService();
  final userID = FirebaseAuth.instance.currentUser!.uid;

  Future<void> sendGuardianEmail() async {
    try {
      final HttpsCallable callable =
      FirebaseFunctions.instance.httpsCallable('sendGuardianVerificationEmail');
      await callable.call({
        'guardianEmail': emailController.text.trim(),
        'childId': userID,
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Verification email sent!')),
      );

      authService.updateUserWithGuardianEmail(userID, emailController.text.trim());

      widget.onNext(); // Proceed in flow
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to send: $e')),
      );
    }
  }

  void _validateAndSend() {
    setState(() => isEmailEmpty = emailController.text.isEmpty);
    if (!isEmailEmpty && isChecked) {
      sendGuardianEmail();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const Text(
          "Signup and Get Access To Simulator",
          style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold, color: Colors.white),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 8),
        Container(width: 400, height: 5, color: Colors.white),
        const SizedBox(height: 20),
        AllWidgets.buildTextField(
          label: "Guardian Email ID",
          hint: "Guardian Email ID",
          controller: emailController,
          isError: isEmailEmpty,
        ),
        const SizedBox(height: 15),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            GestureDetector(
              onTap: () => setState(() => isChecked = !isChecked),
              child: Container(
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  border: Border.all(width: 2, color: Colors.white),
                  borderRadius: BorderRadius.circular(5),
                ),
                child: isChecked
                    ? const Icon(Icons.check, size: 20, color: Colors.white)
                    : null,
              ),
            ),
            const SizedBox(width: 10),
            const Text(
              'Accept Terms and Conditions',
              style: TextStyle(color: Colors.white),
            ),
          ],
        ),
        const SizedBox(height: 20),
        AllWidgets.buildLoginButton(
          isHovered: isHovered,
          onHoverEnter: () => setState(() => isHovered = true),
          onHoverExit: () => setState(() => isHovered = false),
          text: "Send Verification Email",
          onPressed: _validateAndSend,
        ),
      ],
    );
  }
}
