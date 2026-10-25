import 'package:flutter/material.dart';
import 'package:Marketing_Fruit/components/all_widgets.dart';
import 'package:Marketing_Fruit/components/auth_service.dart';

class VerifyEmailFlow extends StatefulWidget {
  final String userKey;
  final int age;
  final String role;
  final void Function({
  required String userKey,
  required int age,
  required String role,
  required String email,
  })? onNext;

  const VerifyEmailFlow({
    super.key,
    required this.userKey,
    required this.age,
    required this.role,
    this.onNext,
  });

  @override
  State<VerifyEmailFlow> createState() => _VerifyEmailFlowState();
}

class _VerifyEmailFlowState extends State<VerifyEmailFlow> {
  final PageController _pageController = PageController();
  final authService = AuthService();

  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final TextEditingController confirmPasswordController = TextEditingController();

  bool _isEmailEmpty = false;
  bool _isPasswordEmpty = false;
  bool _isConfirmPasswordEmpty = false;
  bool _isHovered = false;

  void _validateAndNext() async {
    setState(() {
      _isEmailEmpty = emailController.text.isEmpty;
      _isPasswordEmpty = passwordController.text.isEmpty;
      _isConfirmPasswordEmpty = confirmPasswordController.text.isEmpty;
    });

    if (_isEmailEmpty || _isPasswordEmpty || _isConfirmPasswordEmpty) return;

    if (passwordController.text.length < 8) {
      _showDialog("Weak Password", "Password must be at least 8 characters.");
      return;
    }

    if (passwordController.text != confirmPasswordController.text) {
      _showDialog("Password Mismatch", "Passwords do not match. Please try again.");
      return;
    }

    await authService.updatePendingUserWithEmail(
      widget.userKey,
      emailController.text.trim(),
      passwordController.text.trim(),
    );

    widget.onNext?.call(
      userKey: widget.userKey,
      age: widget.age,
      role: widget.role,
      email: emailController.text.trim(),
    );
  }

  void _showDialog(String title, String message) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      showDialog(
        context: context,
        builder: (_) => AlertDialog(
          title: Text(title),
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

  @override
  Widget build(BuildContext context) {
    return Form(
                  child: Column(
                    children: [
                      const SizedBox(height: 10),
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
                      AllWidgets.buildTextField(
                        label: "Email",
                        hint: "John@example.com",
                        controller: emailController,
                        isError: _isEmailEmpty,
                      ),
                      const SizedBox(height: 15),
                      AllWidgets.buildTextField(
                        label: "Password",
                        hint: "Must be at least 8 characters",
                        controller: passwordController,
                        isPassword: true,
                        isError: _isPasswordEmpty,
                      ),
                      const SizedBox(height: 15),
                      AllWidgets.buildTextField(
                        label: "Confirm Password",
                        hint: "Must be at least 8 characters",
                        controller: confirmPasswordController,
                        isPassword: true,
                        isError: _isConfirmPasswordEmpty,
                      ),
                      const SizedBox(height: 20),
                      AllWidgets.buildLoginButton(
                        isHovered: _isHovered,
                        onHoverEnter: () => setState(() => _isHovered = true),
                        onHoverExit: () => setState(() => _isHovered = false),
                        text: "Verify Email",
                        onPressed: _validateAndNext,
                      ),
                    ],
                  ),
    );
  }
}
