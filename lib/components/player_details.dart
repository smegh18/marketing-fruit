import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:intl/intl.dart';

import 'auth_service.dart';

class PlayerDetails {
  final authService = AuthService();

  // Use a getter that is null if there's no user
  String? get userId => FirebaseAuth.instance.currentUser?.uid;

  void getName(String name) {
    final uid = userId;
    if (uid == null) return;
    FirebaseDatabase.instance.ref('users/$uid/playerDetails/name').set(name);
  }

  void getSex(String sex){
    final uid = userId;
    if (uid == null) return;
    FirebaseDatabase.instance.ref('users/$uid/playerDetails/gender').set(sex);
  }

  void getWallet(){
    final uid = userId;
    if (uid == null) return;
    FirebaseDatabase.instance.ref('wallet/$uid/balance').set(10000);
    FirebaseDatabase.instance.ref('wallet/$uid/gems').set(0);
  }

  Future<void> initWallet()async {
    final uid = userId;
    if (uid == null) return;
    await FirebaseDatabase.instance.ref('wallet/$uid/balance').set(0);
    await FirebaseDatabase.instance.ref('wallet/$uid/gems').set(0);
  }

  void getCompanyName(String company){
    final uid = userId;
    if (uid == null) return;
    FirebaseDatabase.instance.ref('users/$uid/playerDetails/companyName').set(company);
  }

  void getMovieName(String movie){
    final uid = userId;
    if (uid == null) return;
    FirebaseDatabase.instance.ref('movies/$uid/movieName').set(movie);
  }

  void getGenre(String genre){
    final uid = userId;
    if (uid == null) return;
    FirebaseDatabase.instance.ref('movies/$uid/genre').set(genre);
  }

  void getStoryline(String storyline){
    final uid = userId;
    if (uid == null) return;
    FirebaseDatabase.instance.ref('movies/$uid/storyline').set(storyline);
  }

  void gameMechanics(){
    final uid = userId;
    if (uid == null) return;
    FirebaseDatabase.instance.ref('gameMechanics/$uid/sales').set(100);
    FirebaseDatabase.instance.ref('gameMechanics/$uid/profit_margin').set(100);
    FirebaseDatabase.instance.ref('gameMechanics/$uid/cost_of_operations').set(100);
    FirebaseDatabase.instance.ref('gameMechanics/$uid/customer_loyalty').set(100);
    FirebaseDatabase.instance.ref('gameMechanics/$uid/type').set('-');
    FirebaseDatabase.instance.ref('gameMechanics/$uid/choice').set('-');
  }

  Future<String> fetchCompanyName() async {
    final uid = userId;
    if (uid == null) return '';
    String companyName = await FirebaseDatabase.instance.ref().child('users/$uid/playerDetails/companyName').get().then((snapshot) {
      return snapshot.value?.toString() ?? '';
    });
    return companyName;
  }

  Future<String> fetchUserName() async {
    final uid = userId;
    if (uid == null) return '';
    String firstName = await FirebaseDatabase.instance.ref().child('users/$uid/first_name').get().then((snapshot) {
      return snapshot.value?.toString() ?? '';
    });
    return firstName;
  }

  Future<String> fetchArc() async {
    final uid = userId;
    if (uid == null) return '';
    String arc = await FirebaseDatabase.instance.ref().child('users/$uid/playerDetails/arc').get().then((snapshot) {
      return snapshot.value?.toString() ?? '';
    });
    return arc;
  }

  Future<void> updateStreak() async {
    final uid = userId;
    if (uid == null) return;
    final dbRef = FirebaseDatabase.instance.ref("streaks/$uid");

    // Format today and yesterday
    final now = DateTime.now();
    final todayStr = DateFormat('yyyy-MM-dd').format(now);
    final yesterdayStr = DateFormat('yyyy-MM-dd').format(now.subtract(Duration(days: 1)));

    final snapshot = await dbRef.get();
    Map<String, dynamic> currentData = {};

    if (snapshot.exists) {
      currentData = Map<String, dynamic>.from(snapshot.value as Map);
    }

    // If yesterday exists, continue streak. Otherwise, start new streak.
    bool isStreakContinued = currentData.containsKey(yesterdayStr);

    // Add today's date
    await dbRef.child(todayStr).set(true);

    // Optional: cleanup
    if (!isStreakContinued) {
      for (var key in currentData.keys) {
        await dbRef.child(key).remove();
      }
      await dbRef.child(todayStr).set(true);
    }
  }

  Future<String> fetchBalance() async {
    final uid = userId;
    if (uid == null) return "0";
    final snapshot = await FirebaseDatabase.instance
        .ref()
        .child('wallet/$uid/balance')
        .get();

    final value = snapshot.value;

    if (value == null) {
      await initWallet();
      return "0";
    }
    return value.toString();
  }

  void getArc(String arc){
    final uid = userId;
    if (uid == null) return;
    FirebaseDatabase.instance.ref('users/$uid/playerDetails/arc').set(arc);
  }

  // Progress management methods
  void saveProgress(String currentFrame, Map<String, dynamic>? choices) {
    try {
      final uid = userId;
      if (uid == null) return;
      
      Map<String, dynamic> progressData = {
        'currentFrame': currentFrame,
        'lastUpdated': DateTime.now().toIso8601String(),
      };
      
      if (choices != null) {
        progressData['choices'] = choices;
      }
      
      // Use fire-and-forget approach to avoid blocking UI
      FirebaseDatabase.instance.ref('progress/$uid/entertainment_arc').set(progressData).catchError((error) {
        // Silently handle errors - progress saving is not critical for navigation
        print('Progress save error: $error');
      });
    } catch (e) {
      // Silently handle errors - progress saving is not critical for navigation
      print('Progress save error: $e');
    }
  }

  Future<Map<String, dynamic>?> loadProgress() async {
    try {
      final uid = userId;
      if (uid == null) return null;
      
      final snapshot = await FirebaseDatabase.instance
          .ref('progress/$uid/entertainment_arc')
          .get();
      
      if (snapshot.exists && snapshot.value != null) {
        final value = snapshot.value;
        if (value is Map) {
          return Map<String, dynamic>.from(value);
        }
      }
      return null;
    } catch (e) {
      // Return null if any error occurs
      return null;
    }
  }

  void clearProgress() {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;
    FirebaseDatabase.instance.ref('progress/$uid/entertainment_arc').remove();
  }

  Future<bool> hasProgress() async {
    final progress = await loadProgress();
    return progress != null;
  }
}
