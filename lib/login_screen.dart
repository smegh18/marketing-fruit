import 'dart:ui';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:Marketing_Fruit/registration_screen.dart';
import 'package:Marketing_Fruit/screens/dashboard/main_layout.dart';
import 'package:Marketing_Fruit/screens/dashboard/main_layout_mobile.dart';
import 'package:Marketing_Fruit/success_screen.dart';
import 'package:Marketing_Fruit/verify_email_screen.dart';
import 'package:Marketing_Fruit/failure_screen.dart';
import 'package:Marketing_Fruit/otp_screen.dart';
import 'package:Marketing_Fruit/guardian_email.dart';
import 'components/all_widgets.dart';
import 'components/loginform.dart';
import 'confirm_screen.dart';



class GlassRoleSelector extends StatelessWidget {
  final List<String> roles;
  final List<IconData> roleIcons;
  final int selectedIndex;
  final ValueChanged<int> onChanged;

  // Optionally allow glass parameters to be overridden
  final double blurSigma;
  final double borderRadius;
  final Color backgroundColor;
  final Color borderColor;

  const GlassRoleSelector({
    required this.roles,
    required this.roleIcons,
    required this.selectedIndex,
    required this.onChanged,
    this.blurSigma = 5,
    this.borderRadius = 32,
    this.backgroundColor = const Color(0xFF888888),
    this.borderColor = const Color(0xFF888888),
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final double width = MediaQuery.of(context).size.width * 0.98;

    return Center(
      child: ClipRRect(
        borderRadius: BorderRadius.circular(borderRadius),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: blurSigma, sigmaY: blurSigma),
          child: Container(
            height: 100,
            width: width,
            margin: const EdgeInsets.only(top: 16, bottom: 32),
            padding: const EdgeInsets.symmetric(horizontal: 8), // Small inner padding
            decoration: BoxDecoration(
              color: backgroundColor.withOpacity(0.2),
              borderRadius: BorderRadius.circular(borderRadius),
              border: Border.all(
                color: borderColor.withOpacity(0.5),
                width: 3,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black26,
                  blurRadius: 10,
                  offset: Offset(0, 6),
                ),
              ],
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: List.generate(roles.length, (index) {
                final selected = selectedIndex == index;
                return GestureDetector(
                  onTap: () => onChanged(index),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 180),
                    curve: Curves.easeInOut,
                    height: selected ? 82 : 70,
                    width: selected ? 82 : 70,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: selected
                          ? LinearGradient(
                        colors: [
                          Colors.blue.withOpacity(0.6),
                          Colors.cyan.withOpacity(0.6)
                        ],
                      )
                          : null,
                      color: selected ? null : Colors.white.withOpacity(0.22),
                      border: Border.all(
                        color: selected ? Colors.blueAccent : Colors.white38,
                        width: selected ? 3 : 1,
                      ),
                      boxShadow: selected
                          ? [
                        BoxShadow(
                          color: Colors.blueAccent.withOpacity(0.3),
                          blurRadius: 12,
                          offset: Offset(0, 3),
                        ),
                      ]
                          : [],
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          roleIcons[index],
                          size: selected ? 38 : 30,
                          color: selected ? Colors.white : Colors.white70,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          roles[index],
                          style: TextStyle(
                            fontSize: selected ? 14 : 12,
                            color: selected ? Colors.white : Colors.white70,
                            fontWeight: selected ? FontWeight.bold : FontWeight.w400,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }),
            ),
          ),
        ),
      ),
    );
  }
}


class LoginScreen extends StatefulWidget {
  final String? initialRole;
  final bool goToRegister;
  final bool showConfirm;
  const LoginScreen({
    super.key,
    this.initialRole,
    this.goToRegister = false,
    this.showConfirm = false,
  });
  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final PageController _controller = PageController();
  int _currentIndex = 0;

  final List<String> roles = ["Student", "Brand", "School", "Guardian"];
  final List<IconData> roleIcons = [
    Icons.school_rounded,
    Icons.store_rounded,
    Icons.corporate_fare_rounded,
    Icons.shield_rounded,
  ];

  int selectedRoleIndex = 0;
  String get selectedRole => roles[selectedRoleIndex];
  String userKey = "";
  int age = 0;
  String email = "";
  String sms = "";
  bool isLoadingUser = true;

