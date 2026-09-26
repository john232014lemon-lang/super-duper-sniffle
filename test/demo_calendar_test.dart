import 'package:bushel/data/coordinator_store.dart';
import 'package:bushel/data/mock_food_banks.dart';
import 'package:bushel/data/session_store.dart';
import 'package:bushel/data/shift_store.dart';
import 'package:bushel/demo_app.dart';
import 'package:bushel/models/food_bank.dart';
import 'package:bushel/screens/family_center_screen.dart';
import 'package:bushel/screens/food_bank_detail_screen.dart';
import 'package:bushel/screens/shifts_screen.dart';
import 'package:bushel/widgets/shift_calendar.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  setUp(() {
    SessionStore.instance.reset();
    CoordinatorStore.instance.reset();
    ShiftStore.instance.reset();
  });

  testWidgets(
    'demo onboards a family without Firebase and resets nested routes and all data',
    (tester) async {
      await tester.pumpWidget(const DemoApp());
      expect(Firebase.apps, isEmpty);
      expect(find.text('Local demo'), findsOneWidget);
      await tester.ensureVisible(find.text('Get started'));
      await tester.tap(find.text('Get started'));
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextFormField), 'Demo parent');
      await tester.ensureVisible(find.text('Coordinator'));
      await tester.tap(find.text('Coordinator'));
      await tester.ensureVisible(find.byType(SwitchListTile));
      await tester.tap(find.byType(SwitchListTile));
      await tester.ensureVisible(find.text('Finish setup'));
      await tester.tap(find.text('Finish setup'));
      await tester.pumpAndSettle();
      expect(find.byType(FamilyCenterScreen), findsOneWidget);
      final session = SessionStore.instance;
      expect(session.parentRole, BushelRole.coordinator);
      session.addChild('Demo kid');
      session.addChallenge('Demo challenge');
      session.unlockKidBadge('bunny');
      final store = ShiftStore.instance;
      final shift = store.myShifts.first.shift;
      store.generateQrCode(shift);
      store.checkIn(shift);
      store.confirmAttendance(shift, 'parent');
      expect(store.points, 100);
      CoordinatorStore.instance.voteToRemove('riley');
      store.addAvailable(
        mockFoodBanks.first,
        FoodBankShift(
          title: 'Temporary',
          scheduledDate: DateTime.now(),
          time: '10:00 AM',
          station: 'A',
          spotsLeft: 2,
        ),
      );
      session.switchToChild(session.children.first.id);
      tester
          .state<NavigatorState>(find.byType(Navigator))
          .push(MaterialPageRoute<void>(builder: (_) => const ShiftsScreen()));
      await tester.pumpAndSettle();
      expect(find.text('Local demo'), findsOneWidget);
      await tester.tap(find.text('Reset demo'));
      await tester.pumpAndSettle();
      expect(find.text('Get started'), findsOneWidget);
      expect(
        tester.state<NavigatorState>(find.byType(Navigator)).canPop(),
        isFalse,
      );
      expect(session.children, isEmpty);
      expect(session.challenges, hasLength(3));
      expect(session.unlockedKidBadges, isEmpty);
      expect(session.role, BushelRole.volunteer);
      expect(store.points, 0);
      expect(store.qrCodeFor(shift), isNull);
      expect(store.pendingAttendance(shift), isEmpty);
      expect(
        store.available.any((listing) => listing.shift.title == 'Temporary'),
        isFalse,
      );
      expect(CoordinatorStore.instance.hasVotedFor('riley'), isFalse);
      expect(Firebase.apps, isEmpty);
    },
  );

  testWidgets(
    'calendar filters both tabs and signup updates the selected day',
    (tester) async {
      final day = DateTime(2028, 2, 29);
      final shift = FoodBankShift(
        title: 'Leap day packing',
        scheduledDate: day,
        time: '10:00 AM',
        station: 'A',
        spotsLeft: 4,
      );
      ShiftStore.instance.addAvailable(mockFoodBanks.first, shift);
      await tester.pumpWidget(
        MaterialApp(home: ShiftsScreen(initialDate: day)),
      );
      await tester.scrollUntilVisible(find.text('Leap day packing'), 200);
      expect(find.text('Sorting & Packing Line'), findsNothing);
      await tester.scrollUntilVisible(find.text('Sign up'), 100);
      await tester.pumpAndSettle();
      await tester.tap(find.text('Sign up'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Confirm signup'));
      await tester.pumpAndSettle();
      expect(ShiftStore.instance.isSignedUp(shift), isTrue);
      expect(find.text('Signed up'), findsOneWidget);
      await tester.scrollUntilVisible(
        find.descendant(
          of: find.byType(SegmentedButton<int>),
          matching: find.textContaining('My shifts'),
        ),
        -200,
      );
      await tester.pumpAndSettle();
      await tester.tap(
        find
            .descendant(
              of: find.byType(SegmentedButton<int>),
              matching: find.textContaining('My shifts'),
            )
            .first,
      );
      await tester.pumpAndSettle();
      await tester.scrollUntilVisible(find.text('Leap day packing'), 200);
      expect(find.text('Leap day packing'), findsOneWidget);
      await tester.scrollUntilVisible(find.byTooltip('Next month'), -200);
      await tester.pumpAndSettle();
      await tester.tap(find.byTooltip('Next month'));
      await tester.pumpAndSettle();
      expect(
        tester.widget<ShiftCalendar>(find.byType(ShiftCalendar)).selectedDate,
        DateTime(2028, 3, 29),
      );

      await tester.scrollUntilVisible(
        find.text('No signups for this day'),
        200,
      );
      expect(find.text('Leap day packing'), findsNothing);
      await tester.scrollUntilVisible(find.text('Available'), -200);
      await tester.pumpAndSettle();
      await tester.tap(find.text('Available'));
      await tester.pumpAndSettle();
      await tester.scrollUntilVisible(find.text('No shifts on this day'), 200);
    },
  );

  testWidgets('month navigation handles year boundaries and leap days', (
    tester,
  ) async {
    var selected = DateTime(2027, 12, 31);
    await tester.pumpWidget(
      MaterialApp(
        home: StatefulBuilder(
          builder: (context, setState) => Scaffold(
            body: ShiftCalendar(
              selectedDate: selected,
              shiftDates: const [],
              onSelected: (date) => setState(() => selected = date),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.byTooltip('Next month'));
    await tester.pump();
    expect(selected, DateTime(2028, 1, 31));
    await tester.tap(find.byTooltip('Next month'));
    await tester.pump();
    expect(selected, DateTime(2028, 2, 29));
    expect(find.byKey(const ValueKey('calendar-2028-02-30')), findsNothing);
    await tester.tap(find.byKey(const ValueKey('calendar-2028-02-15')));
    await tester.pump();
    expect(selected, DateTime(2028, 2, 15));
    await tester.tap(find.byTooltip('Previous month'));
    await tester.pump();
    expect(selected, DateTime(2028, 1, 15));
  });

  testWidgets(
    'custom shift validates dates and survives reopening bank details',
    (tester) async {
      SessionStore.instance.setRole(BushelRole.coordinator);
      final bank = mockFoodBanks.first;
      await tester.pumpWidget(
        MaterialApp(home: FoodBankDetailScreen(foodBank: bank)),
      );
      await tester.scrollUntilVisible(
        find.text('Add shift'),
        200,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.tap(find.text('Add shift'));
      await tester.pumpAndSettle();
      final fields = find.byType(TextFormField);
      await tester.enterText(fields.at(0), 'New calendar shift');
      await tester.enterText(fields.at(1), '2028-02-30');
      await tester.enterText(fields.at(2), '10:00 AM');
      await tester.enterText(fields.at(3), 'A');
      await tester.tap(find.widgetWithText(FilledButton, 'Add shift').last);
      await tester.pumpAndSettle();
      expect(find.textContaining('Enter a valid date'), findsOneWidget);
      await tester.enterText(fields.at(1), '2028-02-29');
      await tester.tap(find.widgetWithText(FilledButton, 'Add shift').last);
      await tester.pumpAndSettle();
      expect(
        ShiftStore.instance.available.last.shift.scheduledDate,
        DateTime(2028, 2, 29),
      );
      await tester.pumpWidget(
        MaterialApp(
          key: UniqueKey(),
          home: FoodBankDetailScreen(foodBank: bank),
        ),
      );
      await tester.scrollUntilVisible(
        find.byKey(const ValueKey('shift-carousel')),
        200,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.drag(
        find.byKey(const ValueKey('shift-carousel')),
        const Offset(-1100, 0),
      );
      await tester.pumpAndSettle();
      expect(find.text('New calendar shift'), findsOneWidget);
      await tester.pumpWidget(
        MaterialApp(
          key: UniqueKey(),
          home: ShiftsScreen(initialDate: DateTime(2028, 2, 29)),
        ),
      );
      await tester.scrollUntilVisible(find.text('New calendar shift'), 200);
      expect(find.text('New calendar shift'), findsOneWidget);
    },
  );
}
