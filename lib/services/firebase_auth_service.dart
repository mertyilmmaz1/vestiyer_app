import 'package:firebase_auth/firebase_auth.dart';

/// Handles authentication via Firebase Auth (email/password).
/// Token refresh is automatic; no SharedPreferences token storage needed.
class FirebaseAuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;

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

  /// Sign out.
  Future<void> signOut() async {
    await _auth.signOut();
  }

  /// Get current user ID (Firebase UID).
  String? get currentUserId => _auth.currentUser?.uid;

  /// Get ID token for callable functions (handled by SDK when using FirebaseFunctions).
  Future<String?> getIdToken({bool forceRefresh = false}) async {
    return _auth.currentUser?.getIdToken(forceRefresh);
  }
}
