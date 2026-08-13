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
