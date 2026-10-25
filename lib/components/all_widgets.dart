import 'dart:ui';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'dart:io' show Platform;

typedef FieldValidator = void Function();

class AllWidgets {
  static Widget buildTabBar({
    required List<String> tabs,
    required int selectedIndex,
    required Function(int) onTabSelected,
  }) {
    if (kIsWeb || (!Platform.isAndroid && !Platform.isIOS)) {
      // Web or non-mobile platforms
      return Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: List.generate(tabs.length, (index) {
          return buildTab(
            tabs[index],
            selectedIndex == index,
                () => onTabSelected(index),
          );
        }),
      );
    }
    return Container();
  }

  static Widget buildBackground() {
    if (kIsWeb) {
      return Image.asset('assets/Login_Page_Background.png', fit: BoxFit.cover);
    } else if (Platform.isAndroid || Platform.isIOS) {
      return Image.asset('assets/background.png', fit: BoxFit.fill);
    } else {
      return Container(color: Colors.grey); // fallback
    }
  }


  static Widget buildFrostedGlassContainer({
    double scaleFactor = 1.0,
    required Widget child,
    double width = 500,
    double height = 700,
    double borderRadius = 40,
    double blurSigma = 5,
    EdgeInsets padding = const EdgeInsets.all(20),
    Color backgroundColor = const Color(0xFF888888),
    Color borderColor = const Color(0xFF888888),
  }) {
    return Center(
      child: ClipRRect(
        borderRadius: BorderRadius.circular(borderRadius),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: blurSigma, sigmaY: blurSigma),
          child: Container(
            width: width * scaleFactor,
            height: height * scaleFactor,
            padding: padding * scaleFactor,
            decoration: BoxDecoration(
              color: backgroundColor.withOpacity(0.2),
              borderRadius: BorderRadius.circular(borderRadius),
              border: Border.all(
                width: 3,
                color: borderColor.withOpacity(0.5),
              ),
            ),
            child: child,
          ),
        ),
      ),
    );
  }


  static Widget buildTab(String title, bool isSelected, VoidCallback onTap) {
    return MouseRegion(
      cursor: SystemMouseCursors.grab,
      child: GestureDetector(
        onTap: onTap,
        child: Column(
          children: [
            Text(
              title,
              style: TextStyle(
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                fontSize: 20,
                color: Colors.white,
              ),
            ),
            if (isSelected)
              Container(
                height: 3,
                width: 80,
                color: Colors.white,
                margin: EdgeInsets.only(top: 6),
              ),
          ],
        ),
      ),
    );
  }

  static Widget buildTextField({
    double scaleFactor = 1.0,
    required String label,
    required String hint,
    required TextEditingController controller,
    double widthm = 0.85,
    double widthw = 0.25,
    bool isPassword = false,
    bool isError = false,
  }) {
    FocusNode focusNode = FocusNode();
    bool isPasswordVisible = false;
    final isMobile = !kIsWeb && (Platform.isAndroid || Platform.isIOS);

    return StatefulBuilder(
      builder: (context, setState) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: TextStyle(
                fontSize: 18 * scaleFactor,
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            SizedBox(
              width: isMobile ? MediaQuery.of(context).size.width * widthm : MediaQuery.of(context).size.width * widthw *scaleFactor,
              child: Focus(
                onFocusChange: (hasFocus) => setState(() {}),
                child: TextField(
                  controller: controller,
                  obscureText: isPassword && !isPasswordVisible,
                  focusNode: focusNode,
                  style: const TextStyle(color: Colors.black),
                  decoration: InputDecoration(
                    filled: true,
                    fillColor: focusNode.hasFocus
                        ? const Color.fromARGB(255, 229, 243, 255).withOpacity(0.8)
                        : Colors.white,
                    hintText: hint,
                    hintStyle: const TextStyle(color: Colors.grey),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide.none,
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide(
                        color: isError ? Colors.red : Colors.transparent,
                      ),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: const BorderSide(color: Colors.blue, width: 2),
                    ),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                    suffixIcon: isPassword
                        ? IconButton(
                      icon: Icon(
                        isPasswordVisible ? Icons.visibility : Icons.visibility_off,
                        color: Colors.grey,
                      ),
                      onPressed: () {
                        setState(() {
                          isPasswordVisible = !isPasswordVisible;
                        });
                      },
                    )
                        : null,
                  ),
                ),
              ),
            ),
            if (isError)
              const Padding(
                padding: EdgeInsets.only(top: 5),
                child: Text(
                  "This field is required!",
                  style: TextStyle(color: Colors.red, fontSize: 14, fontWeight: FontWeight.bold),
                ),
              ),
          ],
        );
      },
    );
  }




  static Widget buildLoginButton({
    double scaleFactor = 1.0,
    required bool isHovered,
    required VoidCallback onHoverEnter,
    required VoidCallback onHoverExit,
    required VoidCallback onPressed,
    required String text,
  }) {
    return GestureDetector(
      onTap: onPressed,
      child: MouseRegion(
        onEnter: (_) => onHoverEnter(),
        onExit: (_) => onHoverExit(),
        cursor: SystemMouseCursors.click,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          width: 400 * scaleFactor,
          height: 50 * scaleFactor,
          decoration: BoxDecoration(
            color: isHovered ? Colors.black : Colors.white,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Center(
            child: Text(
              text,
              style: TextStyle(
                color: isHovered ? Colors.white : Colors.black,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
      ),
    );
  }

  static Widget buildSocialButtons({
    required VoidCallback onGoogleTap,
    required VoidCallback onFacebookTap,
    // required VoidCallback onMetaMaskTap,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _socialButton("assets/google_logo.png", onGoogleTap),
        const SizedBox(width: 16),
        _socialButton("assets/facebook_logo.png", onFacebookTap),
        const SizedBox(width: 16),
        // _socialButton("assets/metamask_logo.png", onMetaMaskTap),
      ],
    );
  }

  static Widget _socialButton(String iconPath, VoidCallback onTap) {
    return ElevatedButton(
      onPressed: onTap,
      style: ElevatedButton.styleFrom(
        fixedSize: const Size(150, 30),
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        padding: const EdgeInsets.all(10),
        elevation: 2,
        minimumSize: const Size(50, 50),
      ),
      child: Image.asset(iconPath, width: 24, height: 24),
    );
  }

  static Widget buildGenderDropdown({
    required String? selectedGender,
    required void Function(String?) onChanged,
    required bool showError ,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          "Gender",
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.white,
            fontSize: 20,
          ),
        ),
        const SizedBox(height: 5),
        DropdownButtonFormField<String>(
          isExpanded: true,
          value: selectedGender,
          decoration: InputDecoration(
            filled: true,
            fillColor: Colors.white.withOpacity(0.8),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide.none,
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: Colors.red, width: 2),
            ),
            errorStyle: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.bold,
              color: Colors.red,
            ),
          ),
          hint: const Text("Select Gender"),
          items: ["Male", "Female", "Prefer not to say"].map((gender) {
            return DropdownMenuItem<String>(
              value: gender,
              child: Text(gender),
            );
          }).toList(),
          onChanged: onChanged,
          validator: (value) =>
          value == null ? "Please select gender" : null,
        ),
      ],
    );
  }


  /// Date Picker Widget
  static Widget buildDatePicker({
    required BuildContext context,
    required TextEditingController dobController,
    bool showError = false,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          "Date of Birth",
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.white,
            fontSize: 20,
          ),
        ),
        const SizedBox(height: 5),
        TextFormField(
          controller: dobController,
          readOnly: true,
          decoration: InputDecoration(
            hintText: "MM/DD/YYYY",
            filled: true,
            fillColor: Colors.white.withOpacity(0.8),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide.none,
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: Colors.red, width: 2),
            ),
            suffixIcon: const Icon(Icons.calendar_today, color: Colors.black54),
            errorStyle: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.bold,
              color: Colors.red,
            ),
          ),
          onTap: () async {
            DateTime? pickedDate = await showDatePicker(
              context: context,
              initialDate: DateTime.now(),
              firstDate: DateTime(1900),
              lastDate: DateTime.now(),
            );

            if (pickedDate != null) {
              dobController.text =
              "${pickedDate.month}/${pickedDate.day}/${pickedDate.year}";
            }
          },
          validator: (value) =>
          showError && value!.isEmpty ? "Please select a date" : null,
        ),
      ],
    );
  }

}

