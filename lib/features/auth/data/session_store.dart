import 'package:shared_preferences/shared_preferences.dart';

import 'auth_repository.dart';

abstract class SessionStore {
  Future<AuthSession?> read();

  Future<void> write(AuthSession session);

  Future<void> clear();
}

class SharedPrefsSessionStore implements SessionStore {
  SharedPrefsSessionStore();

  static const _sessionKey = 'picpac.auth.session';

  @override
  Future<AuthSession?> read() async {
    final prefs = await SharedPreferences.getInstance();
    return AuthSession.tryParse(prefs.getString(_sessionKey));
  }

  @override
  Future<void> write(AuthSession session) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_sessionKey, session.toStorageValue());
  }

  @override
  Future<void> clear() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_sessionKey);
  }
}
