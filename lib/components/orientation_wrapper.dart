import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class OrientationWrapper extends StatefulWidget {
  final List<DeviceOrientation> orientations;
  final Widget child;

  const OrientationWrapper({
    super.key,
    required this.orientations,
    required this.child,
  });

  @override
  State<OrientationWrapper> createState() => _OrientationWrapperState();
}

class _OrientationWrapperState extends State<OrientationWrapper> {
  @override
  void initState() {
    super.initState();
    SystemChrome.setPreferredOrientations(widget.orientations);
  }

  @override
  void dispose() {
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
    ]);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return widget.child;
  }
}
