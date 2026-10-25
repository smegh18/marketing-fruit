import 'package:flutter/cupertino.dart';
import 'package:flutter/gestures.dart';

class NextButton extends StatefulWidget {
  final VoidCallback onTap;
  const NextButton({super.key, required this.onTap});

  @override
  State<NextButton> createState() => NextButtonState();
}

class NextButtonState extends State<NextButton> {
  double _scale = 1.0;

  void _onEnter(PointerEnterEvent event) {
    setState(() {
      _scale = 1.5;
    });
  }

  void _onExit(PointerExitEvent event) {
    setState(() {
      _scale = 1.0;
    });
  }

  void _onTap() {
    setState(() {
      _scale = 1.0; // Shrink back to normal on click
    });
    widget.onTap(); // Perform the actual tap action
  }

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;

    return MouseRegion(
      onEnter: _onEnter,
      onExit: _onExit,
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: _onTap,
        child: AnimatedScale(
          duration: Duration(milliseconds: 200),
          scale: _scale,
          child: Image.asset(
            'assets/next_Button.png',
            height: screenHeight * 0.08,
          ),
        ),
      ),
    );
  }
}
