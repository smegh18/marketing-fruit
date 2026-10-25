import 'dart:convert';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import 'package:Marketing_Fruit/components/auth_service.dart';
import 'package:Marketing_Fruit/components/orientation_wrapper.dart';
import 'package:Marketing_Fruit/components/all_widgets.dart';
import 'package:Marketing_Fruit/components/social_signin.dart';
import 'package:Marketing_Fruit/screens/dashboard/main_layout.dart';
import 'package:Marketing_Fruit/screens/dashboard/main_layout_mobile.dart';

class LoginForm extends StatefulWidget {
  final double scaleFactor;
  final List<String> roles;
  final List<IconData> roleIcons;
  final int selectedIndex;
  final ValueChanged<int> onRoleChanged;
  final void Function(String selectedRole) onSwitchToRegister;

  const LoginForm({
    super.key,
    required this.scaleFactor,
    required this.roles,
    required this.roleIcons,
    required this.selectedIndex,
    required this.onRoleChanged,
    required this.onSwitchToRegister,
  });

  @override
  State<LoginForm> createState() => _LoginFormState();
}

class _LoginFormState extends State<LoginForm> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  bool _isHovered = false;
  bool _isEmailEmpty = false;
  bool _isPasswordEmpty = false;

  final authService = AuthService();

  void _validateFields() {
    setState(() {
      _isEmailEmpty = _emailController.text.isEmpty;
      _isPasswordEmpty = _passwordController.text.isEmpty;
    });
  }

  static String get wordpressLoginUrl =>
      dotenv.env['WP_LOGIN_URL'] ?? 'https://marketingfruit.net/wp-json/learnpress/v1/token';
  static String get _adminUsername =>
      dotenv.env['WP_ADMIN_USERNAME'] ?? '';
  static String get _adminAppPassword =>
      dotenv.env['WP_ADMIN_APP_PASSWORD'] ?? '';

  String get basicAuthHeader =>
      'Basic ${base64Encode(utf8.encode('$_adminUsername:$_adminAppPassword'))}';

  Future<String?> _loginWordPress(String email, String password) async {
    final response = await http.post(
      Uri.parse(wordpressLoginUrl),
      body: {
        'username': email,
        'password': password,
      },
    );
    final data = json.decode(response.body);
    if (response.statusCode == 200 && data['token'] != null) {
      return data['token'];
    }
    return null;
  }

  Future<bool> registerWordPressUser(
      String username, String email, String password, String name) async {
    final response = await http.post(
      Uri.parse('https://marketingfruit.net/wp-json/wp/v2/users'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': basicAuthHeader,
      },
      body: jsonEncode({
        'username': username,
        'email': email,
        'password': password,
        'name': name,
      }),
    );
    return response.statusCode == 201;
  }

  Future<void> _showGifLoader(BuildContext context) async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) {
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
      },
    );
  }

  Future<void> _handleLogin() async {
    _validateFields();
    if (_isEmailEmpty || _isPasswordEmpty) return;
    await _showGifLoader(context);
    try {
      final user = await authService.loginAndFetchUser(
        _emailController.text,
        _passwordController.text,
      );
      if (!mounted) return;
      final String userId = user.uid;
      final snapshot = await authService.getUserSnapshot(userId);
      if (!mounted) return;
      if (!snapshot.exists) throw Exception("User data not found");
      final dbRole = snapshot.child("role").value.toString();
      if (dbRole != widget.roles[widget.selectedIndex]) {
        Navigator.of(context, rootNavigator: true).pop();
        showDialog(
          context: context,
          builder: (_) => AlertDialog(
            title: const Text("Role Mismatch"),
            content: Text(
                "Selected role (${widget.roles[widget.selectedIndex]}) does not match your registered role ($dbRole)."),
            actions: [
              TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text("OK"))
            ],
          ),
        );
        return;
      }
      final firebaseUser = FirebaseAuth.instance.currentUser;
      final email = firebaseUser?.email ?? "";
      final password = _passwordController.text;
      final name = firebaseUser?.displayName ?? email;
      if (widget.roles[widget.selectedIndex] == 'Student') {
        String? wpToken;
        try {
          wpToken = await _loginWordPress(email, password);
          if (!mounted) return;
          if (wpToken == null && _adminUsername.isNotEmpty) {
            final registered =
            await registerWordPressUser(email, email, password, name);
            if (!mounted) return;
            if (!registered) {
              debugPrint("Failed to register account on WordPress.");
            } else {
              wpToken = await _loginWordPress(email, password);
              if (!mounted) return;
              if (wpToken == null) {
                debugPrint("WordPress login failed after registration.");
              }
            }
          }
        } catch (e) {
          debugPrint("WordPress integration error: $e");
        }
        if (wpToken != null) {
          await FirebaseDatabase.instance
              .ref('users/$userId/wp_token')
              .set(wpToken);
        }
        if (!mounted) return;
      }
      await FirebaseDatabase.instance
          .ref('users/$userId/last_login')
          .set(ServerValue.timestamp);
      if (!mounted) return;
      if (kIsWeb) {
        Navigator.of(context, rootNavigator: true).pop();
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (!mounted) return;
          Navigator.of(context, rootNavigator: true).push(
            MaterialPageRoute(
              builder: (_) =>
                  MainLayout(userRole: widget.roles[widget.selectedIndex]),
            ),
          );
        });
      } else {
        Navigator.of(context, rootNavigator: true).pop();
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (!mounted) return;
          Navigator.of(context, rootNavigator: true).push(
            MaterialPageRoute(
              builder: (_) => MainLayoutMobile(
                  userRole: widget.roles[widget.selectedIndex]),
            ),
          );
        });
      }
    } catch (e) {
      if (!mounted) return;
      Navigator.of(context, rootNavigator: true).pop();
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        showDialog(
          context: context,
          builder: (_) => AlertDialog(
            title: const Text("Login Failed"),
            content: Text(e.toString()),
            actions: [
              TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text("OK"))
            ],
          ),
        );
      });
    }
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isWeb = kIsWeb;
    return SingleChildScrollView(
      child: FocusTraversalGroup(
        policy: OrderedTraversalPolicy(),
        descendantsAreFocusable: true,
        child: Column(
          mainAxisAlignment:
          isWeb ? MainAxisAlignment.start : MainAxisAlignment.spaceEvenly,
          children: [
            const SizedBox(height: 10),
            if (isWeb)
              AllWidgets.buildTabBar(
                tabs: widget.roles,
                selectedIndex: widget.selectedIndex,
                onTabSelected: widget.onRoleChanged,
              ),
            const SizedBox(height: 20),

            FocusTraversalOrder(
              order: NumericFocusOrder(1),
              child: Focus(
                onKeyEvent: (node, event) {
                  if (event is KeyDownEvent &&
                      event.logicalKey == LogicalKeyboardKey.tab) {
                    if (HardwareKeyboard.instance.isShiftPressed) {
                      FocusScope.of(context).previousFocus();
                      FocusScope.of(context).previousFocus();
                      FocusScope.of(context).previousFocus();
                    } else {
                      FocusScope.of(context).nextFocus();
                      FocusScope.of(context).nextFocus();
                      FocusScope.of(context).nextFocus();
                    }
                    return KeyEventResult.handled;
                  }
                  return KeyEventResult.ignored;
                },
                child: AllWidgets.buildTextField(
                  scaleFactor: widget.scaleFactor,
                  label: "Email",
                  hint: "John@example.com",
                  controller: _emailController,
                  isError: _isEmailEmpty,
                  widthw: 0.3,
                ),
              ),
            ),
            const SizedBox(height: 20),

            FocusTraversalOrder(
                order: NumericFocusOrder(2),
                child: Focus(
                  onKeyEvent: (node, event) {
                    if (event is KeyDownEvent && event.logicalKey == LogicalKeyboardKey.enter) {
                      _handleLogin();
                      FocusScope.of(context).nextFocus();
                      return KeyEventResult.handled;
                    }
                    return KeyEventResult.ignored;
                  },
                  child: AllWidgets.buildTextField(
                    scaleFactor: widget.scaleFactor,
                    label: "Password",
                    hint: "Must be at least 6 characters",
                    controller: _passwordController,
                    isPassword: true,
                    isError: _isPasswordEmpty,
                    widthw: 0.3,
                  ),
                )
            ),
            const SizedBox(height: 20),

            MouseRegion(
              cursor: SystemMouseCursors.click,
              onEnter: (_) => setState(() => _isHovered = true),
              onExit: (_) => setState(() => _isHovered = false),
              child: AllWidgets.buildLoginButton(
                scaleFactor: widget.scaleFactor,
                text: "Login",
                isHovered: _isHovered,
                onHoverEnter: () => setState(() => _isHovered = true),
                onHoverExit: () => setState(() => _isHovered = false),
                onPressed: _handleLogin,
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              "or continue with",
              style: TextStyle(color: Colors.white, fontSize: 16),
            ),
            const SizedBox(height: 20),
            AllWidgets.buildSocialButtons(
              onGoogleTap: () async {
                bool success =
                await signInWithGoogle(widget.roles[widget.selectedIndex]);
                if (success) {
                  final uid = FirebaseAuth.instance.currentUser?.uid;
                  await FirebaseDatabase.instance
                      .ref('users/$uid/last_login')
                      .set(ServerValue.timestamp);
                  if (AuthService().isNewUser()) {
                    WidgetsBinding.instance.addPostFrameCallback((_) {
                      Navigator.of(context, rootNavigator: true).push(
                        MaterialPageRoute(
                          builder: (_) => kIsWeb 
                            ? MainLayout(userRole: widget.roles[widget.selectedIndex], nftindex: 8)
                            : MainLayoutMobile(userRole: widget.roles[widget.selectedIndex]),
                        ),
                      );
                    });
                  } else {
                    WidgetsBinding.instance.addPostFrameCallback((_) {
                      Navigator.of(context, rootNavigator: true).push(
                        MaterialPageRoute(
                          builder: (_) => kIsWeb
                            ? MainLayout(userRole: widget.roles[widget.selectedIndex])
                            : MainLayoutMobile(userRole: widget.roles[widget.selectedIndex]),
                        ),
                      );
                    });
                  }
                }
              },
              onFacebookTap: () async {
                bool success = await signInWithFacebook(
                    widget.roles[widget.selectedIndex]);
                if (success) {
                  final uid = FirebaseAuth.instance.currentUser?.uid;
                  await FirebaseDatabase.instance
                      .ref('users/$uid/last_login')
                      .set(ServerValue.timestamp);
                  if (AuthService().isNewUser()) {
                    WidgetsBinding.instance.addPostFrameCallback((_) {
                      Navigator.of(context, rootNavigator: true).push(
                        MaterialPageRoute(
                          builder: (_) => kIsWeb 
                            ? MainLayout(userRole: widget.roles[widget.selectedIndex], nftindex: 8)
                            : MainLayoutMobile(userRole: widget.roles[widget.selectedIndex]),
                        ),
                      );
                    });
                  } else {
                    WidgetsBinding.instance.addPostFrameCallback((_) {
                      Navigator.of(context, rootNavigator: true).push(
                        MaterialPageRoute(
                          builder: (_) => kIsWeb
                            ? MainLayout(userRole: widget.roles[widget.selectedIndex])
                            : MainLayoutMobile(userRole: widget.roles[widget.selectedIndex]),
                        ),
                      );
                    });
                  }
                }
              },
            ),
            const SizedBox(height: 20),
            const Text(
              "Don’t have an account yet?",
              style: TextStyle(color: Colors.white, fontSize: 18),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 10),
            MouseRegion(
              cursor: SystemMouseCursors.click,
              child: GestureDetector(
                onTap: () => widget
                    .onSwitchToRegister(widget.roles[widget.selectedIndex]),
                child: const Text(
                  "Register for Free",
                  style: TextStyle(
                    decoration: TextDecoration.underline,
                    color: Colors.white,
                    fontSize: 18,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
