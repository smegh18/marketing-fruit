import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_facebook_auth/flutter_facebook_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';

import 'auth_service.dart';

Future<bool> signInWithGoogle(String role) async {
  final GoogleSignInAccount? googleUser = await GoogleSignIn(
    clientId: "865810323989-brnpmjjciojv028j1vnker0cbhqm3g3g.apps.googleusercontent.com",
    scopes: ['email'],
  ).signIn();

  if (googleUser == null) return false;

  final GoogleSignInAuthentication googleAuth = await googleUser.authentication;
  final OAuthCredential credential = GoogleAuthProvider.credential(
    accessToken: googleAuth.accessToken,
    idToken: googleAuth.idToken,
  );

  UserCredential userCredential = await FirebaseAuth.instance.signInWithCredential(credential);

  // Check & create user in DB if needed
  await AuthService().checkAndCreateUserInDatabase(userCredential.user!,role);
  return true;
}


Future<bool> signInWithFacebook(String role) async {
  try {
    UserCredential userCredential;

    if (kIsWeb) {
      final facebookProvider = FacebookAuthProvider();
      userCredential = await FirebaseAuth.instance.signInWithPopup(facebookProvider);
    } else {
      final LoginResult result = await FacebookAuth.instance.login();

      if (result.status == LoginStatus.success) {
        final accessToken = result.accessToken;
        final facebookAuthCredential = FacebookAuthProvider.credential(accessToken!.tokenString);
        userCredential = await FirebaseAuth.instance.signInWithCredential(facebookAuthCredential);
      } else {
        print('Facebook sign-in failed: ${result.message}');
        return false;
      }
    }

    // Check & create user in DB if needed
    await AuthService().checkAndCreateUserInDatabase(userCredential.user!,role);
    return true;
  } on FirebaseAuthException catch (e) {
    print('FirebaseAuthException: ${e.message}');
    return false;
  } catch (e) {
    print('General error during Facebook sign-in: $e');
    return false;
  }
}
