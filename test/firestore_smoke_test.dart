import 'dart:async';

import 'package:bushel/screens/firestore_smoke_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('connection check blocks duplicate runs and reports success', (
    tester,
  ) async {
    final pending = Completer<void>();
    var calls = 0;
    await tester.pumpWidget(
      MaterialApp(
        home: FirestoreSmokeScreen(
          runCheck: () {
            calls++;
            return pending.future;
          },
        ),
      ),
    );
    await tester.tap(find.text('Run connection check'));
    await tester.pump();
    expect(
      tester.widget<FilledButton>(find.byType(FilledButton)).onPressed,
      isNull,
    );
    expect(calls, 1);
    pending.complete();
    await tester.pumpAndSettle();
    expect(
      find.text('Passed: write, server read, and deletion verified.'),
      findsOneWidget,
    );
  });

  testWidgets('connection check errors do not report success and can retry', (
    tester,
  ) async {
    var calls = 0;
    await tester.pumpWidget(
      MaterialApp(
        home: FirestoreSmokeScreen(
          runCheck: () async {
            if (calls++ == 0) throw StateError('permission-denied');
          },
        ),
      ),
    );
    await tester.tap(find.text('Run connection check'));
    await tester.pumpAndSettle();
    expect(find.textContaining('Check failed.'), findsOneWidget);
    expect(find.textContaining('Passed:'), findsNothing);
    await tester.tap(find.text('Run connection check'));
    await tester.pumpAndSettle();
    expect(find.textContaining('Passed:'), findsOneWidget);
    expect(calls, 2);
  });
}
