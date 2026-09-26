import 'dart:async';

import 'package:bushel/data/session_store.dart';
import 'package:bushel/firebase_bootstrap.dart';
import 'package:bushel/screens/auth_screen.dart';
import 'package:bushel/screens/home_screen.dart';
import 'package:bushel/screens/profile_screen.dart';
import 'package:bushel/services/profile_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'auth_test.dart' show FakeAuth;

class MemoryProfiles implements ProfileRepository {
  final values = <String, AdultProfile>{};
  final pending = <String, Completer<AdultProfile?>>{};
  bool failLoad = false;
  bool failSave = false;
  Completer<void>? saving;
  @override
  Future<AdultProfile?> load(String uid) async {
    if (failLoad) throw StateError('offline');
    if (pending.containsKey(uid)) return pending[uid]!.future;
    return values[uid];
  }

  @override
  Future<void> save(String uid, AdultProfile profile) async {
    if (failSave) throw StateError('offline');
    if (saving != null) await saving!.future;
    values[uid] = profile;
  }
}

const adult = AdultProfile(
  name: 'Saved adult',
  role: BushelRole.volunteer,
  family: false,
);

void main() {
  late FakeAuth auth;
  late MemoryProfiles profiles;
  setUp(() {
    auth = FakeAuth(uid: 'adult');
    profiles = MemoryProfiles();
  });
  tearDown(() async => auth.changes.close());

  testWidgets(
    'restores profile across logout and sign-in; other adults onboard',
    (tester) async {
      profiles.values['adult'] = adult;
      await tester.pumpWidget(AuthGate(auth: auth, profiles: profiles));
      await tester.pumpAndSettle();
      expect(find.byType(HomeScreen), findsOneWidget);
      expect(SessionStore.instance.parentName, adult.name);
      auth.emit(null);
      await tester.pumpAndSettle();
      expect(find.byType(AuthScreen), findsOneWidget);
      auth.emit('other');
      await tester.pumpAndSettle();
      expect(find.text('Get started'), findsOneWidget);
      expect(SessionStore.instance.parentName, isNot(adult.name));
      auth.emit('adult');
      await tester.pumpAndSettle();
      expect(find.byType(HomeScreen), findsOneWidget);
      expect(SessionStore.instance.parentName, adult.name);
    },
  );

  testWidgets('failed reads retry instead of replacing existing profiles', (
    tester,
  ) async {
    profiles.values['adult'] = adult;
    profiles.failLoad = true;
    await tester.pumpWidget(AuthGate(auth: auth, profiles: profiles));
    await tester.pumpAndSettle();
    expect(find.textContaining('Unable to load your profile'), findsOneWidget);
    expect(find.text('Get started'), findsNothing);
    profiles.failLoad = false;
    await tester.tap(find.text('Retry'));
    await tester.pumpAndSettle();
    expect(find.byType(HomeScreen), findsOneWidget);
  });

  testWidgets('late previous-account read cannot restore private data', (
    tester,
  ) async {
    final pending = Completer<AdultProfile?>();
    profiles.pending['adult'] = pending;
    await tester.pumpWidget(AuthGate(auth: auth, profiles: profiles));
    await tester.pump();
    auth.emit('other');
    await tester.pumpAndSettle();
    pending.complete(adult);
    await tester.pumpAndSettle();
    expect(SessionStore.instance.parentName, isNot(adult.name));
    expect(find.text('Get started'), findsOneWidget);
  });

  testWidgets(
    'onboarding saves by UID and retries failures without losing input',
    (tester) async {
      await tester.pumpWidget(AuthGate(auth: auth, profiles: profiles));
      await tester.pumpAndSettle();
      await tester.scrollUntilVisible(find.text('Get started'), 300);
      await tester.tap(find.text('Get started'));
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextFormField), 'New adult');
      profiles.failSave = true;
      await tester.ensureVisible(find.text('Finish setup'));
      await tester.tap(find.text('Finish setup'));
      await tester.pumpAndSettle();
      expect(
        find.textContaining('Could not save your profile'),
        findsOneWidget,
      );
      expect(profiles.values, isEmpty);
      profiles.failSave = false;
      await tester.tap(find.text('Finish setup'));
      await tester.pumpAndSettle();
      expect(profiles.values['adult']!.name, 'New adult');
      expect(find.byType(HomeScreen), findsOneWidget);
    },
  );

  testWidgets('profile preference is committed only after a successful save', (
    tester,
  ) async {
    profiles.values['adult'] = adult;
    await tester.pumpWidget(AuthGate(auth: auth, profiles: profiles));
    await tester.pumpAndSettle();
    tester
        .state<NavigatorState>(find.byType(Navigator))
        .pushAndRemoveUntil(
          MaterialPageRoute<void>(builder: (_) => const ProfileScreen()),
          (_) => false,
        );
    await tester.pumpAndSettle();
    await tester.tap(find.text('Coordinator'));
    expect(SessionStore.instance.parentRole, BushelRole.volunteer);
    profiles.failSave = true;
    await tester.scrollUntilVisible(find.text('Use this mode'), 250);
    await tester.tap(find.text('Use this mode'));
    await tester.pumpAndSettle();
    expect(SessionStore.instance.parentRole, BushelRole.volunteer);
    expect(find.textContaining('Could not save your profile'), findsOneWidget);
    profiles.failSave = false;
    await tester.tap(find.text('Use this mode'));
    await tester.pumpAndSettle();
    expect(profiles.values['adult']!.role, BushelRole.coordinator);
    expect(SessionStore.instance.parentRole, BushelRole.coordinator);
    auth.emit(null);
    await tester.pumpAndSettle();
    expect(find.byType(AuthScreen), findsOneWidget);
  });

  testWidgets('late save after logout does not repopulate the session', (
    tester,
  ) async {
    profiles.values['adult'] = adult;
    profiles.saving = Completer<void>();
    await tester.pumpWidget(AuthGate(auth: auth, profiles: profiles));
    await tester.pumpAndSettle();
    tester
        .state<NavigatorState>(find.byType(Navigator))
        .push(MaterialPageRoute<void>(builder: (_) => const ProfileScreen()));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Coordinator'));
    await tester.scrollUntilVisible(find.text('Use this mode'), 250);
    await tester.tap(find.text('Use this mode'));
    await tester.pump();
    auth.emit(null);
    await tester.pumpAndSettle();
    profiles.saving!.complete();
    await tester.pumpAndSettle();
    expect(find.byType(AuthScreen), findsOneWidget);
    expect(SessionStore.instance.parentRole, BushelRole.volunteer);
    expect(SessionStore.instance.parentName, isNot(adult.name));
  });
}