class CustomTextField extends StatefulWidget {
  final double scaleFactor;
  final String label;
  final String hint;
  final TextEditingController controller;
  final double widthm;
  final double widthw;
  final bool isPassword;
  final bool isError;
  final FocusNode? focusNode;
  final ValueChanged<String>? onChanged;

  const CustomTextField({
    super.key,
    this.scaleFactor = 1.0,
    required this.label,
    required this.hint,
    required this.controller,
    this.widthm = 0.85,
    this.widthw = 0.25,
    this.isPassword = false,
    this.isError = false,
    this.focusNode,
    this.onChanged,
  });

  @override
  State<CustomTextField> createState() => _CustomTextFieldState();
}

class _CustomTextFieldState extends State<CustomTextField> {
  late FocusNode _internalFocusNode;
  bool _useInternalFocusNode = false;
  bool _isPasswordVisible = false;

  FocusNode get _focusNode => widget.focusNode ?? _internalFocusNode;

  @override
  void initState() {
    super.initState();
    if (widget.focusNode == null) {
      _internalFocusNode = FocusNode();
      _useInternalFocusNode = true;
    }
  }

  @override
  void dispose() {
    if (_useInternalFocusNode) {
      _internalFocusNode.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isMobile = !kIsWeb && (Platform.isAndroid || Platform.isIOS);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          widget.label,
          style: TextStyle(
            fontSize: 18 * widget.scaleFactor,
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        SizedBox(
          width: isMobile
              ? MediaQuery.of(context).size.width * widget.widthm
              : MediaQuery.of(context).size.width * widget.widthw * widget.scaleFactor,
          child: Focus(
            focusNode: _focusNode,
            onFocusChange: (_) => setState(() {}),
            child: TextField(
              controller: widget.controller,
              obscureText: widget.isPassword && !_isPasswordVisible,
              focusNode: _focusNode,
              style: const TextStyle(color: Colors.black),
              onChanged: widget.onChanged,
              decoration: InputDecoration(
                filled: true,
                fillColor: _focusNode.hasFocus
                    ? const Color.fromARGB(255, 229, 243, 255).withOpacity(0.8)
                    : Colors.white,
                hintText: widget.hint,
                hintStyle: const TextStyle(color: Colors.grey),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide.none,
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(
                    color: widget.isError ? Colors.red : Colors.transparent,
                  ),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: const BorderSide(color: Colors.blue, width: 2),
                ),
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                suffixIcon: widget.isPassword
                    ? IconButton(
                  icon: Icon(
                    _isPasswordVisible ? Icons.visibility : Icons.visibility_off,
                    color: Colors.grey,
                  ),
                  onPressed: () {
                    setState(() {
                      _isPasswordVisible = !_isPasswordVisible;
                    });
                  },
                )
                    : null,
              ),
            ),
          ),
        ),
        if (widget.isError)
          const Padding(
            padding: EdgeInsets.only(top: 5),
            child: Text(
              "This field is required!",
              style: TextStyle(color: Colors.red, fontSize: 14, fontWeight: FontWeight.bold),
            ),
          ),
      ],
    );
  }
}

