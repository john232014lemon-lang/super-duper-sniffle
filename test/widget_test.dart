import 'package:bushel/main.dart';
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
    expect(find.text('Upcoming shifts'), findsOneWidget);
    expect(find.text('Sorting & Packing Line'), findsOneWidget);
    await tester.scrollUntilVisible(
      find.text('Recommended food banks'),
      300,
      scrollable: find.byType(Scrollable).last,
    );
    await tester.scrollUntilVisible(
      find.text('Martha’s Kitchen'),
      200,
      scrollable: find.byType(Scrollable).last,
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
}
