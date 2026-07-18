import 'package:google_sign_in/google_sign_in.dart';

class GoogleAuthService {
  GoogleAuthService._internal();
  static final GoogleAuthService instance = GoogleAuthService._internal();

  static const String _googleWebClientId =
      '159001548872-sr9rktlivt6g9ops83m5toh17k0lf11g.apps.googleusercontent.com';

  final GoogleSignIn googleSignIn = GoogleSignIn(
    clientId: _googleWebClientId,
    scopes: ['email', 'profile'],
  );

  Future<void> signOut() async {
    try {
      await googleSignIn.signOut();
    } catch (_) {}
  }
}