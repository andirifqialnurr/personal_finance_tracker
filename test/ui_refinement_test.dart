import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:personal_finance_tracker/app.dart';
import 'package:personal_finance_tracker/data/flow_store.dart';
import 'package:personal_finance_tracker/data/models/models.dart';
import 'package:personal_finance_tracker/screens/transactions_page.dart';
import 'package:personal_finance_tracker/theme/flow_theme.dart';

void main() {
  final timestamp = DateTime.now();
  final account = Account(
    id: 1,
    name: 'Cash',
    type: AccountType.cash,
    openingBalance: 100000,
    icon: 'wallet',
    color: '#168C78',
    createdAt: timestamp,
    updatedAt: timestamp,
  );
  final expense = Transaction(
    id: 1,
    type: TransactionType.expense,
    amount: 999999999999,
    accountId: 1,
    categoryId: 1,
    note: 'Large expense',
    occurredAt: timestamp,
    createdAt: timestamp,
    updatedAt: timestamp,
  );

  testWidgets('bottom shell and line chart survive target widths and themes', (
    tester,
  ) async {
    for (final isDark in [false, true]) {
      for (final width in [320.0, 360.0, 400.0]) {
        await tester.binding.setSurfaceSize(Size(width, 720));
        await tester.pumpWidget(
          FlowApp(
            key: ValueKey('flow-$isDark-$width'),
            store: MemoryFlowStore(
              accounts: [account],
              transactions: [expense],
              settings: AppSettings(
                themeMode: isDark
                    ? ThemeModeSetting.dark
                    : ThemeModeSetting.light,
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();

        expect(find.byKey(const Key('flow-floating-header')), findsNothing);
        expect(
          find.byKey(const Key('flow-floating-navigation')),
          findsOneWidget,
        );
        expect(
          Theme.of(
            tester.element(find.byKey(const Key('flow-floating-navigation'))),
          ).brightness,
          isDark ? Brightness.dark : Brightness.light,
        );

        final navRect = tester.getRect(
          find.byKey(const Key('flow-floating-navigation')),
        );
        await tester.tapAt(
          Offset(navRect.left + navRect.width * ((2 + .5) / 5), navRect.center.dy),
        );
        await tester.pumpAndSettle();
        final chartFinder = find.byKey(
          const Key('statistics-line-chart'),
          skipOffstage: false,
        );
        expect(chartFinder, findsOneWidget);
        await tester.ensureVisible(chartFinder);
        await tester.pumpAndSettle();
        expect(find.byKey(const Key('statistics-line-chart')), findsOneWidget);
        expect(tester.takeException(), isNull);
      }
    }
    addTearDown(() => tester.binding.setSurfaceSize(null));
  });

  testWidgets('filter modal remains usable on a small dark surface', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(320, 720));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(
      MaterialApp(
        theme: FlowTheme.dark(),
        home: Scaffold(
          body: TransactionsPage(
            transactions: [expense],
            accounts: [account],
            categories: const [
              Category(
                id: 1,
                name: 'Food',
                transactionType: TransactionType.expense,
                icon: 'restaurant',
                color: '#C96B6B',
              ),
            ],
            onOpenDetail: (_) {},
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('transaction-filter-button')));
    await tester.pumpAndSettle();

    expect(find.text('Filter transactions'), findsOneWidget);
    expect(find.text('Apply'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
