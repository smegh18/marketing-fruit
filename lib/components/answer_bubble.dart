import 'dart:ui';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';

class AnswerBubble extends StatefulWidget {
  final String label;
  final VoidCallback? onTap;
  final EdgeInsets padding;
  final TextStyle? textStyle;
  final Color? backgroundColor;
  final bool isDisabled;

  const AnswerBubble({
    super.key,
    required this.label,
    this.onTap,
    this.backgroundColor,
    this.padding = const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
    this.textStyle,
    this.isDisabled = false,
  });

  @override
  State<AnswerBubble> createState() => _AnswerBubbleState();
}

class _AnswerBubbleState extends State<AnswerBubble> {
  double _opacity = 1.0;
  double _scale = 1.0;

  void _handleTap() {
    if (widget.isDisabled) {
      setState(() {
        _opacity = 0.3;
      });
    } else {
      setState(() {
        _scale = 1.0; // Reset to original size on tap
      });
      widget.onTap?.call();
    }
  }

  void _onEnter(PointerEnterEvent event) {
    setState(() {
      _scale = 1.2;
    });
  }

  void _onExit(PointerExitEvent event) {
    setState(() {
      _scale = 1.0;
    });
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final width = screenWidth * 0.2;
    final double responsiveFontSize = screenWidth * 0.015;

    return MouseRegion(
      onEnter: _onEnter,
      onExit: _onExit,
      cursor: SystemMouseCursors.click,
      child: AnimatedScale(
        duration: const Duration(milliseconds: 200),
        scale: _scale,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(30),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
            child: Material(
              color: widget.backgroundColor ?? Colors.lime.shade400.withOpacity(0.25),
              child: InkWell(
                onTap: _handleTap,
                borderRadius: BorderRadius.circular(30),
                child: Container(
                  width: width,
                  padding: widget.padding,
                  decoration: BoxDecoration(
                    border: Border.all(
                      color: Colors.white.withOpacity(0.3),
                      width: 1.2,
                    ),
                  ),
                  child: Center(
                    child: AnimatedOpacity(
                      opacity: _opacity,
                      duration: const Duration(milliseconds: 500),
                      child: Stack(
                        children: [
                          // Outline
                          Text(
                            widget.label,
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
                            widget.label,
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
              ),
            ),
          ),
        ),
      ),
    );
  }
}
