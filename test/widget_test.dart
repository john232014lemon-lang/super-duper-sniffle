import 'package:bushel/main.dart';
import 'package:bushel/screens/food_bank_map_screen.dart';
import 'package:bushel/screens/shifts_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('completes volunteer onboarding', (WidgetTester tester) async {
    await tester.pumpWidget(const BushelApp());

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
    await tester.pumpWidget(const BushelApp());
    await tester.ensureVisible(find.text('Get started'));
    await tester.tap(find.text('Get started'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(EditableText), 'Sam');
    await tester.ensureVisible(find.text('Finish setup'));
    await tester.tap(find.text('Finish setup'));
    await tester.pumpAndSettle();

    await tester.drag(find.byType(CustomScrollView), const Offset(0, -220));
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
    await tester.pumpWidget(const BushelApp());
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
    await tester.pumpWidget(const BushelApp());
    await tester.ensureVisible(find.text('Get started'));
    await tester.tap(find.text('Get started'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(EditableText), 'Sam');
    await tester.ensureVisible(find.text('Finish setup'));
    await tester.tap(find.text('Finish setup'));
    await tester.pumpAndSettle();
    await tester.drag(find.byType(CustomScrollView), const Offset(0, -220));
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
    await tester.pumpWidget(const MaterialApp(home: ShiftsScreen()));

    await tester.tap(find.text('Sign up').first);
    await tester.pumpAndSettle();
    expect(find.text('Confirm this shift?'), findsOneWidget);
    await tester.tap(find.text('Confirm signup'));
    await tester.pumpAndSettle();

    expect(find.text('Shift added to My shifts.'), findsOneWidget);
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
}
