import 'dart:ui';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../screens/dashboard/main_layout.dart';
import '../screens/dashboard/main_layout_mobile.dart';
import '../login_screen.dart';

class EntertainmentMenuDrawer extends StatefulWidget {
  const EntertainmentMenuDrawer({super.key});

  @override
  State<EntertainmentMenuDrawer> createState() => _EntertainmentMenuDrawerState();
}

class _EntertainmentMenuDrawerState extends State<EntertainmentMenuDrawer>
    with SingleTickerProviderStateMixin {
  bool showMenu = false;
  late AnimationController _controller;
  late Animation<double> _drawerAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _drawerAnimation = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeInOut,
    );
  }

  void toggleMenu() {
    setState(() {
      showMenu = !showMenu;
      showMenu ? _controller.forward() : _controller.reverse();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // Menu Drawer (expanded)
        Positioned(
          top: 20,
          left: 16,
          child: SizeTransition(
            sizeFactor: _drawerAnimation,
            axis: Axis.horizontal,
            axisAlignment: -1.0,
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.lime.shade400.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(50),
                  border: Border.all(
                    color: Colors.white.withOpacity(0.2),
                    width: 1.2,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    GestureDetector(
                      onTap: toggleMenu,
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: const BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.transparent,
                        ),
                        child: const Icon(Icons.menu, color: Colors.black, weight: 40),
                      ),
                    ),
                    const SizedBox(width: 10),
                    TextButton.icon(
                      onPressed: () {
                        // Restore portrait orientation
                        SystemChrome.setPreferredOrientations([
                          DeviceOrientation.portraitUp,
                          DeviceOrientation.portraitDown,
                        ]);
                        // Push a new MainLayout and remove all imperative routes down to the GoRouter root (isFirst)
                        WidgetsBinding.instance.addPostFrameCallback((_) {
                          if (context.mounted) {
                            if (kIsWeb) {
                              Navigator.of(context).pushAndRemoveUntil(
                                MaterialPageRoute(builder: (context) => MainLayout(userRole: 'Student')),
                                (route) => route.isFirst,
                              );
                            } else {
                              Navigator.of(context).pushAndRemoveUntil(
                                MaterialPageRoute(builder: (context) => MainLayoutMobile(userRole: 'Student')),
                                (route) => route.isFirst,
                              );
                            }
                          }
                        });
                      },
                      icon: const Icon(Icons.dashboard_outlined, color: Colors.black, weight: 30),
                      label: const Text("Dashboard", style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
                    ),
                    const SizedBox(width: 10),
                    TextButton.icon(
                      onPressed: () {
                        // Restore portrait orientation
                        SystemChrome.setPreferredOrientations([
                          DeviceOrientation.portraitUp,
                          DeviceOrientation.portraitDown,
                        ]);
                        FirebaseAuth.instance.signOut();
                        // Pop all imperative routes back to the GoRouter root
                        Navigator.of(context).popUntil((route) => route.isFirst);
                      },
                      icon: const Icon(Icons.logout, color: Colors.black, weight: 30),
                      label: const Text("LogOut", style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),

        // Menu Icon (collapsed)
        if (!showMenu)
          Positioned(
            top: 20,
            left: 16,
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 0, sigmaY: 0),
              child: GestureDetector(
                onTap: toggleMenu,
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.lime.shade400.withOpacity(0.2),
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: Colors.white.withOpacity(0.2),
                      width: 1.2,
                    ),
                  ),
                  child: const Icon(Icons.menu, color: Colors.black),
                ),
              ),
            ),
          ),
      ],
    );
  }
}
