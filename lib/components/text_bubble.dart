import 'dart:ui';
import 'package:flutter/material.dart';

class TextBubble extends StatelessWidget {
  final String message;
  final double width;
  final EdgeInsets padding;
  final TextStyle? textStyle;

  const TextBubble({
    super.key,
    required this.message,
    this.width = double.infinity,
    this.padding = const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
    this.textStyle,
  });

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;

    final double responsiveFontSize = screenWidth * 0.015; // ~4.5% of width
    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10), // blur effect
        child: Container(
          width: width,
          padding: padding,
          decoration: BoxDecoration(
            color: Colors.lime.shade400.withOpacity(0.2), // semi-transparent
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: Colors.white.withOpacity(0.2),
              width: 1.2,
            ),
          ),
        child: Center(
          child: Stack(
            children: [
              // Outline
              Text(
                message,
                textAlign: TextAlign.center,
                style: TextStyle(
                fontSize: responsiveFontSize,
                fontWeight: FontWeight.bold,
                height: 1.4,
                foreground: Paint()
                  ..style = PaintingStyle.stroke
                  ..strokeWidth = 5
                  ..strokeCap = StrokeCap.butt
                  ..strokeJoin = StrokeJoin.round
                  ..color = Colors.black,
                ),
              ),
              // Fill
              Text(
                message,
                textAlign: TextAlign.center,
                style: TextStyle(
                fontSize: responsiveFontSize,
                fontWeight: FontWeight.bold,
                height: 1.4,
                color: Colors.white,
                ),
              ),
            ],
          ),
        ),
      ),
      ),
    );
  }
}
