import 'package:flutter/material.dart';
import 'components/all_widgets.dart';

class OtpFailureFlow extends StatefulWidget {
  final String userKey;
  final int age;
  final String email;
  final String role;

  final VoidCallback onResend;

  const OtpFailureFlow({
    super.key,
    required this.userKey,
    required this.age,
    required this.email,
    required this.role,
    required this.onResend,
  });

  @override
  State<OtpFailureFlow> createState() => _OtpFailureFlowState();
}

class _OtpFailureFlowState extends State<OtpFailureFlow> {
  final PageController _pageController = PageController();
  bool isHovering = false;

  @override
  Widget build(BuildContext context) {
    return Form(
              child:
                Column(
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
                    Container(width: 400, height: 5, color: Colors.white),
                    const SizedBox(height: 20),
                    Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Stack(
                          clipBehavior: Clip.none,
                          children: [
                            Image.asset("assets/email.png", width: 150, height: 150),
                            Positioned(
                              top: 40,
                              right: -20,
                              child: Image.asset("assets/wrong.png", width: 50, height: 50),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        const Text(
                          "Uh-Ohh! Wrong OTP",
                          style: TextStyle(fontSize: 24, color: Colors.white),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    AllWidgets.buildLoginButton(
                      text: "Resend OTP",
                      isHovered: isHovering,
                      onHoverEnter: () => setState(() => isHovering = true),
                      onHoverExit: () => setState(() => isHovering = false),
                      onPressed: widget.onResend,
                    ),
                    const SizedBox(height: 20),
                  ],
                ),


    );
  }
}
