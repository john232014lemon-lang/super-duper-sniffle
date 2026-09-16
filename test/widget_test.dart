import 'package:bushel/main.dart';
import 'package:bushel/data/shift_store.dart';
import 'package:bushel/data/session_store.dart';
import 'package:bushel/data/coordinator_store.dart';
import 'package:bushel/models/kid_badge.dart';
import 'package:bushel/models/reward_badge.dart';
import 'package:bushel/screens/check_in_screen.dart';
import 'package:bushel/screens/coordinator_screen.dart';
import 'package:bushel/screens/food_bank_map_screen.dart';
import 'package:bushel/screens/family_center_screen.dart';
import 'package:bushel/screens/home_screen.dart';
import 'package:bushel/screens/onboarding_screen.dart';
import 'package:bushel/screens/rewards_screen.dart';
import 'package:bushel/screens/shifts_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('app starts with signup', (WidgetTester tester) async {
    await tester.pumpWidget(const BushelApp());

    expect(find.text('Get started'), findsOneWidget);
    expect(find.byKey(const ValueKey('home')), findsNothing);
  });

  test('Kid Mode provides exactly 25 unique badges', () {
    expect(kidBadges, hasLength(25));
    expect(kidBadges.map((badge) => badge.id).toSet(), hasLength(25));
    expect(kidBadges.map((badge) => badge.name), contains('Donkey Badge'));
    expect(kidBadges.map((badge) => badge.name), contains('Carrot Badge'));
    expect(kidBadges.map((badge) => badge.name), contains('Bunny Badge'));
  });

  test('reward badge thresholds unlock at the required points', () {
    expect(rewardBadges[0].isUnlockedAt(499), isFalse);
    expect(rewardBadges[0].isUnlockedAt(500), isTrue);
    expect(rewardBadges[1].isUnlockedAt(1999), isFalse);
    expect(rewardBadges[1].isUnlockedAt(2000), isTrue);
    expect(rewardBadges[2].isUnlockedAt(9999), isFalse);
    expect(rewardBadges[2].isUnlockedAt(10000), isTrue);
  });

  test('parent creates and switches to a kid account', () {
    final session = SessionStore.instance;
    session.configureParent(
      name: 'Maya',
      role: BushelRole.volunteer,
      family: true,
    );
    session.addChild('Jamie');
    session.switchToChild(session.children.last.id);
    expect(session.userName, 'Jamie');
    expect(session.role, BushelRole.kid);
    session.switchToParent();
    expect(session.userName, 'Maya');
    expect(session.role, BushelRole.volunteer);
  });

  testWidgets('completes volunteer onboarding', (WidgetTester tester) async {
    await tester.pumpWidget(const MaterialApp(home: OnboardingScreen()));

    expect(find.text('One app for\nevery food bank.'), findsOneWidget);
    expect(find.text('The community food bank network'), findsOneWidget);

    await tester.ensureVisible(find.text('Get started'));
    await tester.tap(find.text('Get started'));
    await tester.pumpAndSettle();

    expect(find.text('Welcome to Bushel'), findsOneWidget);
    await tester.enterText(find.byType(EditableText), 'Sam');
    await tester.ensureVisible(find.text('Finish setup'));
    await tester.tap(find.text('Finish setup'));
    await tester.pumpAndSettle();

    expect(find.text('Hi, Sam 🌱'), findsOneWidget);
    expect(find.text('Sorting & Packing Line'), findsOneWidget);
    expect(find.text('Food banks near you'), findsOneWidget);
  });

  testWidgets('opens a food bank detail with shifts and recommendations', (
    WidgetTester tester,
  ) async {
    SessionStore.instance.configureParent(
      name: 'Sam',
      role: BushelRole.volunteer,
      family: false,
    );
    await tester.pumpWidget(const MaterialApp(home: HomeScreen(name: 'Sam')));

    await tester.drag(find.byType(CustomScrollView), const Offset(0, -220));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('Second Harvest'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Second Harvest'));
    await tester.pumpAndSettle();

    expect(find.text('About this food bank'), findsOneWidget);
    await tester.scrollUntilVisible(
      find.text('Upcoming shifts'),
      250,
      scrollable: find.byType(Scrollable).first,
    );
    expect(find.text('Upcoming shifts'), findsOneWidget);
    expect(find.text('Add shift'), findsNothing);
    expect(find.text('Sorting & Packing Line'), findsOneWidget);
    await tester.scrollUntilVisible(
      find.text('Recommended food banks'),
      300,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.scrollUntilVisible(
      find.text('Martha’s Kitchen'),
      200,
      scrollable: find.byType(Scrollable).first,
    );
    expect(find.text('Martha’s Kitchen'), findsOneWidget);
  });

  testWidgets('requires a name', (WidgetTester tester) async {
    await tester.pumpWidget(const MaterialApp(home: OnboardingScreen()));
    await tester.ensureVisible(find.text('Get started'));
    await tester.tap(find.text('Get started'));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('Finish setup'));
    await tester.tap(find.text('Finish setup'));
    await tester.pump();

    expect(find.text('Enter your name to continue'), findsOneWidget);
  });

  testWidgets('adds a custom shift to the sideways shift list', (
    WidgetTester tester,
  ) async {
    SessionStore.instance.configureParent(
      name: 'Casey',
      role: BushelRole.coordinator,
      family: false,
    );
    await tester.pumpWidget(const MaterialApp(home: HomeScreen(name: 'Casey')));
    await tester.drag(find.byType(CustomScrollView), const Offset(0, -220));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('Second Harvest'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Second Harvest'));
    await tester.pumpAndSettle();

    await tester.scrollUntilVisible(
      find.text('Add shift'),
      250,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.tap(find.text('Add shift'));
    await tester.pumpAndSettle();
    final fields = find.byType(TextFormField);
    await tester.enterText(fields.at(0), 'Garden Pickup');
    await tester.enterText(fields.at(1), 'Sat, Jun 27');
    await tester.enterText(fields.at(2), '9:00–11:00 AM');
    await tester.enterText(fields.at(3), 'Loading Bay B');
    await tester.enterText(fields.at(4), '4');
    await tester.tap(find.widgetWithText(FilledButton, 'Add shift').last);
    await tester.pumpAndSettle();

    final carousel = find.byKey(const ValueKey('shift-carousel'));
    await tester.ensureVisible(carousel);
    await tester.dragFrom(const Offset(400, 500), const Offset(0, -220));
    await tester.pumpAndSettle();
    await tester.drag(carousel, const Offset(-700, 0));
    await tester.pumpAndSettle();
    expect(find.text('Garden Pickup'), findsOneWidget);
  });

  testWidgets('confirms signup and adds the shift to My shifts', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(key: UniqueKey(), home: const ShiftsScreen()),
    );

    await tester.drag(find.byType(ListView), const Offset(0, -300));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Sign up').first);
    await tester.pumpAndSettle();
    expect(find.text('Confirm this shift?'), findsOneWidget);
    await tester.tap(find.text('Confirm signup'));
    await tester.pumpAndSettle();

    expect(find.text('Shift added to My shifts.'), findsOneWidget);
    await tester.drag(find.byType(ListView), const Offset(0, 300));
    await tester.pumpAndSettle();
    await tester.tap(find.textContaining('My shifts').first);
    await tester.pumpAndSettle();
    expect(find.text('Your upcoming shifts'), findsOneWidget);
    expect(find.text('Sorting & Packing Line'), findsOneWidget);
  });

  testWidgets('map marker opens a bank preview and details', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const MaterialApp(home: FoodBankMapScreen()));

    expect(find.text('Food banks nearby'), findsOneWidget);
    expect(find.text('Houston, TX'), findsOneWidget);
    expect(find.byTooltip('Find my location'), findsOneWidget);
    expect(find.text('MAP KEY'), findsOneWidget);
    expect(find.text('Martha’s Kitchen'), findsOneWidget);
    expect(find.byType(NavigationBar), findsOneWidget);
    await tester.tap(find.bySemanticsLabel('Second Harvest map marker'));
    await tester.pumpAndSettle();

    expect(find.text('Second Harvest'), findsWidgets);
    await tester.tap(find.text('View'));
    await tester.pumpAndSettle();
    expect(find.text('About this food bank'), findsOneWidget);
    expect(find.byType(NavigationBar), findsOneWidget);
  });

  testWidgets(
    'shift QR creates provisional check-in until coordinator confirms',
    (WidgetTester tester) async {
      final store = ShiftStore.instance;
      final session = SessionStore.instance;
      final listing = store.available.first;
      session.configureParent(
        name: 'Morgan',
        role: BushelRole.coordinator,
        family: false,
      );
      expect(store.generateQrCode(listing.shift), isNotNull);
      session.configureParent(
        name: 'Morgan',
        role: BushelRole.volunteer,
        family: false,
      );

      await tester.pumpWidget(const MaterialApp(home: CheckInScreen()));
      await tester.drag(find.byType(ListView), const Offset(0, -320));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('simulate-scan')));
      await tester.pumpAndSettle();
      expect(find.textContaining('Shift matched:'), findsOneWidget);
      await tester.tap(find.text('Confirm station check-in'));
      await tester.pumpAndSettle();
      expect(find.text('Confirm check-in?'), findsOneWidget);
      await tester.tap(find.widgetWithText(FilledButton, 'Check in'));
      await tester.pumpAndSettle();

      expect(find.text('Check-in sent!'), findsOneWidget);
      expect(store.isAwaitingConfirmation(listing.shift), isTrue);
      expect(store.isCheckedIn(listing.shift), isFalse);
      expect(store.points, 0);
      await tester.tap(find.text('Done'));
      await tester.pumpAndSettle();

      session.setRole(BushelRole.coordinator);
      await tester.pumpWidget(
        MaterialApp(key: UniqueKey(), home: const GroupDetailScreen()),
      );
      await tester.pumpAndSettle();
      expect(find.text('Morgan'), findsWidgets);
      await tester.tap(find.byKey(const ValueKey('confirm-parent')));
      await tester.pumpAndSettle();
      expect(store.isCheckedIn(listing.shift), isTrue);
      expect(store.points, 100);
    },
  );

  testWidgets('persistent Home navigation rebuilds the home destination', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const MaterialApp(home: ShiftsScreen()));
    await tester.tap(find.text('Home'));
    await tester.pumpAndSettle();

    expect(find.byKey(const ValueKey('home')), findsOneWidget);
    expect(find.textContaining('Hi,'), findsOneWidget);
  });

  testWidgets('home check-in opens the same simulated scanner', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const MaterialApp(home: HomeScreen(name: 'Sam')));
    await tester.tap(find.text('Check in'));
    await tester.pumpAndSettle();
    await tester.drag(find.byType(ListView), const Offset(0, -320));
    await tester.pumpAndSettle();

    expect(find.byKey(const ValueKey('simulate-scan')), findsOneWidget);
    expect(find.byType(NavigationBar), findsOneWidget);
  });

  testWidgets('rewards screen shows points and all badge milestones', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const MaterialApp(home: RewardsScreen()));

    expect(find.text('Rewards'), findsWidgets);
    expect(find.text('Harvesting Hero'), findsOneWidget);
    expect(find.text('500 pts'), findsOneWidget);
    await tester.scrollUntilVisible(
      find.text('Material Mover'),
      300,
      scrollable: find.byType(Scrollable).first,
    );
    expect(find.text('Family Feeder'), findsOneWidget);
    expect(find.text('Material Mover'), findsOneWidget);
    expect(find.text('10000 pts'), findsOneWidget);
  });

  testWidgets('parent-created kid can submit a provisional check-in', (
    WidgetTester tester,
  ) async {
    final session = SessionStore.instance;
    session.configureParent(
      name: 'Morgan',
      role: BushelRole.volunteer,
      family: true,
    );
    session.addChild('Ari');
    CoordinatorStore.instance.addFamilyChild(session.children.last);
    session.switchToChild(session.children.last.id);
    await tester.pumpWidget(const MaterialApp(home: HomeScreen(name: 'Ari')));

    expect(find.byKey(const ValueKey('kid-home')), findsOneWidget);
    expect(find.text('CHECK IN & PICK A BADGE'), findsOneWidget);
    expect(find.byType(NavigationBar), findsOneWidget);
    await tester.tap(find.text('CHECK IN & PICK A BADGE'));
    await tester.pumpAndSettle();
    await tester.drag(find.byType(ListView), const Offset(0, -320));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('simulate-scan')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('YES, CHECK ME IN!'));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(FilledButton, 'Check in'));
    await tester.pumpAndSettle();

    expect(find.text('Check-in sent!'), findsOneWidget);
    expect(
      find.textContaining('awaiting coordinator confirmation'),
      findsOneWidget,
    );
  });

  testWidgets('family center creates kid accounts and shows challenges', (
    WidgetTester tester,
  ) async {
    SessionStore.instance.configureParent(
      name: 'Taylor',
      role: BushelRole.volunteer,
      family: true,
    );
    await tester.pumpWidget(const MaterialApp(home: FamilyCenterScreen()));

    await tester.tap(find.text('Add kid'));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byKey(const ValueKey('kid-name-field')),
      'Robin',
    );
    await tester.tap(find.text('Create kid account'));
    await tester.pumpAndSettle();
    expect(find.text('Robin'), findsOneWidget);
    await tester.tap(find.text('Robin'));
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('kid-home')), findsOneWidget);
    await tester.tap(find.text('Family'));
    await tester.pumpAndSettle();
    expect(find.text('Sign up for 3 shifts!'), findsOneWidget);
    expect(find.text('Pack 10 food boxes!'), findsOneWidget);
    expect(find.text('Volunteer together as a family!'), findsOneWidget);
  });

  testWidgets('coordinator opens a shift group without test accounts', (
    WidgetTester tester,
  ) async {
    SessionStore.instance.configureParent(
      name: 'Casey',
      role: BushelRole.coordinator,
      family: false,
    );
    CoordinatorStore.instance.configureParent('Casey', BushelRole.coordinator);
    await tester.pumpWidget(const MaterialApp(home: CoordinatorScreen()));

    expect(find.text('Your shift groups'), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('open-shift-group')));
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(
      find.text('Casey'),
      250,
      scrollable: find.byType(Scrollable).first,
    );
    expect(find.text('Casey'), findsOneWidget);
    expect(find.text('Sir Johnny John Jimmy'), findsNothing);
    expect(find.text('Lil Jimbo'), findsNothing);
    expect(find.text('Jimmerson Jimmies'), findsNothing);
  });

  testWidgets('volunteer opens their group from My shifts', (
    WidgetTester tester,
  ) async {
    SessionStore.instance.setRole(BushelRole.volunteer);
    await tester.pumpWidget(const MaterialApp(home: ShiftsScreen()));

    await tester.tap(find.textContaining('My shifts').first);
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('open-my-shift-group')).first);
    await tester.pumpAndSettle();

    expect(find.text('Shift group'), findsWidgets);
    expect(find.text('Everyone signed up for this shift'), findsOneWidget);
  });
}
