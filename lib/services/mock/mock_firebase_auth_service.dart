import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

import '../firebase_auth_service.dart';

/// Notifier for mock "signed in" state. When [value] is true, mock user is considered logged in.
final mockSignedInNotifier = ValueNotifier<bool>(true);

/// Mock auth: no Firebase calls. [currentUserId] returns [mockUserId] when [mockSignedInNotifier] is true.
class MockFirebaseAuthService extends FirebaseAuthService {
  static const String mockUserId = 'mock-user-uid';

  @override
  User? get currentFirebaseUser => null;

  @override
  Stream<User?> get authStateChanges => Stream.value(null);

  @override
  String? get currentUserId => mockSignedInNotifier.value ? mockUserId : null;

  @override
  Future<UserCredential> signInWithEmailAndPassword(String email, String password) async {
    mockSignedInNotifier.value = true;
    throw UnimplementedError('Mock sign-in: use mockSignedInNotifier');
  }

  @override
  Future<UserCredential> createUserWithEmailAndPassword(String email, String password) async {
    mockSignedInNotifier.value = true;
    throw UnimplementedError('Mock sign-up: use mockSignedInNotifier');
  }

  @override
  Future<void> signOut() async {
    mockSignedInNotifier.value = false;
  }

  @override
  Future<String?> getIdToken({bool forceRefresh = false}) async => 'mock-token';
}
