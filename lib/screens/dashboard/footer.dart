import 'package:flutter/material.dart';

class Footer extends StatelessWidget {
  const Footer({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 40,
      color: Colors.grey[300],
      alignment: Alignment.center,
      child: const Text("© 2025 Your Company"),
    );
  }
}
