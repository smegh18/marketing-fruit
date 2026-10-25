# Error Handling & Security Report

## 1. Global Error Boundaries

To prevent the application from crashing unexpectedly and to ensure gracefully handled failures, global error boundaries have been established in the entry point (`main.dart`):

1. **FlutterError.onError**: Captures errors thrown during the Flutter build phase, layout, or paint phases. Instead of the default red screen of death causing application termination, it gracefully logs the error context.
2. **PlatformDispatcher.instance.onError**: Captures asynchronous exceptions (e.g., failed Futures, unhandled network exceptions) that bypass the standard try-catch blocks.

## 2. Hardcoded Secrets & Backdoors Remediated

During the audit, critical security vulnerabilities were discovered and remediated:

### A. WordPress API Credentials
**Issue**: `loginform.dart` contained plaintext credentials for the WordPress `LearnPress` integration (`adminAppPassword`).
**Fix**: Migrated the credentials to environment variables using the `flutter_dotenv` package. Secrets are now securely loaded at runtime via `dotenv.env['WP_ADMIN_APP_PASSWORD']`.

### B. Admin Login Backdoor
**Issue**: `loginform.dart` contained a hardcoded conditional that bypassed Firebase Authentication entirely:
```dart
if (_emailController.text == 'admin' && _passwordController.text == 'admin') {
    // Navigate directly to Admin Layout
}
```
**Fix**: This block has been completely purged from the source code. All admin access must now securely authenticate through Firebase Auth and rely on database-driven role checks (`snapshot.child("role").value`).

## 3. Asynchronous Context Usage (BuildContext)

**Issue**: Across 20 files in the `entertainment_arc/` module and various forms (e.g., `loginform.dart`, `login_screen.dart`), the application was accessing `BuildContext` after `await` calls without checking if the widget was still mounted. This leads to `Unhandled Exception: Null check operator used on a null value` or memory leaks when navigating quickly.
**Fix**: A comprehensive audit and script safely injected `if (!mounted) return;` checks before all `Navigator.push` and `setState` calls following async gaps, securing the application against lifecycle crashes.

## 4. Null Safety & State Preservation

**Issue**: `ThemeProvider` improperly mixed non-nullable boolean declarations with nullable checks (`isDarkMode == null` and `isDarkMode!`).
**Fix**: Refactored `ThemeProvider` to use strict non-nullable booleans and clear getter/setter logic, preventing runtime null reference exceptions during theme toggling.
