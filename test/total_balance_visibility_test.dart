import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:personal_finance_tracker/app.dart';
import 'package:personal_finance_tracker/data/flow_store.dart';
import 'package:personal_finance_tracker/data/models/models.dart';
import 'package:personal_finance_tracker/screens/home_dashboard.dart';
import 'package:personal_finance_tracker/theme/flow_theme.dart';
import 'package:personal_finance_tracker/utils/flow_format.dart';

void main() {
  final timestamp = DateTime(2026, 8, 9);
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
  final negativeAccount = Account(
    id: 1,
    name: 'Cash',
    type: AccountType.cash,
    openingBalance: 0,
    icon: 'wallet',
    color: '#168C78',
    createdAt: timestamp,
    updatedAt: timestamp,
  );

  Widget home({bool hideBalance = false, ValueChanged<bool>? onChanged}) =>
      MaterialApp(
        theme: FlowTheme.light(),
        home: Scaffold(
          body: HomeDashboard(
            accounts: [account],
            hideBalance: hideBalance,
            onHideBalanceChanged: onChanged,
            onAddTransaction: () {},
          ),
        ),
      );

  testWidgets('masks only the total balance and keeps the toggle reversible', (
    tester,
  ) async {
    var changedTo = false;
    await tester.pumpWidget(home(onChanged: (value) => changedTo = value));
    await tester.pumpAndSettle();

    expect(find.text(formatCurrency(100000, 'IDR')), findsOneWidget);
    await tester.tap(find.byTooltip('Hide balance'));
    await tester.pumpAndSettle();

    expect(find.text('Rp ••••••'), findsOneWidget);
    expect(find.text(formatCurrency(100000, 'IDR')), findsNothing);
    expect(changedTo, isTrue);

    await tester.tap(find.byTooltip('Show balance'));
    await tester.pumpAndSettle();
    expect(find.text(formatCurrency(100000, 'IDR')), findsOneWidget);
  });

  testWidgets('keeps the negative sign visible while masking the amount', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: FlowTheme.light(),
        home: Scaffold(
          body: HomeDashboard(
            accounts: [negativeAccount],
            transactions: [
              Transaction(
                id: 1,
                type: TransactionType.expense,
                amount: 1000,
                accountId: 1,
                categoryId: 1,
                occurredAt: timestamp,
                createdAt: timestamp,
                updatedAt: timestamp,
              ),
            ],
            hideBalance: true,
            onAddTransaction: () {},
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Rp -••••••'), findsOneWidget);
    expect(find.text('Income'), findsOneWidget);
    expect(find.text('Expense'), findsOneWidget);
  });

  testWidgets('restores and persists the balance visibility setting', (
    tester,
  ) async {
    final store = MemoryFlowStore(
      accounts: [account],
      settings: const AppSettings(hideBalance: true),
    );
    await tester.pumpWidget(FlowApp(store: store));
    await tester.pumpAndSettle();

    expect(find.text('Rp ••••••'), findsOneWidget);
    await tester.tap(find.byTooltip('Show balance'));
    await tester.pumpAndSettle();

    expect(find.text(formatCurrency(100000, 'IDR')), findsOneWidget);
    expect((await store.load()).settings.hideBalance, isFalse);
  });
}
