import 'package:shared_preferences/shared_preferences.dart';
import 'package:frontend/features/auth/domain/Entities/user_entites.dart';

class SessionLocalDataSource {
  static const String _keyUserId = 'session_user_id';
  static const String _keyName = 'session_name';
  static const String _keyUsername = 'session_username';
  static const String _keyEmail = 'session_email';
  static const String _keyProfileImage = 'session_profile_image';
  static const String _keyToken = 'session_access_token';
  static const String _keyRefreshToken = 'session_refresh_token';

  final SharedPreferences _prefs;

  SessionLocalDataSource({required this._prefs});

  /// Saves the user session, access token, and refresh token locally.
  Future<void> saveSession(UserEntity user) async {
    await _prefs.setString(_keyUserId, user.id);
    await _prefs.setString(_keyName, user.name);
    await _prefs.setString(_keyUsername, user.username);
    await _prefs.setString(_keyEmail, user.email);
    if (user.profileImage != null && user.profileImage!.isNotEmpty) {
      await _prefs.setString(_keyProfileImage, user.profileImage!);
    } else {
      await _prefs.remove(_keyProfileImage);
    }
    if (user.token != null && user.token!.isNotEmpty) {
      await _prefs.setString(_keyToken, user.token!);
    }
    if (user.refreshToken != null && user.refreshToken!.isNotEmpty) {
      await _prefs.setString(_keyRefreshToken, user.refreshToken!);
    }
  }

  /// Saves updated access token and optional rotated refresh token.
  Future<void> saveTokens({
    required String accessToken,
    String? refreshToken,
  }) async {
    await _prefs.setString(_keyToken, accessToken);
    if (refreshToken != null && refreshToken.isNotEmpty) {
      await _prefs.setString(_keyRefreshToken, refreshToken);
    }
  }

  /// Saves the authentication JWT access token locally.
  Future<void> saveToken(String token) async {
    await _prefs.setString(_keyToken, token);
  }

  /// Returns the saved JWT access token or null if none exists.
  String? getToken() {
    return _prefs.getString(_keyToken);
  }

  /// Returns the saved refresh token or null if none exists.
  String? getRefreshToken() {
    return _prefs.getString(_keyRefreshToken);
  }

  /// Returns the saved [UserEntity] or null if no valid session/token exists.
  UserEntity? getSession() {
    final id = _prefs.getString(_keyUserId);
    final token = _prefs.getString(_keyToken);
    final refreshToken = _prefs.getString(_keyRefreshToken);

    // Session is only valid if user ID and at least one token exists
    if (id == null || id.isEmpty) return null;
    if ((token == null || token.isEmpty) && (refreshToken == null || refreshToken.isEmpty)) {
      return null;
    }

    return UserEntity(
      id: id,
      name: _prefs.getString(_keyName) ?? '',
      username: _prefs.getString(_keyUsername) ?? '',
      email: _prefs.getString(_keyEmail) ?? '',
      profileImage: _prefs.getString(_keyProfileImage),
      token: token,
      refreshToken: refreshToken,
    );
  }

  /// Clears all session data and tokens from local storage.
  Future<void> clearSession() async {
    await _prefs.remove(_keyUserId);
    await _prefs.remove(_keyName);
    await _prefs.remove(_keyUsername);
    await _prefs.remove(_keyEmail);
    await _prefs.remove(_keyProfileImage);
    await _prefs.remove(_keyToken);
    await _prefs.remove(_keyRefreshToken);
  }
}
