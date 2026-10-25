// Only catastrophic-regression smoke checks. Feature QA belongs in
// docs/manual_testing.md; do not grow this into an exhaustive UI suite.
import 'dart:async';

import 'package:bushel/catalog_session.dart';
import 'package:bushel/data/catalog_store.dart';
import 'package:bushel/data/coordinator_store.dart';
import 'package:bushel/data/session_store.dart';
import 'package:bushel/data/shift_store.dart';
import 'package:bushel/demo_app.dart';
import 'package:bushel/demo_config.dart';
import 'package:bushel/firebase_bootstrap.dart';
import 'package:bushel/main.dart';
import 'package:bushel/models/food_bank.dart';
import 'package:bushel/models/attendance.dart';
import 'package:bushel/models/shift_schedule.dart';
import 'package:bushel/models/check_in_token.dart';
import 'package:bushel/screens/attendance_management_screen.dart';
import 'package:bushel/screens/check_in_screen.dart';
import 'package:bushel/data/mock_qr_presentation_store.dart';
import 'package:bushel/screens/camera_scan_screen.dart';
import 'package:bushel/screens/mock_camera_scan_screen.dart';
import 'package:bushel/widgets/station_qr_code.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:bushel/screens/shifts_screen.dart';
import 'package:bushel/screens/live_group_screen.dart';
import 'package:bushel/widgets/family_shift_bookings.dart';
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
import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';

// Fixtures only supply inputs. Unexpected calls fail instead of simulating
// backend persistence, voting, capacity, or authorization in a second codebase.
class _Auth implements AuthService {
  final changes = StreamController<String?>.broadcast();
  @override
  Stream<String?> get userIds => changes.stream;
  @override
  String? get currentEmail => null;
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
  (String, String, String, bool)? childRequest;
  @override
  Future<void> setChildSignup(
    String uid,
    String shiftId,
    String childId,
    bool join,
  ) async {
    childRequest = (uid, shiftId, childId, join);
  }

