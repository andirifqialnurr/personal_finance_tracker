import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:personal_finance_tracker/data/data.dart';
import 'package:personal_finance_tracker/screens/settings_page.dart';

void main() {
  testWidgets('Settings focuses on app preferences and danger zone', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: FlowSettingsPage(
          initialThemeMode: ThemeMode.light,
          onThemeModeChanged: (_) {},
          currency: 'IDR',
          onCurrencyChanged: (_) {},
          categories: const [
            Category(
              id: 1,
              name: 'Salary',
              transactionType: TransactionType.income,
              icon: 'payments',
              color: '#168C78',
            ),
          ],
          onCategoriesChanged: (_) {},
          onDeleteAll: () {},
          showAppBar: false,
        ),
      ),
    );

    expect(find.text('Appearance'), findsOneWidget);
    expect(find.text('Currency'), findsOneWidget);
    expect(find.text('Categories'), findsOneWidget);
    expect(find.text('Danger zone'), findsOneWidget);
    expect(find.text('Delete all data'), findsOneWidget);

    expect(find.text('Data management'), findsNothing);
    expect(find.text('Export CSV'), findsNothing);
    expect(find.text('Import CSV'), findsNothing);
    expect(find.text('Export local backup'), findsNothing);
    expect(find.text('Restore local backup'), findsNothing);
  });
}
