import 'package:flutter/material.dart';
import 'package:Marketing_Fruit/components/all_widgets.dart';

class SuccessFlow extends StatefulWidget {
  final int age;
  final String role;
  final VoidCallback onNext;

  const SuccessFlow({
    super.key,
    required this.age,
    required this.role,
    required this.onNext,
  });

  @override
  State<SuccessFlow> createState() => _SuccessFlowState();
}

class _SuccessFlowState extends State<SuccessFlow> {
  bool isHovering = false;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
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
        Container(width: 400, height: 5, color: Colors.white),
        const SizedBox(height: 20),

        Column(
          children: [
            Image.asset(
              "assets/success_logo.png",
              width: 100,
              height: 100,
            ),
            const SizedBox(height: 10),
            const Text(
              "Your Email has been Verified Securely",
              style: TextStyle(fontSize: 24, color: Colors.white),
              textAlign: TextAlign.center,
            ),
          ],
        ),
        const SizedBox(height: 30),

        AllWidgets.buildLoginButton(
          text: "Next",
          isHovered: isHovering,
          onHoverEnter: () => setState(() => isHovering = true),
          onHoverExit: () => setState(() => isHovering = false),
          onPressed: widget.onNext,
        ),
      ],
    );
  }
}
