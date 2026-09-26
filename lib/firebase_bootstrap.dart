import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';

import 'data/coordinator_store.dart';
import 'data/session_store.dart';
import 'data/shift_store.dart';
import 'firebase_options.dart';
import 'main.dart';
import 'screens/auth_screen.dart';
import 'screens/onboarding_screen.dart';
import 'services/auth_service.dart';

typedef AuthInitializer = Future<AuthService> Function();

Future<AuthService> initializeFirebaseAuth() async {
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  return FirebaseAuthService(FirebaseAuth.instance);
}

class FirebaseBootstrap extends StatefulWidget {
  const FirebaseBootstrap({
    super.key,
    this.initialize = initializeFirebaseAuth,
  });
  final AuthInitializer initialize;

  @override
  State<FirebaseBootstrap> createState() => _FirebaseBootstrapState();
}

class _FirebaseBootstrapState extends State<FirebaseBootstrap> {
  late Future<AuthService> _initialization;

  @override
  void initState() {
    super.initState();
    _initialization = widget.initialize();
  }

  @override
  Widget build(BuildContext context) => FutureBuilder<AuthService>(
    future: _initialization,
    builder: (context, snapshot) {
      if (snapshot.hasError) {
        return BushelApp(
          home: _StartupError(
            message:
                'Bushel could not connect to Firebase. Check the app configuration and your connection, then retry.',
            onRetry: () => setState(() {
              _initialization = widget.initialize();
            }),
          ),
        );
      }
      if (!snapshot.hasData) return const BushelApp(home: _LoadingScreen());
      return AuthGate(auth: snapshot.requireData);
    },
  );
}

/// Owns the entire Navigator so logout also removes pushed/replaced routes.
class AuthGate extends StatefulWidget {
  const AuthGate({super.key, required this.auth});
  final AuthService auth;

  @override
  State<AuthGate> createState() => _AuthGateState();
}

class _AuthGateState extends State<AuthGate> {
  StreamSubscription<String?>? _subscription;
  String? _uid;
  bool _waiting = true;
  bool _failed = false;

  @override
  void initState() {
    super.initState();
    _listen();
  }

  void _listen() {
    _subscription = widget.auth.userIds.listen(
      (uid) {
        if (!mounted) return;
        if (_waiting || uid != _uid) {
          // Mock IDs are still local (Slice 15 owns profile persistence).
          // Clear all three stores before a different authenticated session.
          SessionStore.instance.reset();
          CoordinatorStore.instance.reset();
          ShiftStore.instance.reset();
        }
        setState(() {
          _uid = uid;
          _waiting = false;
          _failed = false;
        });
      },
      onError: (Object error) {
        if (mounted) setState(() => _failed = true);
      },
    );
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_failed) {
      return BushelApp(
        home: _StartupError(
          message: 'Unable to restore your sign-in. Please retry.',
          onRetry: () async {
            await _subscription?.cancel();
            if (!mounted) return;
            setState(() {
              _waiting = true;
              _failed = false;
            });
            _listen();
          },
        ),
      );
    }
    if (_waiting) return const BushelApp(home: _LoadingScreen());
    return AuthScope(
      service: widget.auth,
      child: BushelApp(
        key: ValueKey(_uid),
        home: _uid == null
            ? AuthScreen(auth: widget.auth)
            : const OnboardingScreen(),
      ),
    );
  }
}

class _LoadingScreen extends StatelessWidget {
  const _LoadingScreen();
  @override
  Widget build(BuildContext context) =>
      const Scaffold(body: Center(child: CircularProgressIndicator()));
}

class _StartupError extends StatelessWidget {
  const _StartupError({required this.message, required this.onRetry});
  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) => Scaffold(
    body: Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.cloud_off_outlined, size: 48),
            const SizedBox(height: 16),
            Text(message, textAlign: TextAlign.center),
            const SizedBox(height: 16),
            FilledButton(onPressed: onRetry, child: const Text('Retry')),
          ],
        ),
      ),
    ),
  );
}
