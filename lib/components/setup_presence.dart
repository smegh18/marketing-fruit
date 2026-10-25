import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';

void setupPresence() {
  final dbRef = FirebaseDatabase.instance.ref();
  final presenceRef = dbRef.child('presence/users');

  // Get unique session id; can use User UID if authenticated, else random.
  final sessionId = FirebaseAuth.instance.currentUser?.uid;

  // Mark online on connect
  presenceRef.child(sessionId!).set({'last_seen': ServerValue.timestamp});
  // Setup disconnect remove
  presenceRef.child(sessionId).onDisconnect().remove();
}
