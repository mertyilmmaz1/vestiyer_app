import 'dart:convert';
import 'dart:math';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';
import 'package:crypto/crypto.dart';

/// Result of a social sign-in when the provider supplies profile data (e.g. Apple first-time).
class SocialSignInResult {
  const SocialSignInResult({
    required this.uid,
    this.email,
    this.firstName,
    this.lastName,
  });
  final String uid;
  final String? email;
  final String? firstName;
  final String? lastName;
}

/// Handles authentication via Firebase Auth (email/password, Google, Apple).
/// Token refresh is automatic; no SharedPreferences token storage needed.
class FirebaseAuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;

  /// Optional Web client ID for Google Sign-In (e.g. for iOS serverClientId).
  /// Set from Firebase Console → Authentication → Sign-in method → Google → Web client ID.
  final String? googleServerClientId;

  FirebaseAuthService({this.googleServerClientId});

  User? get currentFirebaseUser => _auth.currentUser;

  /// Stream of auth state changes (null = signed out).
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  /// Sign in with email and password.
  Future<void> signInWithEmailAndPassword(
    String email,
    String password,
  ) async {
    await _auth.signInWithEmailAndPassword(email: email, password: password);
  }

  /// Create account with email, password, and display name.
  /// Caller should then create/update Firestore user profile with firstName, lastName.
  Future<void> createUserWithEmailAndPassword(
    String email,
    String password,
  ) async {
    await _auth.createUserWithEmailAndPassword(
      email: email,
      password: password,
    );
  }

  /// Sign in with Google. Throws on cancel or failure.
  Future<void> signInWithGoogle() async {
    final googleSignIn = GoogleSignIn(
      serverClientId: googleServerClientId,
    );
    final googleUser = await googleSignIn.signIn();
    if (googleUser == null) {
      throw FirebaseAuthException(
        code: 'sign_in_canceled',
        message: 'Google ile giriş iptal edildi.',
      );
    }
    final googleAuth = await googleUser.authentication;
    final idToken = googleAuth.idToken;
    if (idToken == null) {
      throw FirebaseAuthException(
        code: 'no_id_token',
        message: 'Google kimlik bilgisi alınamadı.',
      );
    }
    final credential = GoogleAuthProvider.credential(
      idToken: idToken,
      accessToken: googleAuth.accessToken,
    );
    await _auth.signInWithCredential(credential);
  }

  /// Sign in with Apple. Throws on cancel or failure.
  /// Returns [SocialSignInResult] with optional name/email (Apple sends these only on first sign-in).
  Future<SocialSignInResult> signInWithApple() async {
    final rawNonce = _generateNonce();
    final hashedNonce = _sha256ofString(rawNonce);

    final appleCredential = await SignInWithApple.getAppleIDCredential(
      scopes: [
        AppleIDAuthorizationScopes.email,
        AppleIDAuthorizationScopes.fullName,
      ],
      nonce: hashedNonce,
    );

    final idToken = appleCredential.identityToken;
    if (idToken == null) {
      throw FirebaseAuthException(
        code: 'no_identity_token',
        message: 'Apple kimlik bilgisi alınamadı.',
      );
    }

    final credential = OAuthProvider('apple.com').credential(
      idToken: idToken,
      rawNonce: rawNonce,
    );
    await _auth.signInWithCredential(credential);

    final uid = _auth.currentUser?.uid ?? '';
    final name = appleCredential.givenName;
    final family = appleCredential.familyName;
    final email = appleCredential.email ?? _auth.currentUser?.email;
    return SocialSignInResult(
      uid: uid,
      email: email,
      firstName: name,
      lastName: family,
    );
  }

  static String _generateNonce([int length = 32]) {
    const charset =
        '0123456789ABCDEFGHIJKLMNOPQRSTUVXYZabcdefghijklmnopqrstuvwxyz';
    final random = Random.secure();
    return List.generate(length, (_) => charset[random.nextInt(charset.length)]).join();
  }

  static String _sha256ofString(String input) {
    final bytes = utf8.encode(input);
    final digest = sha256.convert(bytes);
    return digest.toString();
  }

  /// Sign out.
  Future<void> signOut() async {
    await _auth.signOut();
    await GoogleSignIn().signOut();
  }

  /// Get current user ID (Firebase UID).
  String? get currentUserId => _auth.currentUser?.uid;

  /// Get ID token for callable functions (handled by SDK when using FirebaseFunctions).
  Future<String?> getIdToken({bool forceRefresh = false}) async {
    return _auth.currentUser?.getIdToken(forceRefresh);
  }
}