  @override
  void initState() {
    super.initState();
    if (widget.initialRole != null) {
      final idx = roles.indexOf(widget.initialRole!);
      if (idx != -1) selectedRoleIndex = idx;
    }
    if (widget.goToRegister) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        goToPage(1); // go to registration
      });
    }
    if (widget.showConfirm) {
      sms = "Guardian Verified Successfully! Login Or Register to Access Guardian Dashbaord";
      WidgetsBinding.instance.addPostFrameCallback((_) {
        goToPage(7); // ConfirmFlow screen
      });
    }
    fetchUser();
  }

  Future<void> fetchUser() async {
    setState(() {
      isLoadingUser = true;
    });

    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid != null) {
      try {
        final ref = FirebaseDatabase.instance.ref('users/$uid');
        final snapshot = await ref.get();
        if (!mounted) return;
        final dbRole = snapshot.child("role").value?.toString() ?? 'Student';
        await FirebaseDatabase.instance.ref('users/$uid/last_login').set(ServerValue.timestamp);
        if (!mounted) return;

        setState(() {
          isLoadingUser = false;
        });

        if (kIsWeb) {
          Navigator.of(context, rootNavigator: true).push(
            MaterialPageRoute(builder: (_) => MainLayout(userRole: dbRole)),
          );
        } else {
          Navigator.of(context, rootNavigator: true).push(
            MaterialPageRoute(builder: (_) => MainLayoutMobile(userRole: dbRole)),
          );
        }
      } catch (e) {
        debugPrint('fetchUser error: $e');
        if (!mounted) return;
        setState(() {
          isLoadingUser = false;
        });
      }
    } else {
      setState(() {
        isLoadingUser = false;
      });
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void goToPage(int index) {
    setState(() => _currentIndex = index);
    _controller.animateToPage(
      index,
      duration: const Duration(milliseconds: 400),
      curve: Curves.easeInOut,
    );
  }

  void handleRoleChange(int index) {
    setState(() {
      selectedRoleIndex = index;
    });
  }

  void handleSwitchToRegister(String role) {
    setState(() {
      selectedRoleIndex = roles.indexOf(role);
    });
    goToPage(1);
  }

  void handleRegistrationNext(String uKey, int userAge) {
    setState(() {
      userKey = uKey;
      age = userAge;
    });
    goToPage(2);
  }

  void handleVerifyEmailNext({
    required String userKey,
    required int age,
    required String role,
    required String email,
  }) {
    setState(() {
      this.userKey = userKey;
      this.age = age;
      selectedRoleIndex = roles.indexOf(role);
      this.email = email;
    });
    goToPage(3); // OTP page
  }

  void goToSuccess() => goToPage(4);
  void goToFailure() => goToPage(5);

  void handleSuccessNext() {
    if (selectedRole == "Student" && age <= 18) {
      goToPage(6); // Guardian Email Page
    } else {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        Navigator.of(context, rootNavigator: true).push(
          MaterialPageRoute(
            builder: (_) => MainLayout(userRole: selectedRole),
          ),
        );
      });
    }
  }

  void handleGuardianConfirmation() {
    goToPage(7); // ConfirmFlow screen
  }

  void handleConfirmFinish() {
    goToPage(0);
  }

  bool get isMobile {
    final shortestSide = MediaQuery.of(context).size.shortestSide;
    return !kIsWeb && shortestSide < 600;
  }

  Widget _showGifLoader(BuildContext context) {
        return Container(
          color: Color(0xFFF5F4F4),
          child: Center(
            child: Image.asset(
              'assets/preloader.gif', // Make sure this path matches your asset location
              width: 320,
              height: 320,
              fit: BoxFit.contain,
            ),
          ),
        );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: false,
      body: Stack(
        fit: StackFit.expand,
        children: [
          AllWidgets.buildBackground(),
          if (isLoadingUser) ...[
             _showGifLoader(context)
          ]
          else
          // Main frosted glass container
            Center(
              child: AllWidgets.buildFrostedGlassContainer(
                height: 600,
                width: 500,
                child: PageView(
                  controller: _controller,
                  physics: const NeverScrollableScrollPhysics(),
                  children: [
                    // 0. Login Form
                    LoginForm(
                      scaleFactor: 1.0,
                      selectedIndex: selectedRoleIndex,
                      roles: roles,
                      roleIcons: roleIcons,
                      onRoleChanged: handleRoleChange,
                      onSwitchToRegister: handleSwitchToRegister,
                    ),
                    RegistrationForm(
                      role: selectedRole,
                      onBackToLogin: () => goToPage(0),
                      onNext: handleRegistrationNext,
                    ),
                    VerifyEmailFlow(
                      userKey: userKey,
                      age: age,
                      role: selectedRole,
                      onNext: handleVerifyEmailNext,
                    ),
                    OTPFlow(
                      age: age,
                      email: email,
                      userKey: userKey,
                      role: selectedRole,
                      onSuccess: goToSuccess,
                      onFailure: goToFailure,
                    ),
                    SuccessFlow(
                      age: age,
                      role: selectedRole,
                      onNext: handleSuccessNext,
                    ),
                    OtpFailureFlow(
                      age: age,
                      email: email,
                      userKey: userKey,
                      role: selectedRole,
                      onResend: () => goToPage(3),
                    ),
                    GuardianEmailFlow(
                      userId: userKey, onNext: handleGuardianConfirmation,
                    ),
                    ConfirmFlow(
                      sms: sms,
                      onFinish: handleConfirmFinish,
                    ),
                  ],
                ),
              ),
            ),
          // OUTSIDE the frosted glass: Mobile glass role selector
          if (!isLoadingUser && isMobile)
            Positioned(
              left: 0,
              right: 0,
              bottom: 16,
              child: GlassRoleSelector(
                roles: roles,
                roleIcons: roleIcons,
                selectedIndex: selectedRoleIndex,
                onChanged: handleRoleChange,
              ),
            ),
        ],
      ),
    );
  }
}
