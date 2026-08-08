import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:personal_finance_tracker/app.dart';

Future<void> pumpWithFirstAccount(WidgetTester tester) async {
  await tester.pumpWidget(const FlowApp());
  await tester.tap(find.text('Create first account'));
  await tester.pumpAndSettle();
  await tester.enterText(find.byType(TextFormField).first, 'Cash');
  await tester.tap(find.text('Create account'));
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('Flow starts in Welcome and creates the first account', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const FlowApp());

    expect(find.text('Welcome to Flow'), findsOneWidget);
    expect(find.text('IDR'), findsOneWidget);
    await tester.tap(find.text('Create first account'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextFormField).first, 'Cash');
    await tester.tap(find.text('Create account'));
    await tester.pumpAndSettle();
    expect(find.text('Home'), findsWidgets);
    expect(find.text('Cash'), findsOneWidget);
    expect(
      find.text('You have pushed the button this many times:'),
      findsNothing,
    );
  });

  testWidgets('Flow shell switches between primary destinations', (
    WidgetTester tester,
  ) async {
    await pumpWithFirstAccount(tester);

    await tester.tap(find.text('Transactions'));
    await tester.pumpAndSettle();

    expect(find.text('Transactions will appear here'), findsOneWidget);
  });

  testWidgets('primary action opens the add transaction flow', (
    WidgetTester tester,
  ) async {
    await pumpWithFirstAccount(tester);

    await tester.tap(find.byTooltip('Add transaction'));
    await tester.pumpAndSettle();

    expect(find.text('Add transaction'), findsOneWidget);
    expect(find.text('Save transaction'), findsOneWidget);
  });

  testWidgets('Home avatar opens settings and theme selection persists', (
    WidgetTester tester,
  ) async {
    await pumpWithFirstAccount(tester);

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

  testWidgets('Accounts shows total and per-account balance cards', (
    WidgetTester tester,
  ) async {
    await pumpWithFirstAccount(tester);

    await tester.tap(find.text('Accounts'));
    await tester.pumpAndSettle();

    expect(find.text('Total balance'), findsOneWidget);
    expect(find.text('Your accounts'), findsOneWidget);
    expect(find.text('Cash'), findsOneWidget);
  });

  testWidgets('account archive preserves the shell and shows empty state', (
    WidgetTester tester,
  ) async {
    await pumpWithFirstAccount(tester);
    await tester.tap(find.text('Accounts'));
    await tester.pumpAndSettle();

    await tester.tap(find.byTooltip('Archive account'));
    await tester.pumpAndSettle();
    expect(find.text('Archive Cash?'), findsOneWidget);
    await tester.tap(find.text('Archive account'));
    await tester.pumpAndSettle();

    expect(find.text('No accounts yet'), findsOneWidget);
    expect(find.text('Create account'), findsOneWidget);
  });
}
