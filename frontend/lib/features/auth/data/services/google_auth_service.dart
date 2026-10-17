import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:google_sign_in/google_sign_in.dart';

class GoogleAuthService {
  final GoogleSignIn _googleSignIn;

  GoogleAuthService({
    GoogleSignIn? googleSignIn,
    String? serverClientId,
    String? clientId,
  })  : _googleSignIn = googleSignIn ??
            GoogleSignIn(
              scopes: ['email', 'profile'],
              serverClientId: serverClientId,
              clientId: clientId,
            );

  /// Initiates interactive Google Sign-In flow
  Future<GoogleSignInAccount?> signIn() async {
    try {
      debugPrint('[GoogleAuthService] Starting interactive Google Sign-In');
      final account = await _googleSignIn.signIn();
      if (account != null) {
        debugPrint(
          '[GoogleAuthService] Successfully retrieved account: ${account.email} (${account.displayName})',
        );
      } else {
        debugPrint('[GoogleAuthService] Sign-in cancelled by user');
      }
      return account;
    } on PlatformException catch (e, stack) {
      debugPrint('[GoogleAuthService] PlatformException during Google Sign-In: $e\n$stack');
      final message = e.message ?? '';
      if (message.contains('10') ||
          message.contains('DEVELOPER_ERROR') ||
          e.code.contains('10')) {
        throw Exception(
          'Google Sign-In configuration error (ApiException 10: DEVELOPER_ERROR). '
          'Please ensure your SHA-1 fingerprint (B4:0D:27:B1:4D:1D:C5:CD:4F:F6:09:32:A2:20:15:15:55:EF:11:76) '
          'and package name (com.example.frontend) are added to your Firebase or Google Cloud Console.',
        );
      }
      rethrow;
    } catch (e, stack) {
      debugPrint('[GoogleAuthService] Error during Google Sign-In: $e\n$stack');
      rethrow;
    }
  }

  /// Signs out of Google account session
  Future<void> signOut() async {
    try {
      await _googleSignIn.signOut();
    } catch (_) {}
  }
}
