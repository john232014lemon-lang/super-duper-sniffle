import 'dart:async';

import 'package:bushel/data/coordinator_store.dart';
import 'package:bushel/data/session_store.dart';
import 'package:bushel/data/shift_store.dart';
import 'package:bushel/firebase_bootstrap.dart';
import 'package:bushel/main.dart';
import 'package:bushel/screens/auth_screen.dart';
import 'package:bushel/screens/profile_screen.dart';
import 'package:bushel/services/auth_service.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

class FakeAuth implements AuthService {
  FakeAuth({this.uid});
  String? uid;
  final changes = StreamController<String?>.broadcast();
  Object? failure;
  int signIns = 0;
  int registrations = 0;
  String? submittedEmail;
  String? submittedPassword;

  @override
  Stream<String?> get userIds async* {
    yield uid;
    yield* changes.stream;
  }

  void emit(String? value) {
    uid = value;
    changes.add(value);
  }

  @override
  Future<void> signIn(String email, String password) async {
    signIns++;
    submittedEmail = email;
    submittedPassword = password;
    if (failure != null) throw failure!;
    emit('adult-1');
  }

  @override
  Future<void> register(String email, String password) async {
    registrations++;
    submittedEmail = email;
    submittedPassword = password;
    if (failure != null) throw failure!;
    emit('adult-1');
  }

  @override
  Future<void> signOut() async {
    if (failure != null) throw failure!;
    emit(null);
  }
}

void main() {
  late FakeAuth auth;
  setUp(() {
    auth = FakeAuth();
    SessionStore.instance.reset();
    CoordinatorStore.instance.reset();
    ShiftStore.instance.reset();
  });
  tearDown(() async => auth.changes.close());

  testWidgets('startup failure has retry and never opens mock onboarding', (
    tester,
  ) async {
    var attempts = 0;
    await tester.pumpWidget(
      FirebaseBootstrap(
        initialize: () async {
          if (attempts++ == 0) throw StateError('Missing configuration');
          return auth;
        },
      ),
    );
    await tester.pumpAndSettle();
    expect(
      find.textContaining('could not connect to Firebase'),
      findsOneWidget,
    );
    expect(find.text('Get started'), findsNothing);
    await tester.tap(find.text('Retry'));
    await tester.pumpAndSettle();
    expect(find.text('Sign in'), findsOneWidget);
  });

  testWidgets('login validates input and reports invalid credentials', (
    tester,
  ) async {
    auth.failure = FirebaseAuthException(code: 'invalid-credential');
    await tester.pumpWidget(BushelApp(home: AuthScreen(auth: auth)));
    await tester.tap(find.text('Sign in'));
    await tester.pumpAndSettle();
    expect(auth.signIns, 0);
    expect(find.text('Enter a valid email address.'), findsOneWidget);
    await tester.enterText(
      find.byType(TextFormField).at(0),
      ' adult@example.com ',
    );
    await tester.enterText(find.byType(TextFormField).at(1), 'wrong-password');
    await tester.tap(find.text('Sign in'));
    await tester.pumpAndSettle();
    expect(auth.submittedEmail, 'adult@example.com');
    expect(find.text('Email or password is incorrect.'), findsOneWidget);
    expect(find.text('Get started'), findsNothing);
  });

  testWidgets('registration validates password then opens adult onboarding', (
    tester,
  ) async {
    await tester.pumpWidget(AuthGate(auth: auth));
    await tester.pumpAndSettle();
    await tester.tap(find.text('New to Bushel? Create an account'));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byType(TextFormField).at(0),
      'adult@example.com',
    );
    await tester.enterText(find.byType(TextFormField).at(1), '123');
    await tester.tap(find.text('Create account'));
    await tester.pumpAndSettle();
    expect(auth.registrations, 0);
    expect(find.text('Use at least 6 characters.'), findsOneWidget);
    await tester.enterText(find.byType(TextFormField).at(1), 'secret-password');
    await tester.tap(find.text('Create account'));
    await tester.pumpAndSettle();
    expect(auth.registrations, 1);
    expect(auth.submittedPassword, 'secret-password');
    expect(find.text('Get started'), findsOneWidget);
    expect(find.byType(AuthScreen), findsNothing);
  });

  testWidgets(
    'restored session skips login; logout clears routes and mock data',
    (tester) async {
      auth.uid = 'restored-adult';
      await tester.pumpWidget(AuthGate(auth: auth));
      await tester.pumpAndSettle();
      expect(find.text('Get started'), findsOneWidget);
      expect(find.text('Sign in'), findsNothing);

      final session = SessionStore.instance;
      session.configureParent(
        name: 'Private parent',
        role: BushelRole.coordinator,
        family: true,
      );
      session.addChild('Private child');
      session.addChallenge('Private challenge');
      session.unlockKidBadge('bunny');
      final shifts = ShiftStore.instance;
      final shift = shifts.myShifts.first.shift;
      shifts.generateQrCode(shift);
      shifts.checkIn(shift);
      shifts.confirmAttendance(shift, 'parent');
      expect(shifts.points, 100);
      CoordinatorStore.instance.voteToRemove('riley');

      final navigator = tester.state<NavigatorState>(find.byType(Navigator));
      navigator.push(
        MaterialPageRoute<void>(builder: (_) => const ProfileScreen()),
      );
      await tester.pumpAndSettle();
      await tester.scrollUntilVisible(find.text('Sign out'), 250);
      await tester.tap(find.text('Sign out'));
      await tester.pumpAndSettle();
      expect(find.byType(AuthScreen), findsOneWidget);
      expect(find.byType(ProfileScreen), findsNothing);
      expect(
        tester.state<NavigatorState>(find.byType(Navigator)).canPop(),
        isFalse,
      );
      expect(session.children, isEmpty);
      expect(session.challenges, hasLength(3));
      expect(session.unlockedKidBadges, isEmpty);
      expect(session.familyAccount, isFalse);
      expect(shifts.points, 0);
      expect(shifts.qrCodeFor(shift), isNull);
      expect(CoordinatorStore.instance.hasVotedFor('riley'), isFalse);

      auth.emit('different-adult');
      await tester.pumpAndSettle();
      expect(find.text('Get started'), findsOneWidget);
      expect(find.text('Private parent'), findsNothing);
    },
  );

  testWidgets(
    'failed logout keeps signed-in routes and shows retryable error',
    (tester) async {
      auth.uid = 'adult';
      await tester.pumpWidget(AuthGate(auth: auth));
      await tester.pumpAndSettle();
      tester
          .state<NavigatorState>(find.byType(Navigator))
          .push(MaterialPageRoute<void>(builder: (_) => const ProfileScreen()));
      await tester.pumpAndSettle();
      auth.failure = FirebaseAuthException(code: 'network-request-failed');
      await tester.scrollUntilVisible(find.text('Sign out'), 250);
      await tester.tap(find.text('Sign out'));
      await tester.pumpAndSettle();
      expect(find.byType(ProfileScreen), findsOneWidget);
      expect(find.text('Check your connection and try again.'), findsOneWidget);
      expect(find.text('Sign out'), findsOneWidget);
    },
  );
}
