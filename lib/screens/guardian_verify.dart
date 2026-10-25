import 'package:flutter/material.dart';
import 'package:cloud_functions/cloud_functions.dart';

class GuardianVerify extends StatefulWidget {
  final String childId;

  const GuardianVerify({super.key, required this.childId});

  @override
  _GuardianVerifyState createState() => _GuardianVerifyState();
}

class _GuardianVerifyState extends State<GuardianVerify> {
  String message = "Verifying...";

  @override
  void initState() {
    super.initState();
    verifyGuardian();
  }

  Future<void> verifyGuardian() async {
    try {
      final callable = FirebaseFunctions.instance.httpsCallable('verifyGuardian');
      final result = await callable.call({'childId': widget.childId});
      if (result.data['success'] == true) {
        setState(() => message = "Guardian successfully verified!");
      } else {
        setState(() => message = "Verification failed.");
      }
    } catch (e) {
      setState(() => message = "Error verifying guardian: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(child: Text(message, style: TextStyle(fontSize: 18))),
    );
  }
}
