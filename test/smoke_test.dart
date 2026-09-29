// Only catastrophic-regression smoke checks. Feature QA belongs in
// docs/manual_testing.md; do not grow this into an exhaustive UI suite.
import 'dart:async';

import 'package:bushel/catalog_session.dart';
import 'package:bushel/data/catalog_store.dart';
import 'package:bushel/data/coordinator_store.dart';
import 'package:bushel/data/session_store.dart';
import 'package:bushel/data/shift_store.dart';
import 'package:bushel/demo_app.dart';
import 'package:bushel/firebase_bootstrap.dart';
import 'package:bushel/main.dart';
import 'package:bushel/models/food_bank.dart';
import 'package:bushel/models/attendance.dart';
import 'package:bushel/screens/check_in_screen.dart';
import 'package:bushel/screens/auth_screen.dart';
import 'package:bushel/screens/food_bank_detail_screen.dart';
import 'package:bushel/screens/home_screen.dart';
import 'package:bushel/screens/onboarding_screen.dart';
import 'package:bushel/services/auth_service.dart';
import 'package:bushel/services/catalog_repository.dart';
import 'package:bushel/services/community_models.dart';
import 'package:bushel/services/profile_service.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

// Fixtures only supply inputs. Unexpected calls fail instead of simulating
// backend persistence, voting, capacity, or authorization in a second codebase.
class _Auth implements AuthService {
  final changes = StreamController<String?>.broadcast();
  @override
  Stream<String?> get userIds => changes.stream;
  @override
  dynamic noSuchMethod(Invocation invocation) =>
      throw StateError('Unexpected auth call: ${invocation.memberName}');
}

class _Profiles implements ProfileRepository {
  final pending = Completer<AdultProfile?>();
  @override
  Future<AdultProfile?> load(String uid) async =>
      uid == 'old-adult' ? pending.future : null;
  @override
  dynamic noSuchMethod(Invocation invocation) =>
      throw StateError('Unexpected profile call: ${invocation.memberName}');
}

final _bank = FirestoreCatalogRepository.decodeBank('bank', {
  'name': 'Live bank',
  'shortName': 'Live bank',
  'description': 'Food bank',
  'address': 'Test street',
  'hours': '9 AM',
  'latitude': 29.76,
  'longitude': -95.37,
});

class _Catalog implements CatalogRepository {
  _Catalog({
    this.failBanks = false,
    this.kidMode = false,
    this.attendanceStream,
  });
  final Stream<List<AttendanceEntry>>? attendanceStream;
  @override
  Stream<List<AttendanceEntry>> watchAttendance(
    String uid, {
    bool asLeader = false,
  }) => attendanceStream ?? Stream.value([]);
  @override
  Stream<Map<String, String>> watchFeaturedBadges(String uid) =>
      Stream.value({});
  final bool failBanks;
  final bool kidMode;
  final access = StreamController<Set<String>>.broadcast();
  @override
  Stream<List<FoodBank>> watchBanks() =>
      failBanks ? Stream.error(StateError('offline')) : Stream.value([_bank]);
  @override
  Stream<List<StoredShift>> watchShifts() => Stream.value([
    for (final id in ['parent-shift', 'child-shift'])
      StoredShift(
        bankId: 'bank',
        creatorUid: 'leader',
        shift: FoodBankShift(
          id: id,
          title: id,
          scheduledDate: DateTime(2026, 10, 1),
          time: '9 AM',
          station: 'Packing',
          spotsLeft: 2,
        ),
      ),
  ]);
  @override
  Stream<Set<String>> watchSignups(String uid) =>
      Stream.value({'parent-shift', 'child-shift'});
  @override
  Stream<Set<String>> watchCoordinatorBanks(String uid) async* {
    yield <String>{};
    yield* access.stream;
  }

  @override
  Stream<Map<String, String>> watchApplications(String uid) =>
      Stream.value({'bank': 'pending'});
  @override
  Stream<FamilyData> watchFamily(String uid) => Stream.value(
    FamilyData(
      children: const {'kid': 'Sam'},
      activeChildId: kidMode ? 'kid' : '',
    ),
  );
  @override
  Stream<Map<String, Set<String>>> watchChildSignups(String uid) =>
      Stream.value({
        'child-shift': {'kid'},
      });
  @override
  dynamic noSuchMethod(Invocation invocation) =>
      throw StateError('Unexpected catalog call: ${invocation.memberName}');
}

