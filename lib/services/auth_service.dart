import 'package:local_auth/local_auth.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:flutter/foundation.dart';

class AuthService {
  static final _auth = FirebaseAuth.instance;
  static final _googleSignIn = GoogleSignIn();
  static final _localAuth = LocalAuthentication();
 
  // ─── Current User ──────────────────────────────────────────────────────────
  static User? get currentUser => _auth.currentUser;
  static String? get currentUid => _auth.currentUser?.uid;
  static bool get isLoggedIn => _auth.currentUser != null;
 
  // ─── Google Sign-In ────────────────────────────────────────────────────────
  static Future<UserCredential?> signInWithGoogle() async {
    try {
      // Trigger Google sign-in flow
      final googleUser = await _googleSignIn.signIn();
      if (googleUser == null) return null; // user cancelled
 
      final googleAuth = await googleUser.authentication;
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );
 
      return await _auth.signInWithCredential(credential);
    } catch (e) {
      debugPrint('Google Sign-In error: $e');
      return null;
    }
  }
 
  // ─── Sign Out ──────────────────────────────────────────────────────────────
  static Future<void> signOut() async {
    await _googleSignIn.signOut();
    await _auth.signOut();
  }

  static Future<bool> authenticate() async {
    try {
      final canCheck = await _localAuth.canCheckBiometrics;
      final isDeviceSupported = await _localAuth.isDeviceSupported();
      if (!canCheck && !isDeviceSupported) return true; // no lock set, allow through

      return await _localAuth.authenticate(
        localizedReason: 'Authenticate to access Expense Tracker',
        options: const AuthenticationOptions(
          biometricOnly: false, // allows PIN/pattern/password fallback
          stickyAuth: true,     // keeps prompt alive if user switches apps
        ),
      );
    } catch (_) {
      return false;
    }
  }
}