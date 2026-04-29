import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import 'models.dart';

class SessionStore {
  static const String _sessionKey = 'workflow_session';

  Future<UserSession?> read() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_sessionKey);
    if (raw == null || raw.isEmpty) {
      return null;
    }

    try {
      final json = jsonDecode(raw) as Map<String, dynamic>;
      return UserSession.fromJson(json);
    } catch (_) {
      await prefs.remove(_sessionKey);
      return null;
    }
  }

  Future<void> save(UserSession session) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_sessionKey, jsonEncode(session.toJson()));
  }

  Future<void> clear() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_sessionKey);
  }
}
