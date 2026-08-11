import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:personal_finance_tracker/data/models/models.dart';
import 'package:personal_finance_tracker/screens/transactions_page.dart';
import 'package:personal_finance_tracker/theme/flow_theme.dart';

void main() {
  final timestamp = DateTime(2026, 8, 9);
  final accounts = [
    Account(
      id: 1,
      name: 'Cash',
      type: AccountType.cash,
      openingBalance: 0,
      icon: 'wallet',
      color: '#168C78',
      createdAt: timestamp,
      updatedAt: timestamp,
    ),
  ];
  const categories = [
    Category(
      id: 1,
      name: 'Food',
      transactionType: TransactionType.expense,
      icon: 'restaurant',
      color: '#C96B6B',
    ),
  ];
  final transactions = [
    Transaction(
      id: 1,
      type: TransactionType.expense,
      amount: 100000,
      accountId: 1,
      categoryId: 1,
      note: 'Lunch note',
      occurredAt: timestamp,
      createdAt: timestamp,
      updatedAt: timestamp,
    ),
    Transaction(
      id: 2,
      type: TransactionType.income,
      amount: 500000,
      accountId: 1,
      note: 'Salary note',
      occurredAt: timestamp,
      createdAt: timestamp,
      updatedAt: timestamp,
    ),
  ];

  Widget harness() => MaterialApp(
    theme: FlowTheme.light(),
    home: Scaffold(
      body: TransactionsPage(
        transactions: transactions,
        accounts: accounts,
        categories: categories,
        onOpenDetail: (_) {},
      ),
    ),
  );

  testWidgets('filter modal applies and clears all transaction filters', (
    tester,
  ) async {
    await tester.pumpWidget(harness());
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('transaction-filter-button')));
    await tester.pumpAndSettle();

    expect(find.text('Filter transactions'), findsOneWidget);
    expect(find.text('Type'), findsOneWidget);
    expect(find.text('Account'), findsOneWidget);
    expect(find.text('Category'), findsOneWidget);
    expect(find.text('Date'), findsOneWidget);
    expect(find.text('Clear all'), findsOneWidget);
    expect(find.text('Apply'), findsOneWidget);

    await tester.tap(find.byType(DropdownButtonFormField<TransactionType?>));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Expense').last);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Apply'));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('transaction-filter-active-count')), findsOneWidget);
    expect(find.text('1 filters active'), findsOneWidget);
    expect(find.textContaining('Lunch note'), findsOneWidget);
    expect(find.textContaining('Salary note'), findsNothing);

    await tester.tap(find.byKey(const Key('transaction-filter-button')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Clear all'));
    await tester.tap(find.text('Apply'));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('transaction-filter-active-count')), findsNothing);
    expect(find.textContaining('Salary note'), findsOneWidget);
  });
}
