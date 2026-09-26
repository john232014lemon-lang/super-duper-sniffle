import 'package:flutter/material.dart';

import 'data/coordinator_store.dart';
import 'data/session_store.dart';
import 'main.dart';
import 'screens/family_center_screen.dart';
import 'screens/home_screen.dart';
import 'screens/onboarding_screen.dart';
import 'services/auth_service.dart';
import 'services/profile_service.dart';

class ProfileApp extends StatefulWidget {
  const ProfileApp({
    super.key,
    required this.uid,
    required this.repository,
    required this.isCurrent,
  });
  final String uid;
  final ProfileRepository repository;
  final bool Function() isCurrent;
  @override
  State<ProfileApp> createState() => _ProfileAppState();
}

class _ProfileAppState extends State<ProfileApp> {
  late Future<AdultProfile?> _profile;
  String? _signOutError;
  @override
  void initState() {
    super.initState();
    _profile = _load();
  }

  Future<AdultProfile?> _load() async {
    final profile = await widget.repository.load(widget.uid);
    if (mounted && widget.isCurrent() && profile != null) {
      SessionStore.instance.configureParent(
        name: profile.name,
        role: profile.role,
        family: profile.family,
      );
      CoordinatorStore.instance.configureParent(profile.name, profile.role);
    }
    return profile;
  }

  @override
  Widget build(BuildContext context) => ProfileScope(
    uid: widget.uid,
    repository: widget.repository,
    isCurrent: widget.isCurrent,
    child: FutureBuilder<AdultProfile?>(
      future: _profile,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const BushelApp(
            home: Scaffold(body: Center(child: CircularProgressIndicator())),
          );
        }
        if (snapshot.hasError) {
          return BushelApp(
            home: Scaffold(
              body: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text(
                      'Unable to load your profile. Check your connection and retry.',
                    ),
                    FilledButton(
                      onPressed: () => setState(() {
                        _profile = _load();
                      }),
                      child: const Text('Retry'),
                    ),
                    TextButton(
                      onPressed: () async {
                        try {
                          await AuthScope.maybeOf(context)?.signOut();
                        } catch (_) {
                          if (mounted) {
                            setState(
                              () => _signOutError =
                                  'Could not sign out. Please try again.',
                            );
                          }
                        }
                      },
                      child: const Text('Sign out'),
                    ),
                    if (_signOutError != null) Text(_signOutError!),
                  ],
                ),
              ),
            ),
          );
        }
        final profile = snapshot.data;
        return BushelApp(
          home: profile == null
              ? const OnboardingScreen()
              : profile.family
              ? const FamilyCenterScreen()
              : HomeScreen(name: profile.name),
        );
      },
    ),
  );
}
