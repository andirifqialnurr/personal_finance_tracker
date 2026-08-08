import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:personal_finance_tracker/app.dart';

void main() {
  testWidgets('Flow starts in an empty Home state', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const FlowApp());

    expect(find.text('Home'), findsWidgets);
    expect(find.text('Start your Flow'), findsOneWidget);
    expect(
      find.text('You have pushed the button this many times:'),
      findsNothing,
    );
  });

  testWidgets('Flow shell switches between primary destinations', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const FlowApp());

    await tester.tap(find.text('Transactions'));
    await tester.pumpAndSettle();

    expect(find.text('Transactions will appear here'), findsOneWidget);
  });

  testWidgets('primary action opens the add transaction flow', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const FlowApp());

    await tester.tap(find.byTooltip('Add transaction'));
    await tester.pumpAndSettle();

    expect(find.text('Add transaction'), findsOneWidget);
    expect(find.text('Save transaction'), findsOneWidget);
  });

  testWidgets('Home avatar opens settings and theme selection persists', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const FlowApp());

    await tester.tap(find.byTooltip('Settings'));
    await tester.pumpAndSettle();
    expect(find.text('Settings'), findsOneWidget);

    await tester.tap(find.text('Dark'));
    await tester.pumpAndSettle();
    expect(
      Theme.of(tester.element(find.text('Settings'))).brightness,
      Brightness.dark,
    );

    await tester.tap(find.byTooltip('Close'));
    await tester.pumpAndSettle();
    expect(find.text('Home'), findsWidgets);
    expect(
      Theme.of(tester.element(find.text('Home').first)).brightness,
      Brightness.dark,
    );
  });
}