  @override
  Stream<String> watchCoordinatorPhone(String uid) => Stream.value('');
  @override
  Stream<ShiftGroup> watchGroup(String shiftId) =>
      Stream.value(const ShiftGroup(members: {'adult': 'Adult'}, version: 1));
  @override
  Stream<Map<String, RemovalVote>> watchVotes(String shiftId) =>
      Stream.value({});
  _Catalog({
    this.failBanks = false,
    this.kidMode = false,
    this.attendanceStream,
    this.signupStream,
    this.leaderAttendanceStream,
  });
  final Stream<List<AttendanceEntry>>? attendanceStream;
  final Stream<Set<String>>? signupStream;
  final Stream<List<AttendanceEntry>>? leaderAttendanceStream;
  @override
  Stream<List<AttendanceEntry>> watchAttendance(
    String uid, {
    bool asLeader = false,
  }) =>
      (asLeader ? leaderAttendanceStream : attendanceStream) ??
      Stream.value([]);
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
      signupStream ?? Stream.value({'parent-shift', 'child-shift'});
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

class _MockQrCatalog extends _Catalog {
  Stream<List<AttendanceEntry>>? entries;
  (String, String, String, String)? request;
  @override
  Stream<List<AttendanceEntry>> watchAttendance(
    String uid, {
    bool asLeader = false,
  }) => entries!;
  @override
  Future<bool> submitAttendance(
    String uid,
    String participantId,
    String shiftId,
    String name,
    String code,
  ) async {
    request = (uid, participantId, shiftId, code);
    return false;
  }
}

void main() {
  testWidgets('camera QR manual fallback uses pending attendance path', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(900, 1200);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final session = SessionStore.instance;
    final store = ShiftStore.instance;
    session.setRole(BushelRole.coordinator);
    final listing = store.available.first;
    final code = store.generateQrCode(listing.shift)!;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(body: StationQrCode(code: code)),
      ),
    );
    expect(find.byType(QrImageView), findsOneWidget);
    expect(tester.takeException(), isNull);
    session.setRole(BushelRole.volunteer);
    await tester.pumpWidget(const BushelApp(home: CheckInScreen()));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), code);
    await tester.tap(find.text('Use entered code'));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('Confirm station check-in'));
    await tester.tap(find.text('Confirm station check-in'));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(FilledButton, 'Check in'));
    await tester.pumpAndSettle();
    expect(store.pendingAttendance(listing.shift), hasLength(1));
    expect(store.points, 0);
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets(
    'camera QR Kid Mode cannot scan and unsupported camera has fallback',
    (tester) async {
      SessionStore.instance.addChild('Child');
      SessionStore.instance.switchToChild(
        SessionStore.instance.children.single.id,
      );
      await tester.pumpWidget(const BushelApp(home: CheckInScreen()));
      expect(find.text('Scan QR with camera'), findsNothing);
      expect(find.byType(TextField), findsNothing);
      await tester.pumpWidget(const MaterialApp(home: CameraScanScreen()));
      expect(find.byType(MobileScanner), findsNothing);
      expect(find.text('Enter code instead'), findsNothing);
      SessionStore.instance.switchToParent();
      // Widget tests default to Android. Explicitly use an unsupported platform
      // to check the fallback without touching a camera or platform channel.
      debugDefaultTargetPlatformOverride = TargetPlatform.windows;
      addTearDown(() => debugDefaultTargetPlatformOverride = null);
      await tester.pumpAndSettle();
      expect(find.byType(MobileScanner), findsNothing);
      expect(find.text('Enter code instead'), findsOneWidget);
      await tester.pumpWidget(const SizedBox());
      debugDefaultTargetPlatformOverride = null;
    },
  );

  test(
    'secure QR rejects expired rotated wrong-shift and public-hash codes',
    () {
      final start = DateTime(2026, 10, 12, 12);
      final token = CheckInToken.generate('shift', start, now: start);
      final next = CheckInToken.generate('shift', start, now: start);
      String? validate(
        String code, {
        String sid = 'shift',
        String? hash,
        DateTime? now,
      }) => CheckInToken.validate(
        code,
        sid,
        hash ?? CheckInToken.verifier(token.code),
        token.expiresAt,
        start,
        now: now ?? start,
      );
      expect(validate(token.code), isNull);
      expect(validate(token.code, now: token.expiresAt), contains('expired'));
      expect(validate(token.code, sid: 'other'), contains('another shift'));
      expect(
        validate(token.code, hash: CheckInToken.verifier(next.code)),
        contains('rotated'),
      );
      expect(
        validate('BUSHEL1:shift:${CheckInToken.verifier(token.code)}'),
        isNotNull,
      );
      expect(
        CheckInToken.digest('abc'),
        'ba7816bf8f01cfea414140de5dae2223b00361a396177a9cb410ff61f20015ad',
      );
    },
  );

  test(
    'secure QR demo denies nonmembers kids and repeated attendance',
    () async {
      final session = SessionStore.instance;
      final store = ShiftStore.instance;
      session.setRole(BushelRole.coordinator);
      final listing = store.available.first;
      final code = store.generateQrCode(listing.shift)!;
      session.setRole(BushelRole.volunteer);
      expect(store.qrCodeFor(listing.shift), isNull);
      await store.cancelSignup(listing.shift);
      await expectLater(
        store.submitCheckIn(listing.shift, code),
        throwsA(isA<CatalogException>()),
      );
      await store.signUp(listing.foodBank, listing.shift);
      session.addChild('Child');
      session.switchToChild(session.children.single.id);
      await expectLater(
        store.submitCheckIn(listing.shift, code),
        throwsA(isA<CatalogException>()),
      );
      session.switchToParent();
      expect(await store.submitCheckIn(listing.shift, code), isTrue);
      expect(store.points, 0);
      await expectLater(
        store.submitCheckIn(listing.shift, code),
        throwsA(isA<CatalogException>()),
      );
      expect(store.pendingAttendance(listing.shift), hasLength(1));
    },
  );

  test('mock QR tokens stay separate and reject invalid proofs', () {
    final now = DateTime(2026, 10, 23, 12);
    final token = CheckInToken.generateMock('shift', now: now);
    final rotated = CheckInToken.generateMock('shift', now: now);
    String? validate(
      String code, {
      String sid = 'shift',
      String? hash,
      DateTime? at,
    }) => CheckInToken.validateMock(
      code,
      sid,
      hash ?? CheckInToken.verifier(token.code),
      token.expiresAt,
      now: at ?? now,
    );
    expect(validate(token.code), isNull);
    expect(validate(token.code, sid: 'other'), isNotNull);
    expect(validate(token.code, at: token.expiresAt), isNotNull);
    expect(
      validate(token.code, hash: CheckInToken.verifier(rotated.code)),
      isNotNull,
    );
    expect(
      validate(token.code.replaceFirst('BUSHELMOCK:', 'BUSHEL1:')),
      isNotNull,
    );
    expect(
      validate('BUSHELMOCK:shift:${CheckInToken.verifier(token.code)}'),
      isNotNull,
    );
    expect(
      CheckInToken.validate(
        token.code,
        'shift',
        CheckInToken.verifier(token.code),
        token.expiresAt,
        now,
        now: now,
      ),
      isNotNull,
    );
  });

  testWidgets(
    'mock QR uses live catalog and denies child and coordinator redemption',
    (tester) async {
      expect(demoMode, isFalse);
      final repository = _MockQrCatalog();
      final attendance = StreamController<List<AttendanceEntry>>();
      repository.entries = attendance.stream;
      addTearDown(attendance.close);
      addTearDown(repository.access.close);
      await tester.pumpWidget(
        CatalogSession(
          uid: 'adult',
          repository: repository,
          child: const BushelApp(home: Scaffold()),
        ),
      );
      attendance.add([]);
      await tester.pumpAndSettle();
      final store = ShiftStore.instance;
      final session = SessionStore.instance;
      expect(store.usingLive, isTrue);
      expect(store.usingMockQr, isTrue);
      expect(store.available.first.foodBank.name, 'Live bank');
      final shift = store.myShifts.first.shift;
      session.setRole(BushelRole.coordinator);
      await expectLater(
        store.submitCheckIn(shift, 'code'),
        throwsA(isA<CatalogException>()),
      );
      session.setRole(BushelRole.volunteer);
      await expectLater(
        store.submitCheckIn(shift, 'code', participantId: 'kid'),
        throwsA(isA<CatalogException>()),
      );
      session.switchToChild('kid');
      await expectLater(
        store.submitCheckIn(shift, 'code'),
        throwsA(isA<CatalogException>()),
      );
      expect(repository.request, isNull);
      session.switchToParent();
      expect(await store.submitCheckIn(shift, 'code'), isTrue);
      expect(repository.request, ('adult', 'parent', shift.id, 'code'));
      expect(store.lastCheckInConfirmed, isFalse);
      expect(store.points, 0);
      attendance.add([
        AttendanceEntry(
          ownerUid: 'adult',
          participantId: 'parent',
          shiftId: shift.id!,
          leaderUid: 'leader',
          name: 'Adult',
          status: 'confirmed',
        ),
      ]);
      await tester.pumpAndSettle();
      expect(store.points, 100);
      await tester.pumpWidget(const SizedBox());
    },
    skip: !mockQrMode,
  );

  testWidgets(
    'mock camera shows session QR and scan returns the code',
    (tester) async {
      expect(mockQrMode, isTrue);
      await tester.binding.setSurfaceSize(const Size(800, 1200));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      final now = DateTime(2026, 10, 24, 12);
      final token = CheckInToken.generateMock('demo-shift', now: now);
      MockQrPresentationStore.instance.remember('demo-shift', token);
      addTearDown(MockQrPresentationStore.instance.clear);
      String? scanned;
      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) => Scaffold(
              body: TextButton(
                onPressed: () async {
                  scanned = await Navigator.of(context).push<String>(
                    MaterialPageRoute(
                      builder: (_) =>
                          const MockCameraScanScreen(shiftId: 'demo-shift'),
                    ),
                  );
                },
                child: const Text('Open mock camera'),
              ),
            ),
          ),
        ),
      );
      await tester.tap(find.text('Open mock camera'));
      await tester.pumpAndSettle();
      expect(find.byType(MobileScanner), findsNothing);
      expect(find.byType(QrImageView), findsOneWidget);
      expect(find.text('Scan this QR'), findsOneWidget);
      await tester.tap(find.text('Scan this QR'));
      await tester.pumpAndSettle();
      expect(scanned, token.code);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox());
    },
    skip: !mockQrMode,
  );

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

  testWidgets(
    'parent can leave one child booking and missing contact stays explicit',
    (tester) async {
      final repository = _Catalog();
      addTearDown(repository.access.close);
      await tester.pumpWidget(
        CatalogSession(
          uid: 'adult',
          repository: repository,
          child: const BushelApp(
            home: Scaffold(
              body: SingleChildScrollView(child: FamilyShiftBookings()),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('Coordinator: no number provided'), findsOneWidget);
      expect(find.text('Sign up for shift'), findsOneWidget);
      await tester.tap(find.text('Leave shift for Sam'));
      await tester.pumpAndSettle();
      expect(repository.childRequest, ('adult', 'child-shift', 'kid', false));
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox());
    },
  );

  testWidgets('My shifts exposes groups beyond the selected calendar date', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(1000, 1200));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    final repository = _Catalog();
    addTearDown(repository.access.close);
    await tester.pumpWidget(
      CatalogSession(
        uid: 'adult',
        repository: repository,
        child: BushelApp(
          home: ShiftsScreen(showMyShifts: true, initialDate: DateTime(2030)),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('View group & members'), findsNWidgets(2));
    await tester.tap(find.text('View group & members').first);
    await tester.pumpAndSettle();
    expect(find.byType(LiveGroupScreen), findsOneWidget);
    expect(
      find.textContaining('Removal voting needs at least 3 adults'),
      findsOneWidget,
    );
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox());
  });

  test('group child members are listable and vote targets parse', () {
    const group = ShiftGroup(
      members: {'adult-a': 'Alex', 'adult-b': 'Blair', 'adult-c': 'Casey'},
      childMembers: {
        'adult-a': {'child-1': 'Sam'},
      },
      version: 2,
    );
    expect(group.votesNeeded, 2);
    expect(group.childList.single.name, 'Sam');
    expect(
      group.childList.single.target,
      ShiftGroup.childVoteTarget('adult-a', 'child-1'),
    );
    expect(
      ShiftGroup.parseChildVoteTarget('adult-a::child-1'),
      ('adult-a', 'child-1'),
    );
    expect(ShiftGroup.parseChildVoteTarget('adult-a'), isNull);
  });

  test('demo members can vote kids out before check-in', () {
    SessionStore.instance.reset();
    CoordinatorStore.instance.reset();
    SessionStore.instance.configureParent(
      name: 'Maya',
      role: BushelRole.volunteer,
      family: true,
    );
    SessionStore.instance.addChild('Jordan');
    CoordinatorStore.instance.addFamilyChild(
      SessionStore.instance.children.single,
    );
    expect(CoordinatorStore.instance.canVoteFor('parent'), isFalse);
    expect(CoordinatorStore.instance.canVoteFor('riley'), isTrue);
    expect(
      CoordinatorStore.instance.canVoteFor(
        SessionStore.instance.children.single.id,
      ),
      isFalse,
    );
    final kidId = SessionStore.instance.children.single.id;
    SessionStore.instance.reset();
    SessionStore.instance.configureParent(
      name: 'Other adult',
      role: BushelRole.volunteer,
      family: false,
    );
    expect(CoordinatorStore.instance.canVoteFor(kidId), isTrue);
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

  test('removed family attendance loses points and claimed badges', () {
    final rewards = AttendanceRewards([
      entry('parent', 'confirmed').revoke(),
      entry('kid', 'confirmed', badge: 'bee').revoke(),
      entry('other-kid', 'confirmed', badge: 'frog'),
    ]);
    expect(rewards.points('parent'), 0);
    expect(rewards.points('kid'), 0);
    expect(rewards.badges('kid'), isEmpty);
    expect(rewards.points('other-kid'), 100);
    expect(rewards.badges('other-kid'), {'frog'});
  });

  test('new shifts reject invalid times and out-of-window starts', () {
    final now = DateTime(2026, 9, 28, 12, 30, 45);
    expect(ShiftSchedule.validate(now, '12:30', now: now), isNull);
    expect(ShiftSchedule.validate(now, '12:29', now: now), isNotNull);
    expect(ShiftSchedule.validate(now, '00:59', now: now), isNotNull);
    expect(ShiftSchedule.validate(now, '24:01', now: now), isNotNull);
    expect(ShiftSchedule.minutes('24:00'), isNull);
    expect(ShiftSchedule.normalize('0:00'), '00:00');
    expect(ShiftSchedule.minutes('23:59'), 1439);
    expect(
      ShiftSchedule.validate(
        now.add(const Duration(days: 1)),
        '0:00',
        now: now,
      ),
      isNull,
    );
    expect(
      ShiftSchedule.validate(
        now.add(const Duration(days: 366)),
        '12:30',
        now: now,
      ),
      isNotNull,
    );
  });

  testWidgets('leader QR remains available when attendance query fails', (
    tester,
  ) async {
    final repository = _Catalog(
      leaderAttendanceStream: Stream<List<AttendanceEntry>>.error(
        StateError('missing index'),
      ),
    );
    addTearDown(repository.access.close);
    await tester.pumpWidget(
      CatalogSession(
        uid: 'leader',
        repository: repository,
        child: const BushelApp(
          home: AttendanceManagementScreen(
            shiftId: 'parent-shift',
            title: 'Shift',
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    repository.access.add({'bank'});
    await tester.pumpAndSettle();
    expect(find.text('Generate shift QR'), findsOneWidget);
    expect(find.text('Retry check-ins'), findsOneWidget);
    expect(
      tester
          .widget<FilledButton>(
            find.widgetWithText(FilledButton, 'Generate shift QR'),
          )
          .onPressed,
      isNotNull,
    );
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets(
    'live check-in survives attendance updates without awarding pending points',
    (tester) async {
      final updates = StreamController<List<AttendanceEntry>>();
      final bookings = StreamController<Set<String>>();
      final repository = _Catalog(
        attendanceStream: updates.stream,
        signupStream: bookings.stream,
      );
      addTearDown(updates.close);
      addTearDown(bookings.close);
      addTearDown(repository.access.close);
      await tester.pumpWidget(
        CatalogSession(
          uid: 'adult',
          repository: repository,
          child: const BushelApp(home: CheckInScreen()),
        ),
      );
      updates.add([]);
      bookings.add({'parent-shift', 'child-shift'});
      await tester.pumpAndSettle();
      expect(find.byType(DropdownButtonFormField<Object>), findsOneWidget);
      expect(tester.takeException(), isNull);
      bookings.add({});
      await tester.pumpAndSettle();
      expect(find.byType(DropdownButtonFormField<Object>), findsNothing);
      expect(tester.takeException(), isNull);
      bookings.add({'child-shift'});
      await tester.pumpAndSettle();
      expect(find.byType(DropdownButtonFormField<Object>), findsOneWidget);
      updates.add([entry('parent', 'pending')]);
      await tester.pumpAndSettle();
      expect(ShiftStore.instance.points, 0);
      expect(
        ShiftStore.instance.isAwaitingConfirmation(
          ShiftStore.instance.myShifts.single.shift,
        ),
        isTrue,
      );
      updates.add([entry('parent', 'confirmed')]);
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
    await expectLater(
      shifts.cancelSignup(shifts.myShifts.single.shift),
      throwsA(isA<CatalogException>()),
    );
    await expectLater(
      shifts.setChildBooking(shifts.myShifts.single, 'kid', false),
      throwsA(isA<CatalogException>()),
    );
    await tester.pumpWidget(
      CatalogSession(
        uid: 'adult',
        repository: repository,
        child: const BushelApp(home: ShiftsScreen(showMyShifts: true)),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Leave shift'), findsNothing);
    expect(find.text('Sign up for shift'), findsNothing);
    await tester.pumpWidget(const SizedBox());
  });
}
