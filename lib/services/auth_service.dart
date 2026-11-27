import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:google_sign_in/google_sign_in.dart';

abstract class AuthService {
  Stream<String?> get userIds;
  String? get currentEmail;
  Future<void> signIn(String email, String password);
  Future<void> register(String email, String password);
  bool get supportsGoogleSignIn => false;
  Future<void> signInWithGoogle() =>
      Future.error(UnsupportedError('Google sign-in is unavailable.'));
  Future<void> signOut();

  /// Signs in, or creates the account when it does not exist yet.
  Future<void> ensureAccount(String email, String password) async {
    try {
      await signIn(email, password);
    } on FirebaseAuthException catch (error) {
      if (error.code != 'user-not-found' &&
          error.code != 'invalid-credential' &&
          error.code != 'wrong-password') {
        rethrow;
      }
      try {
        await register(email, password);
      } on FirebaseAuthException catch (createError) {
        if (createError.code == 'email-already-in-use') {
          await signIn(email, password);
          return;
        }
        rethrow;
      }
    }
  }
}

class FirebaseAuthService extends AuthService {
  FirebaseAuthService(this._auth);
  final FirebaseAuth _auth;
  Future<void>? _googleInitialization;

  @override
  bool get supportsGoogleSignIn =>
      kIsWeb ||
      defaultTargetPlatform == TargetPlatform.android ||
      defaultTargetPlatform == TargetPlatform.iOS;

  @override
  Future<void> signInWithGoogle() async {
    if (kIsWeb) {
      await _auth.signInWithPopup(GoogleAuthProvider());
      return;
    }
    final google = GoogleSignIn.instance;
    await (_googleInitialization ??= google.initialize());
    final account = await google.authenticate();
    final idToken = account.authentication.idToken;
    if (idToken == null) {
      throw FirebaseAuthException(code: 'missing-google-id-token');
    }
    await _auth.signInWithCredential(
      GoogleAuthProvider.credential(idToken: idToken),
    );
  }

  @override
  Stream<String?> get userIds =>
      _auth.authStateChanges().map((user) => user?.uid).distinct();

  @override
  String? get currentEmail => _auth.currentUser?.email;

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
  Future<void> signOut() async {
    if (_googleInitialization != null) {
      try {
        await GoogleSignIn.instance.signOut();
      } on GoogleSignInException catch (error) {
        debugPrint('Google sign-out failed: ${error.code.name}');
      }
    }
    await _auth.signOut();
  }
}

String? googleSignInError(Object error) {
  if (error is GoogleSignInException) {
    if (error.code == GoogleSignInExceptionCode.canceled) return null;
    return 'Could not sign in with Google. Please try again or use email.';
  }
  if (error is FirebaseAuthException) {
    return switch (error.code) {
      'popup-closed-by-user' || 'cancelled-popup-request' => null,
      'popup-blocked' => 'Allow pop-ups for Bushel and try again.',
      'account-exists-with-different-credential' => 'This email already has an account. Sign in using your original method.',
      'network-request-failed' => authErrorMessage(error),
      _ => 'Could not sign in with Google. Please try again or use email.',
    };
  }
  return 'Could not sign in with Google. Please try again or use email.';
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
