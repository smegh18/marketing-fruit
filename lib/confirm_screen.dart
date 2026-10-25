import 'package:flutter/material.dart';
import 'components/all_widgets.dart';

class ConfirmFlow extends StatefulWidget {
  final String sms;
  final VoidCallback onFinish;

  const ConfirmFlow({super.key, required this.sms, required this.onFinish});

  @override
  State<ConfirmFlow> createState() => _ConfirmFlowState();
}

class _ConfirmFlowState extends State<ConfirmFlow> {
  bool isHovering = false;
  late String message;

  @override
  void initState() {
    super.initState();
    message = widget.sms.isNotEmpty
        ? widget.sms
        : "We have sent a confirmation request to your guardian. You will be able to access the platform once they approve.";
  }

  @override
  Widget build(BuildContext context) {
    return Column(
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
        const SizedBox(height: 50),
        Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Image.asset("assets/confirm_logo.png", width: 200, height: 200),
            const SizedBox(height: 50),
            Text(
              message,
              style: const TextStyle(fontSize: 24, color: Colors.white),
              textAlign: TextAlign.justify,
              softWrap: true,
            ),
          ],
        ),
        const SizedBox(height: 30),
        AllWidgets.buildLoginButton(
          text: "Done",
          isHovered: isHovering,
          onHoverEnter: () => setState(() => isHovering = true),
          onHoverExit: () => setState(() => isHovering = false),
          onPressed: widget.onFinish,
        ),
      ],
    );
  }
}
