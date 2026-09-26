import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/widgets.dart';

abstract class AuthService {
  Stream<String?> get userIds;
  Future<void> signIn(String email, String password);
  Future<void> register(String email, String password);
  Future<void> signOut();
}

class FirebaseAuthService implements AuthService {
  FirebaseAuthService(this._auth);
  final FirebaseAuth _auth;

  @override
  Stream<String?> get userIds =>
      _auth.authStateChanges().map((user) => user?.uid).distinct();

  @override
  Future<void> signIn(String email, String password) async {
    await _auth.signInWithEmailAndPassword(email: email, password: password);
  }

  @override
  Future<void> register(String email, String password) async {
    await _auth.createUserWithEmailAndPassword(
      email: email,
      password: password,
    );
  }

  @override
  Future<void> signOut() => _auth.signOut();
}

String authErrorMessage(Object error) {
  if (error is! FirebaseAuthException) {
    return 'Something went wrong. Please try again.';
  }
  return switch (error.code) {
    'invalid-email' => 'Enter a valid email address.',
    'invalid-credential' ||
    'wrong-password' ||
    'user-not-found' => 'Email or password is incorrect.',
    'email-already-in-use' =>
      'This email already has an account. Sign in instead.',
    'weak-password' => 'Choose a stronger password with at least 6 characters.',
    'network-request-failed' => 'Check your connection and try again.',
    'too-many-requests' => 'Too many attempts. Please try again later.',
    'user-disabled' => 'This account has been disabled.',
    'operation-not-allowed' =>
      'Email sign-in is not available yet. Please try again later.',
    _ => 'Unable to sign in. Please try again.',
  };
}

class AuthScope extends InheritedWidget {
  const AuthScope({super.key, required this.service, required super.child});
  final AuthService service;

  static AuthService? maybeOf(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<AuthScope>()?.service;

  @override
  bool updateShouldNotify(AuthScope oldWidget) => service != oldWidget.service;
}
