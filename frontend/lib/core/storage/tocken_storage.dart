import 'package:shared_preferences/shared_preferences.dart';
import 'package:frontend/features/auth/domain/Entities/user_entites.dart';

class SessionLocalDataSource {
  static const String _keyUserId = 'session_user_id';
  static const String _keyName = 'session_name';
  static const String _keyUsername = 'session_username';
  static const String _keyEmail = 'session_email';

  final SharedPreferences _prefs;

  SessionLocalDataSource({required this._prefs});

  /// Saves the user session locally. Only non-sensitive identity data is stored.
  Future<void> saveSession(UserEntity user) async {
    await _prefs.setString(_keyUserId, user.id);
    await _prefs.setString(_keyName, user.name);
    await _prefs.setString(_keyUsername, user.username);
    await _prefs.setString(_keyEmail, user.email);
  }

  /// Returns the saved [UserEntity] or null if no session exists.
  UserEntity? getSession() {
    final id = _prefs.getString(_keyUserId);
    if (id == null || id.isEmpty) return null;

    return UserEntity(
      id: id,
      name: _prefs.getString(_keyName) ?? '',
      username: _prefs.getString(_keyUsername) ?? '',
      email: _prefs.getString(_keyEmail) ?? '',
    );
  }

  /// Clears all session data from local storage.
  Future<void> clearSession() async {
    await _prefs.remove(_keyUserId);
    await _prefs.remove(_keyName);
    await _prefs.remove(_keyUsername);
    await _prefs.remove(_keyEmail);
  }
}
