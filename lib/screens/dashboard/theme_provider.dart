import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';

class ThemeProvider extends ChangeNotifier {
  bool _isDarkMode = false;

  ThemeProvider() {
    _initWithSystemBrightness();
  }

  bool get isDarkMode => _isDarkMode;

  ThemeMode get currentTheme {
    return _isDarkMode ? ThemeMode.dark : ThemeMode.light;
  }

  void toggleTheme() {
    _isDarkMode = !_isDarkMode;
    notifyListeners();
  }

  void _initWithSystemBrightness() {
    if (!kIsWeb) {
      final brightness =
          WidgetsBinding.instance.platformDispatcher.platformBrightness;
      _isDarkMode = brightness == Brightness.dark;
    } else {
      _isDarkMode = false;
    }
  }
}
