import 'package:flutter_test/flutter_test.dart';
import 'package:google_sign_in/google_sign_in.dart';

void main() {
  test('GoogleSignIn class compiles and initializes', () {
    final googleSignIn = GoogleSignIn(scopes: ['email', 'profile']);
    expect(googleSignIn.scopes, contains('email'));
    expect(googleSignIn.scopes, contains('profile'));
  });
}
