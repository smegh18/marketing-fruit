import 'package:cloud_functions/cloud_functions.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'components/all_widgets.dart';
import 'components/auth_service.dart';

class OTPFlow extends StatefulWidget {
  final int age;
  final String email;
  final String role;
  final String userKey;

  final VoidCallback onSuccess;
  final VoidCallback onFailure;

  const OTPFlow({
    super.key,
    required this.userKey,
    required this.age,
    required this.email,
    required this.role,
    required this.onSuccess,
    required this.onFailure,
  });

  @override
  State<OTPFlow> createState() => _OTPFlowState();
}

class _OTPFlowState extends State<OTPFlow> {
  final List<TextEditingController> _otpControllers =
  List.generate(6, (_) => TextEditingController());
  final List<FocusNode> _focusNodes =
  List.generate(6, (_) => FocusNode());

  bool isHovered = false;
  String generatedOtp = "";
  final authService = AuthService();

  @override
  void initState() {
    super.initState();
    _sendOtpToEmail(widget.email);
  }

  @override
  void dispose() {
    for (final controller in _otpControllers) {
      controller.dispose();
    }
    for (final node in _focusNodes) {
      node.dispose();
    }
    super.dispose();
  }

  Future<void> _sendOtpToEmail(String email) async {
    try {
      final callable = FirebaseFunctions.instance.httpsCallable('sendOtpEmail');
      final result = await callable.call({'email': email});
      print(result);
      generatedOtp = result.data["otp"];
      print("OTP sent: $generatedOtp");
    } catch (e) {
      print("OTP Error: $e");
    }
  }

  void _onOtpChanged(int index, String value) {
    if (value.isNotEmpty && index < 5) {
      FocusScope.of(context).requestFocus(_focusNodes[index + 1]);
    } else if (value.isEmpty && index > 0) {
      FocusScope.of(context).requestFocus(_focusNodes[index - 1]);
    }
  }

  Future<void> _confirmOtp() async {
    final enteredOtp = _otpControllers.map((c) => c.text).join();
    if (enteredOtp == generatedOtp) {
      try {
        final userCredential = await authService.registerWithEmail();
        final uid = userCredential.user!.uid;
        await authService.movePendingToRegistered(uid);
        widget.onSuccess();
      } catch (e) {
        print("Registration failed: $e");
      }
    } else {
      widget.onFailure();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Form(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  "Signup and Get Access To Simulator",
                  style: TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Container(width: 400, height: 7, color: Colors.white),
                const SizedBox(height: 20),
                const Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    "OTP",
                    style: TextStyle(
                      fontSize: 20,
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: List.generate(
                    6,
                        (index) => SizedBox(
                      width: 40,
                      height: 50,
                      child: TextFormField(
                        controller: _otpControllers[index],
                        focusNode: _focusNodes[index],
                        textAlign: TextAlign.center,
                        keyboardType: TextInputType.number,
                        maxLength: 1,
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                        decoration: InputDecoration(
                          counterText: "",
                          filled: true,
                          fillColor: Colors.white,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(5),
                            borderSide: BorderSide.none,
                          ),
                        ),
                        onChanged: (value) => _onOtpChanged(index, value),
                        inputFormatters: [
                          FilteringTextInputFormatter.digitsOnly,
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                AllWidgets.buildLoginButton(
                  isHovered: isHovered,
                  onHoverEnter: () => setState(() => isHovered = true),
                  onHoverExit: () => setState(() => isHovered = false),
                  text: "Confirm OTP",
                  onPressed: _confirmOtp,
                ),
              ],
            ),
    );
  }
}