void main() {
  AttendanceEntry entry(String person, String status, {String? badge}) =>
      AttendanceEntry(
        ownerUid: 'adult',
        participantId: person,
        shiftId: 'child-shift',
        leaderUid: 'leader',
        name: 'Sam',
        status: status,
        badgeId: badge,
      );
  setUp(() {
    SessionStore.instance.reset();
    CoordinatorStore.instance.reset();
    ShiftStore.instance.reset();
  });

  test('rewards exclude pending attendance and duplicate completions', () {
    final confirmed = entry('kid', 'confirmed', badge: 'bee');
    final rewards = AttendanceRewards([
      entry('other-kid', 'pending'),
      confirmed,
      confirmed,
      entry('parent', 'confirmed'),
    ]);
    expect(rewards.points('kid'), 100);
    expect(rewards.points('other-kid'), 0);
    expect(rewards.badges('kid'), {'bee'});
    expect(rewards.badges('parent'), isEmpty);
    expect(rewards.familyShifts, 1);
  });

  testWidgets(
    'live check-in survives attendance updates without awarding pending points',
    (tester) async {
      final updates = StreamController<List<AttendanceEntry>>();
      final repository = _Catalog(
        kidMode: true,
        attendanceStream: updates.stream,
      );
      addTearDown(updates.close);
      addTearDown(repository.access.close);
      await tester.pumpWidget(
        CatalogSession(
          uid: 'adult',
          repository: repository,
          child: const BushelApp(home: CheckInScreen()),
        ),
      );
      updates.add([]);
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      updates.add([entry('kid', 'pending')]);
      await tester.pumpAndSettle();
      expect(ShiftStore.instance.points, 0);
      expect(
        ShiftStore.instance.isAwaitingConfirmation(
          ShiftStore.instance.myShifts.single.shift,
        ),
        isTrue,
      );
      updates.add([entry('kid', 'confirmed')]);
      await tester.pumpAndSettle();
      expect(ShiftStore.instance.points, 100);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox());
    },
  );

  testWidgets('demo boots without Firebase and reset clears private state', (
    tester,
  ) async {
    await tester.pumpWidget(const DemoApp());
    expect(Firebase.apps, isEmpty);
    expect(find.byType(OnboardingScreen), findsOneWidget);
    SessionStore.instance.addChild('Private child');
    await tester.tap(find.text('Reset demo'));
    await tester.pumpAndSettle();
    expect(SessionStore.instance.children, isEmpty);
    expect(find.byType(OnboardingScreen), findsOneWidget);
  });

  testWidgets('Firebase startup failure cannot silently open the demo', (
    tester,
  ) async {
    await tester.pumpWidget(
      FirebaseBootstrap(initialize: () async => throw StateError('offline')),
    );
    await tester.pumpAndSettle();
    expect(find.text('Retry'), findsOneWidget);
    expect(find.byType(OnboardingScreen), findsNothing);
    expect(find.text('Local demo'), findsNothing);
  });

  testWidgets('logout removes private state and old navigation', (
    tester,
  ) async {
    final auth = _Auth();
    addTearDown(auth.changes.close);
    await tester.pumpWidget(
      AuthGate(auth: auth, signedInHome: const OnboardingScreen()),
    );
    auth.changes.add('adult');
    await tester.pumpAndSettle();
    SessionStore.instance.addChild('Private child');
    tester
        .state<NavigatorState>(find.byType(Navigator))
        .push(
          MaterialPageRoute<void>(
            builder: (_) => const Scaffold(body: Text('Private route')),
          ),
        );
    await tester.pumpAndSettle();
    auth.changes.add(null);
    await tester.pumpAndSettle();
    expect(find.byType(AuthScreen), findsOneWidget);
    expect(find.text('Private route'), findsNothing);
    expect(SessionStore.instance.children, isEmpty);
    expect(
      tester.state<NavigatorState>(find.byType(Navigator)).canPop(),
      isFalse,
    );
  });

  testWidgets('late profile response cannot leak a previous account', (
    tester,
  ) async {
    final auth = _Auth();
    final profiles = _Profiles();
    addTearDown(auth.changes.close);
    await tester.pumpWidget(AuthGate(auth: auth, profiles: profiles));
    auth.changes.add('old-adult');
    await tester.pump();
    auth.changes.add('new-adult');
    await tester.pumpAndSettle();
    profiles.pending.complete(
      const AdultProfile(
        name: 'Private name',
        role: BushelRole.coordinator,
        family: true,
      ),
    );
    await tester.pumpAndSettle();
    expect(SessionStore.instance.parentName, isNot('Private name'));
    expect(find.byType(OnboardingScreen), findsOneWidget);
  });

  testWidgets('live catalog failure never substitutes mock shifts', (
    tester,
  ) async {
    final repository = _Catalog(failBanks: true);
    addTearDown(repository.access.close);
    await tester.pumpWidget(
      CatalogSession(
        uid: 'adult',
        repository: repository,
        child: const BushelApp(home: HomeScreen(name: 'Adult')),
      ),
    );
    await tester.pumpAndSettle();
    expect(ShiftStore.instance.usingLive, isTrue);
    expect(ShiftStore.instance.available, isEmpty);
    expect(find.text('Second Harvest'), findsNothing);
  });

  testWidgets('coordinator preference cannot bypass application approval', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(1000, 1200));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    final repository = _Catalog();
    addTearDown(repository.access.close);
    SessionStore.instance.setRole(BushelRole.coordinator);
    await tester.pumpWidget(
      CatalogSession(
        uid: 'adult',
        repository: repository,
        child: BushelApp(home: FoodBankDetailScreen(foodBank: _bank)),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Add shift'), findsNothing);
    repository.access.add({'bank'});
    await tester.pumpAndSettle();
    expect(find.text('Add shift'), findsOneWidget);
  });

  testWidgets('Kid Mode uses child bookings and blocks independent signup', (
    tester,
  ) async {
    final repository = _Catalog(kidMode: true);
    addTearDown(repository.access.close);
    await tester.pumpWidget(
      CatalogSession(
        uid: 'adult',
        repository: repository,
        child: const BushelApp(home: HomeScreen(name: 'Adult')),
      ),
    );
    await tester.pumpAndSettle();
    final shifts = ShiftStore.instance;
    expect(shifts.usingLive, isTrue);
    expect(shifts.myShifts.map((entry) => entry.shift.id), ['child-shift']);
    final catalog = CatalogScope.maybeOf(
      tester.element(find.byType(HomeScreen)),
    )!;
    await expectLater(
      catalog.changeSignup(shifts.available.first.shift, true),
      throwsA(isA<CatalogException>()),
    );
  });
}
