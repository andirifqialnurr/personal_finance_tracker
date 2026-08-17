import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:personal_finance_tracker/app.dart';

Future<void> pumpWithFirstAccount(WidgetTester tester) async {
  await tester.pumpWidget(const FlowApp());
  await tester.pumpAndSettle();
  await tester.tap(find.text('Create first account'));
  await tester.pumpAndSettle();
  await tester.enterText(find.byType(TextFormField).first, 'Cash');
  await tester.tap(find.text('Create account'));
  await tester.pumpAndSettle();
}

Future<void> tapShellTab(WidgetTester tester, int index) async {
  final navRect = tester.getRect(
    find.byKey(const Key('flow-floating-navigation')),
  );
  await tester.tapAt(
    Offset(navRect.left + navRect.width * ((index + .5) / 6), navRect.center.dy),
  );
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('Flow starts in Welcome and creates the first account', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const FlowApp());
    await tester.pumpAndSettle();

    expect(find.text('Welcome to Flow'), findsOneWidget);
    expect(find.text('IDR'), findsOneWidget);
    await tester.tap(find.text('Create first account'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextFormField).first, 'Cash');
    await tester.tap(find.text('Create account'));
    await tester.pumpAndSettle();
    expect(find.text('Your Flow'), findsOneWidget);
    expect(find.text('Total balance'), findsOneWidget);
    expect(
      find.text('You have pushed the button this many times:'),
      findsNothing,
    );
  });

  testWidgets('Flow shell switches between primary destinations', (
    WidgetTester tester,
  ) async {
    await pumpWithFirstAccount(tester);

    expect(find.byKey(const Key('flow-floating-header')), findsNothing);
    expect(find.byKey(const Key('flow-floating-navigation')), findsOneWidget);
    expect(find.byIcon(Icons.settings_outlined), findsOneWidget);

    await tapShellTab(tester, 1);

    expect(find.text('No transactions yet'), findsOneWidget);
  });

  testWidgets('Statistics exposes daily, weekly, and monthly periods', (
    WidgetTester tester,
  ) async {
    await pumpWithFirstAccount(tester);

    await tapShellTab(tester, 2);

    expect(find.text('Harian'), findsOneWidget);
    expect(find.text('Pekanan'), findsOneWidget);
    expect(find.text('Bulanan'), findsOneWidget);
    await tester.tap(find.text('Harian'));
    await tester.pumpAndSettle();
    expect(find.byTooltip('Previous period'), findsOneWidget);
    expect(find.byTooltip('Next period'), findsOneWidget);
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

  testWidgets('Settings tab changes theme and persists', (
    WidgetTester tester,
  ) async {
    await pumpWithFirstAccount(tester);

    await tapShellTab(tester, 5);
    expect(find.text('Appearance'), findsOneWidget);
    expect(find.text('System'), findsNothing);

    await tester.tap(find.text('Dark'));
    await tester.pumpAndSettle();
    expect(
      Theme.of(tester.element(find.text('Appearance'))).brightness,
      Brightness.dark,
    );

    await tapShellTab(tester, 0);
    expect(find.text('Your Flow'), findsOneWidget);
    expect(
      Theme.of(tester.element(find.text('Your Flow'))).brightness,
      Brightness.dark,
    );
  });

  testWidgets('Accounts shows total and per-account balance cards', (
    WidgetTester tester,
  ) async {
    await pumpWithFirstAccount(tester);

    await tapShellTab(tester, 3);

    expect(find.text('Total balance'), findsOneWidget);
    expect(find.text('Your accounts'), findsOneWidget);
    expect(find.text('Cash'), findsWidgets);
  });

  testWidgets('account archive preserves the shell and shows empty state', (
    WidgetTester tester,
  ) async {
    await pumpWithFirstAccount(tester);
    await tapShellTab(tester, 3);

    await tester.tap(find.byTooltip('Archive account'));
    await tester.pumpAndSettle();
    expect(find.text('Archive Cash?'), findsOneWidget);
    await tester.tap(find.text('Archive account'));
    await tester.pumpAndSettle();

    expect(find.text('No accounts yet'), findsOneWidget);
    expect(find.text('Create account'), findsOneWidget);
    expect(find.text('Archived accounts'), findsOneWidget);

    await tester.tap(find.text('Restore'));
    await tester.pumpAndSettle();

    expect(find.text('No accounts yet'), findsNothing);
    expect(find.text('Cash'), findsWidgets);
  });

  testWidgets(
    'transaction form validates and adapts transfer fields on small screens',
    (WidgetTester tester) async {
      await pumpWithFirstAccount(tester);
      await tester.binding.setSurfaceSize(const Size(320, 640));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      await tester.tap(find.byTooltip('Add transaction'));
      await tester.pumpAndSettle();

      final saveButton = tester.widget<FilledButton>(
        find.widgetWithText(FilledButton, 'Save transaction'),
      );
      expect(saveButton.onPressed, isNull);
      await tester.tap(find.text('Transfer'));
      await tester.pumpAndSettle();
      expect(find.text('To account'), findsOneWidget);
      expect(find.text('Category'), findsNothing);
      expect(tester.takeException(), isNull);
    },
  );
}
