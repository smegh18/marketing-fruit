import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/foundation.dart';

class AuthService {
  static final AuthService _instance = AuthService._internal();
  factory AuthService() => _instance;
  AuthService._internal();
  bool newUser = false;

  final _auth = FirebaseAuth.instance;
  final _db = FirebaseDatabase.instance.ref();
  var _email = "";
  var _password = "";
  var userKey = "";

  // 1. Save initial user details (before email is entered)
  Future<String> saveUserBasicInfo(String tempId, Map<String, dynamic> userDetails, String role) async {
    DatabaseReference newUserRef = _db.child('pending_users').push();
    tempId = newUserRef.key!;
    userKey = tempId;
    debugPrint(userKey);
    await newUserRef.set({
      ...userDetails,
      'role': role,
    });
    return tempId;
  }

  // 2. Update with email and password (still pending stage)
  Future<void> updatePendingUserWithEmail(String id,String email, String password) async {
    await _db.child('pending_users').child(id).update({
      'email': email,
      'password': password, // optionally avoid storing plain passwords
    });
    _email = email;
    _password = password;
  }

  // 3. Register user in Firebase Auth after OTP verification
  Future<UserCredential> registerWithEmail() async {
    debugPrint(_email);
    return await _auth.createUserWithEmailAndPassword(email: _email, password: _password);
  }

  // 4. Migrate pending user to main users DB
  Future<void> movePendingToRegistered(String uid) async {
    final tempRef = _db.child('pending_users').child(userKey);
    final userRef = _db.child('users').child(uid);

    final snapshot = await tempRef.get();
    if (snapshot.exists) {
      final data = Map<String, dynamic>.from(snapshot.value as Map);
      await userRef.set({
        ...data,
        'role': data['role'] ?? 'Student', // fallback
      });
      await tempRef.remove();
    }
  }

  Future<void> updateUserWithGuardianEmail(String id,String email) async {
    await _db.child('users').child(id).update({
      'guardian_email': email,
    });
  }

  // 5. Login user and fetch their info
  Future<User> loginAndFetchUser(String email, String password) async {
    final result = await _auth.signInWithEmailAndPassword(email: email, password: password);
    debugPrint(result.user?.uid);
    return result.user!;
  }

  Future<DataSnapshot> getUserSnapshot(String uid) async {
    final dbRef = _db.child('users');
    return await dbRef.child(uid).get();
  }

  Future<void> checkAndCreateUserInDatabase(User user, String role) async {
    final userRef = FirebaseDatabase.instance.ref("users/${user.uid}");
    final snapshot = await userRef.get();

    if (!snapshot.exists) {
      await userRef.set({
        "email": user.email,
        "created_at": DateTime.now().toIso8601String(),
        "source": "social",
        "role": role,
      });
      newUser = true;
      debugPrint("New user created in DB for UID: ${user.uid}");
    } else {
      debugPrint("User already exists in DB for UID: ${user.uid}");
    }
  }


  // 6. Get current user's UID
  String? getCurrentUserId() {
    return _auth.currentUser?.uid;
  }

  bool isNewUser(){
    return newUser;
  }

  // 7. Logout
  Future<void> signOut() async {
    await _auth.signOut();
  }
}
