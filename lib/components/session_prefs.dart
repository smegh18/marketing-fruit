import 'package:shared_preferences/shared_preferences.dart';

class UserSession {
  static const _kUid = 'bg_uid';

  static Future<void> saveUid(String uid) async {
    final sp = await SharedPreferences.getInstance();
    await sp.setString(_kUid, uid);
  }

  static Future<String?> readUid() async {
    final sp = await SharedPreferences.getInstance();
    return sp.getString(_kUid);
  }

  static Future<void> clearUid() async {
    final sp = await SharedPreferences.getInstance();
    await sp.remove(_kUid);
  }
}
